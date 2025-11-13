#!/usr/bin/env python3
"""
Server Status Monitor Widget
A draggable desktop widget that monitors server status in real-time
Uses external CSS for styling
"""

import gi
import json

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib
import socket
import threading
import time
import argparse
import subprocess
from pathlib import Path


class ServerMonitorWidget(Gtk.Window):
    def __init__(self):
        super().__init__()

        # Load CSS styling first
        self.load_css()

        # Load server configuration from config.json
        self.servers = self.load_server_config()

        # Discover and add Docker services dynamically
        self.add_docker_services()

        # Status tracking
        self.server_status = {
            i: {"status": "checking", "response_time": 0}
            for i in range(len(self.servers))
        }
        self.minimized = False

        # Cache for internet connectivity to avoid frequent checks
        self.internet_cache = {"status": None, "timestamp": 0}

        # Theme state (False = dark, True = light)
        self.is_light_theme = False

        # Store window sizes
        self.full_width = 675
        self.full_height = 1000
        self.max_height = 1200  # Maximum height before scrolling kicks in
        self.minimized_width = 1000
        self.minimized_height = 150

        # Window setup
        # Option 1: Normal window with title bar
        # self.set_decorated(True)
        # self.set_title("Server Status Monitor")

        # Option 2: Frameless widget
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.NORMAL)  # Use NORMAL instead of UTILITY

        # Behave like a normal window (not always on top)
        self.set_keep_above(False)
        self.set_default_size(self.full_width, self.full_height)  # Custom size: 675x730
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(True)  # Allow manual resizing

        # Set size constraints - limit maximum height to trigger scrolling
        self.set_size_request(675, 800)  # Minimum size (keep original proportions)

        # Create geometry hints for size constraints
        geometry = Gdk.Geometry()
        geometry.min_width = 675
        geometry.min_height = 800
        geometry.max_width = 1000
        geometry.max_height = self.max_height

        self.set_geometry_hints(
            self, geometry, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE
        )

        # Make sure the window is visible and focusable
        self.set_skip_taskbar_hint(False)  # Show in taskbar
        self.set_skip_pager_hint(False)  # Show in pager/workspace switcher

        # Transparency
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
            self.set_app_paintable(True)

        # Dragging variables
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.is_dragging = False

        # Create UI
        self.create_ui()

        # Connect signals
        self.connect("button-press-event", self.on_button_press)
        self.connect("button-release-event", self.on_button_release)
        self.connect("motion-notify-event", self.on_motion)
        self.connect("draw", self.on_draw)

        # Start monitoring
        self.start_monitoring()

    def add_docker_services(self):
        """Discover Docker services and add them to the servers list"""
        try:
            # Get all containers with their Docker Compose project info
            result = subprocess.run(
                [
                    "docker",
                    "ps",
                    "-a",
                    "--format",
                    "{{.Names}}\t{{.Status}}\t{{.Image}}",
                ],
                capture_output=True,
                text=True,
                timeout=10,
            )

            if result.returncode != 0 or not result.stdout.strip():
                return  # Docker not available or no containers

            # Get Docker Compose project info for all containers
            container_projects = self.get_container_projects()

            # Group containers by service
            services = {}
            for line in result.stdout.strip().split("\n"):
                if line.strip():
                    parts = line.split("\t")
                    if len(parts) >= 2:
                        name = parts[0]
                        status = parts[1]
                        image = parts[2] if len(parts) > 2 else "unknown"

                        # Use Docker Compose project name if available, otherwise fall back to name-based grouping
                        service_name = container_projects.get(
                            name, self.get_service_name(name)
                        )

                        if service_name not in services:
                            services[service_name] = []

                        services[service_name].append(
                            {
                                "name": name,
                                "status": status,
                                "image": image,
                                "is_running": "Up" in status,
                            }
                        )

            # Add each service to servers list with sorted containers
            for service_name, containers in services.items():
                # Sort containers alphabetically by name
                sorted_containers = sorted(containers, key=lambda x: x["name"].lower())
                self.servers.append(
                    {
                        "name": service_name,
                        "type": "docker_service",
                        "containers": sorted_containers,
                    }
                )

        except Exception as e:
            print(f"Error discovering Docker services: {e}")

    def get_container_projects(self):
        """Get Docker Compose project names for all containers"""
        try:
            # Get all container IDs
            result = subprocess.run(
                ["docker", "ps", "-aq"],
                capture_output=True,
                text=True,
                timeout=10,
            )

            if result.returncode != 0 or not result.stdout.strip():
                return {}

            container_ids = result.stdout.strip().split("\n")

            # Get project info for all containers
            container_projects = {}
            for container_id in container_ids:
                if container_id.strip():
                    inspect_result = subprocess.run(
                        [
                            "docker",
                            "inspect",
                            "--format",
                            '{{index .Config.Labels "com.docker.compose.project"}} {{.Name}}',
                            container_id,
                        ],
                        capture_output=True,
                        text=True,
                        timeout=5,
                    )

                    if inspect_result.returncode == 0 and inspect_result.stdout.strip():
                        parts = inspect_result.stdout.strip().split(" ", 1)
                        if len(parts) == 2:
                            project_name = parts[0]
                            container_name = parts[1].lstrip(
                                "/"
                            )  # Remove leading slash

                            if project_name and project_name != "<no value>":
                                # Format project name nicely
                                formatted_project = self.format_project_name(
                                    project_name
                                )
                                container_projects[container_name] = formatted_project

            return container_projects

        except Exception as e:
            print(f"Error getting container projects: {e}")
            return {}

    def format_project_name(self, project_name):
        """Format Docker Compose project name to be more readable"""
        # Replace hyphens with spaces and capitalize each word
        formatted = project_name.replace("-", " ").title()
        return formatted

    def refresh_docker_services(self):
        """Re-discover Docker services and update the servers list"""
        # Remove existing Docker services
        self.servers = [s for s in self.servers if s.get("type") != "docker_service"]

        # Re-discover and add Docker services
        self.add_docker_services()

        # Update status tracking for new server count
        self.server_status = {
            i: {"status": "checking", "response_time": 0}
            for i in range(len(self.servers))
        }

    def rebuild_ui(self):
        """Rebuild the services UI after Docker discovery"""
        # Clear existing services container
        for child in self.services_container.get_children():
            self.services_container.remove(child)

        # Rebuild services sections
        # Server services
        server_indices = [
            i for i, s in enumerate(self.servers) if s["type"] == "server"
        ]
        if server_indices:
            server_section = self.create_services_section(
                "SERVER SERVICES", server_indices
            )
            self.services_container.pack_start(server_section, False, False, 0)

        # Local services (including Docker)
        local_indices = [
            i
            for i, s in enumerate(self.servers)
            if s["type"] in ["local", "docker_service"]
        ]
        if local_indices:
            local_section = self.create_services_section(
                "LOCAL SERVICES", local_indices
            )
            self.services_container.pack_start(local_section, False, False, 0)

        # Show all new widgets
        self.services_container.show_all()

        return False

    def rebuild_ui_theme_only(self):
        """Rebuild the services UI for theme changes only (no service discovery)"""
        # Clear existing services container
        for child in self.services_container.get_children():
            self.services_container.remove(child)

        # Rebuild services sections using existing server data
        # Server services
        server_indices = [
            i for i, s in enumerate(self.servers) if s["type"] == "server"
        ]
        if server_indices:
            server_section = self.create_services_section(
                "SERVER SERVICES", server_indices
            )
            self.services_container.pack_start(server_section, False, False, 0)

        # Local services (including Docker)
        local_indices = [
            i
            for i, s in enumerate(self.servers)
            if s["type"] in ["local", "docker_service"]
        ]
        if local_indices:
            local_section = self.create_services_section(
                "LOCAL SERVICES", local_indices
            )
            self.services_container.pack_start(local_section, False, False, 0)

        # Show all new widgets
        self.services_container.show_all()

        # Update the display with current status data (no new checks)
        for i in range(len(self.servers)):
            if i in self.service_widgets:
                self.update_server_display(i)

    def get_service_name(self, container_name):
        """Extract service name from container name dynamically"""
        # Handle special cases where containers belong to the same service but have different naming
        container_lower = container_name.lower()

        # Group cardhouzz-related containers together
        if (
            container_lower.startswith("ch_")
            or "cardhouzz" in container_lower
            or container_lower.startswith("cardhouzz")
        ):
            return "Cardhouzz"

        # Extract the service prefix (part before first _ or -)
        if "_" in container_name:
            service_prefix = container_name.split("_")[0]
        elif "-" in container_name:
            service_prefix = container_name.split("-")[0]
        else:
            # Single word container name - check if it has a domain extension
            if "." in container_name:
                # Handle cases like "service.io", "app.com" - use the part before the dot
                service_prefix = container_name.split(".")[0]
            else:
                service_prefix = container_name

        # Convert to readable format: replace any remaining separators and capitalize
        service_name = service_prefix.replace("_", " ").replace("-", " ").title()

        return service_name

    def load_css(self):
        """Load CSS styling from external file"""
        css_file = Path(__file__).parent / "widget-gtk.css"

        if css_file.exists():
            css_provider = Gtk.CssProvider()
            css_provider.load_from_path(str(css_file))

            screen = Gdk.Screen.get_default()
            style_context = Gtk.StyleContext()
            style_context.add_provider_for_screen(
                screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
            print(f"✅ Loaded CSS from {css_file}")
        else:
            print(f"⚠️  CSS file not found: {css_file}")

    def load_server_config(self):
        """Load server configuration from config.json file"""
        config_file = Path(__file__).parent / "config.json"

        try:
            with open(config_file, "r") as json_file:
                servers = json.load(json_file)
                print(f"✅ Loaded {len(servers)} servers from {config_file}")
                return servers
        except FileNotFoundError:
            print(f"⚠️  Config file not found: {config_file}")
            print("Creating default config.json...")
            self.create_default_config(config_file)
            return self.load_default_servers()
        except json.JSONDecodeError as e:
            print(f"❌ Error parsing config.json: {e}")
            print("Using default server configuration...")
            return self.load_default_servers()
        except Exception as e:
            print(f"❌ Error loading config: {e}")
            return self.load_default_servers()

    def create_default_config(self, config_file):
        """Create a default config.json file"""
        default_config = [
            {
                "name": "Example HTTPS Service",
                "host": "https://httpbin.org",
                "type": "server",
            },
            {
                "name": "Example HTTP Service",
                "host": "httpbin.org",
                "port": 80,
                "type": "server",
            },
        ]

        try:
            with open(config_file, "w") as json_file:
                json.dump(default_config, json_file, indent=2)
            print(f"✅ Created default config: {config_file}")
        except Exception as e:
            print(f"❌ Error creating default config: {e}")

    def load_default_servers(self):
        """Return default server configuration as fallback"""
        return [
            {
                "name": "Example Service",
                "host": "httpbin.org",
                "port": 80,
                "type": "server",
            }
        ]

    def create_ui(self):
        # Main container
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.main_box.set_margin_top(20)
        self.main_box.set_margin_bottom(20)
        self.main_box.set_margin_start(20)
        self.main_box.set_margin_end(20)

        # Header
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        header_box.set_valign(
            Gtk.Align.START
        )  # Prevent header from expanding vertically

        # Title section
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title_box.set_valign(Gtk.Align.START)  # Align title section to top

        title = Gtk.Label(label="System Status")
        title.get_style_context().add_class("widget-title")
        title.set_halign(Gtk.Align.START)

        self.last_updated = Gtk.Label(label="Last updated: Now")
        self.last_updated.get_style_context().add_class("widget-subtitle")
        self.last_updated.set_halign(Gtk.Align.START)

        # Network status indicator
        self.network_status = Gtk.Label(label="🌐 Connected")
        self.network_status.get_style_context().add_class("network-status")
        self.network_status.set_halign(Gtk.Align.START)

        title_box.pack_start(title, False, False, 0)
        title_box.pack_start(self.last_updated, False, False, 0)
        title_box.pack_start(self.network_status, False, False, 0)

        header_box.pack_start(title_box, True, True, 0)

        # Buttons
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        button_box.set_halign(Gtk.Align.END)  # Align buttons to the right
        button_box.set_valign(Gtk.Align.START)  # Align buttons to the top

        # Refresh button
        self.refresh_btn = Gtk.Button(label="⟳")
        self.refresh_btn.set_tooltip_text("Refresh")
        self.refresh_btn.set_size_request(30, 30)  # Fixed size
        self.refresh_btn.connect("clicked", self.on_refresh)

        # Theme toggle button
        self.theme_btn = Gtk.Button(label="🌙")
        self.theme_btn.set_tooltip_text("Toggle Theme")
        self.theme_btn.set_size_request(30, 30)  # Fixed size
        self.theme_btn.connect("clicked", self.on_theme_toggle)

        # Minimize button
        self.minimize_btn = Gtk.Button(label="−")
        self.minimize_btn.set_tooltip_text("Minimize")
        self.minimize_btn.set_size_request(30, 30)  # Fixed size
        self.minimize_btn.get_style_context().add_class("minimize-button")
        self.minimize_btn.connect("clicked", self.on_minimize)

        # Close button
        close_btn = Gtk.Button(label="✕")
        close_btn.set_tooltip_text("Close")
        close_btn.set_size_request(30, 30)  # Fixed size
        close_btn.get_style_context().add_class("close-button")

        close_btn.connect("clicked", self.on_close)

        button_box.pack_start(self.refresh_btn, False, False, 0)
        button_box.pack_start(self.theme_btn, False, False, 0)
        button_box.pack_start(self.minimize_btn, False, False, 0)
        button_box.pack_start(close_btn, False, False, 0)

        header_box.pack_start(button_box, False, False, 0)
        self.main_box.pack_start(header_box, False, False, 0)

        # Spacing
        self.main_box.pack_start(Gtk.Box(), False, False, 20)

        # Services sections with scrollable container
        self.services_container = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL, spacing=20
        )

        # Create scrolled window for services
        self.scrolled_window = Gtk.ScrolledWindow()
        self.scrolled_window.set_policy(
            Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC
        )  # No horizontal scroll, auto vertical
        self.scrolled_window.set_max_content_height(
            800
        )  # Max height before scrolling (1200 - header - footer - margins)
        self.scrolled_window.set_propagate_natural_height(True)
        self.scrolled_window.add(self.services_container)

        # Server services
        server_indices = [
            i for i, s in enumerate(self.servers) if s["type"] == "server"
        ]
        if server_indices:
            server_section = self.create_services_section(
                "SERVER SERVICES", server_indices
            )
            self.services_container.pack_start(server_section, False, False, 0)

        # Local services (including Docker)
        local_indices = [
            i
            for i, s in enumerate(self.servers)
            if s["type"] in ["local", "docker_service"]
        ]
        if local_indices:
            local_section = self.create_services_section(
                "LOCAL SERVICES", local_indices
            )
            self.services_container.pack_start(local_section, False, False, 0)

        self.main_box.pack_start(self.scrolled_window, True, True, 0)

        # Footer
        self.main_box.pack_start(Gtk.Box(), False, False, 20)

        footer_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        footer_label = Gtk.Label(label="Overall Status")
        footer_label.get_style_context().add_class("footer-label")
        footer_label.set_halign(Gtk.Align.START)

        self.status_summary = Gtk.Label(label="6 / 6 Operational")
        self.status_summary.get_style_context().add_class("footer-status")
        self.status_summary.set_halign(Gtk.Align.END)

        footer_box.pack_start(footer_label, True, True, 0)
        footer_box.pack_start(self.status_summary, False, False, 0)

        self.main_box.pack_start(footer_box, False, False, 0)

        self.add(self.main_box)

    def create_services_section(self, title, indices):
        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)

        # Section title
        title_label = Gtk.Label(label=title)
        title_label.get_style_context().add_class("section-title")
        title_label.set_halign(Gtk.Align.START)
        section_box.pack_start(title_label, False, False, 0)

        # Services
        for i in indices:
            server = self.servers[i]
            service_row = self.create_service_row(i, server)
            section_box.pack_start(service_row, False, False, 0)

        return section_box

    def create_service_row(self, index, server):
        # Create main service row with service-item styling
        event_box = Gtk.EventBox()
        event_box.get_style_context().add_class("service-item")

        # Main vertical container inside the service-item
        main_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_container.set_margin_top(10)
        main_container.set_margin_bottom(10)
        main_container.set_margin_start(12)
        main_container.set_margin_end(12)

        # Service header row
        row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        # Service icon
        icon_map = {
            "API Server": "🖥️",
            "Database": "🗄️",
            "Cloud Storage": "☁️",
            "Local Cache": "💾",
            "CPU Monitor": "⚙️",
            "Network": "🌐",
            "Cardhouzz DEV": "🏠",
            "Cardhouzz": "🏠",
            "Nasspay": "💳",
            "App Services": "📱",
            "Auth Services": "🔐",
            "NestJS": "🟢",
            "Other Services": "🐳",
        }

        # Use custom icon from config if available, otherwise use icon mapping
        if "icon" in server and server["icon"]:
            icon_text = server["icon"]
        elif server.get("type") == "docker_service":
            icon_text = "🐳"  # Docker whale icon for all Docker services
        else:
            icon_text = icon_map.get(server["name"], icon_map["Cloud Storage"])
        icon_label = Gtk.Label(label=icon_text)
        icon_label.get_style_context().add_class("service-icon")
        row_box.pack_start(icon_label, False, False, 0)

        # Service details
        details_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        name_label = Gtk.Label(label=server["name"])
        name_label.get_style_context().add_class("service-name")
        name_label.set_halign(Gtk.Align.START)

        response_label = Gtk.Label(label="0ms response time")
        response_label.get_style_context().add_class("service-response")
        response_label.set_halign(Gtk.Align.START)

        details_box.pack_start(name_label, False, False, 0)
        details_box.pack_start(response_label, False, False, 0)

        row_box.pack_start(details_box, True, True, 0)

        # Status
        status_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)

        status_text = Gtk.Label(label="Checking")
        status_text.get_style_context().add_class("status-checking")

        status_dot = Gtk.Label(label="●")
        status_dot.get_style_context().add_class("status-dot")
        status_dot.get_style_context().add_class("status-checking")

        status_box.pack_start(status_text, False, False, 0)
        status_box.pack_start(status_dot, False, False, 0)

        row_box.pack_start(status_box, False, False, 0)

        # Add service header to main container
        main_container.pack_start(row_box, False, False, 0)

        # Container list for Docker services (inside the same service-item)
        containers_box = None
        if server.get("type") == "docker_service":
            containers_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            containers_box.set_margin_start(28)  # Indent containers
            containers_box.set_margin_top(8)

            # Add containers
            containers = server.get("containers", [])
            for container in containers:
                container_row = self.create_container_row(container)
                containers_box.pack_start(container_row, False, False, 0)

            # Add containers to the main container (inside service-item)
            main_container.pack_start(containers_box, False, False, 0)

        # Add main container to event box
        event_box.add(main_container)

        # Store references for updates
        if not hasattr(self, "service_widgets"):
            self.service_widgets = {}

        self.service_widgets[index] = {
            "event_box": event_box,
            "status_text": status_text,
            "status_dot": status_dot,
            "response_label": response_label,
            "containers_box": containers_box,
            "server": server,
        }

        return event_box

    def create_container_row(self, container):
        """Create a row for an individual container"""
        container_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        container_box.set_margin_top(3)
        container_box.set_margin_bottom(3)
        container_box.set_margin_start(8)
        container_box.set_margin_end(8)

        # Container status dot
        status_dot = Gtk.Label(label="●")
        if container["is_running"]:
            status_dot.set_markup('<span color="#10b981">●</span>')  # Green
        else:
            status_dot.set_markup('<span color="#ef4444">●</span>')  # Red

        container_box.pack_start(status_dot, False, False, 0)

        # Container name
        name_label = Gtk.Label(label=container["name"])
        # Use theme-appropriate color for container names
        container_color = "#1f2937" if self.is_light_theme else "#e2e8f0"
        name_label.set_markup(
            f'<span size="small" color="{container_color}">{container["name"]}</span>'
        )
        name_label.set_halign(Gtk.Align.START)
        container_box.pack_start(name_label, True, True, 0)

        # Container status text
        status_text = "Running" if container["is_running"] else "Stopped"
        status_label = Gtk.Label(label=status_text)
        if container["is_running"]:
            status_label.set_markup(
                f'<span size="small" color="#10b981">{status_text}</span>'
            )
        else:
            status_label.set_markup(
                f'<span size="small" color="#ef4444">{status_text}</span>'
            )

        container_box.pack_start(status_label, False, False, 0)

        return container_box

    def check_server_url(self, url, timeout=2):
        """Check if a server is reachable using full URL"""
        try:
            import urllib.request
            import urllib.error

            start_time = time.time()

            # First check basic internet connectivity
            if not self.check_internet_connectivity():
                return False, 0

            try:
                # Create request with proper headers and timeout
                req = urllib.request.Request(url)
                req.add_header("User-Agent", "ServerMonitor/1.0")

                with urllib.request.urlopen(req, timeout=timeout) as response:
                    response_time = int((time.time() - start_time) * 1000)
                    # Consider 2xx and 3xx status codes as successful
                    return response.getcode() < 400, response_time

            except urllib.error.HTTPError as e:
                response_time = int((time.time() - start_time) * 1000)
                # Some HTTP errors still mean the server is reachable
                if e.code < 500:  # 4xx errors mean server is up but request issue
                    return True, response_time
                else:  # 5xx errors mean server issues
                    return False, response_time

            except urllib.error.URLError:
                response_time = int((time.time() - start_time) * 1000)
                return False, response_time

        except Exception as e:
            print(f"Error checking URL {url} - {e}")
            return False, 0

    def check_server(self, host, port, timeout=2):
        """Check if a server is reachable and measure response time"""
        try:
            import urllib.request
            import urllib.error

            start_time = time.time()

            # First check basic internet connectivity
            if not self.check_internet_connectivity():
                return False, 0

            # Build URL based on port
            if port == 443:
                url = f"https://{host}"
            elif port == 80:
                url = f"http://{host}"
            else:
                # For custom ports, try HTTPS first, then HTTP
                url = f"https://{host}:{port}"

            try:
                # Create request with proper headers and timeout
                req = urllib.request.Request(url)
                req.add_header("User-Agent", "ServerMonitor/1.0")

                with urllib.request.urlopen(req, timeout=timeout) as response:
                    response_time = int((time.time() - start_time) * 1000)
                    # Consider 2xx and 3xx status codes as successful
                    return response.getcode() < 400, response_time

            except urllib.error.HTTPError as e:
                response_time = int((time.time() - start_time) * 1000)
                # Some HTTP errors still mean the server is reachable
                if e.code < 500:  # 4xx errors mean server is up but request issue
                    return True, response_time
                else:  # 5xx errors mean server issues
                    return False, response_time

            except urllib.error.URLError:
                # If HTTPS failed and we're using a custom port, try HTTP
                if port != 80 and port != 443 and url.startswith("https://"):
                    try:
                        http_url = f"http://{host}:{port}"
                        req = urllib.request.Request(http_url)
                        req.add_header("User-Agent", "ServerMonitor/1.0")

                        with urllib.request.urlopen(req, timeout=timeout) as response:
                            response_time = int((time.time() - start_time) * 1000)
                            return response.getcode() < 400, response_time
                    except:
                        pass

                # Fall back to socket connection test
                return self.check_socket_connection(host, port, timeout, start_time)

        except Exception as e:
            print(f"Error checking {host}:{port} - {e}")
            return False, 0

    def check_internet_connectivity(self):
        """Check if we have basic internet connectivity with caching"""
        current_time = time.time()

        # Use cached result if it's less than 5 seconds old
        if (current_time - self.internet_cache["timestamp"]) < 5:
            return self.internet_cache["status"]

        try:
            # Fast DNS resolution check first
            socket.gethostbyname("google.com")
            result = True
        except:
            try:
                # Fallback: try reaching a reliable service
                import urllib.request

                req = urllib.request.Request("https://8.8.8.8", timeout=1)
                urllib.request.urlopen(req)
                result = True
            except:
                result = False

        # Cache the result
        self.internet_cache = {"status": result, "timestamp": current_time}
        return result

    def check_socket_connection(self, host, port, timeout, start_time):
        """Fallback socket connection test"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port))
            sock.close()
            response_time = int((time.time() - start_time) * 1000)
            return result == 0, response_time
        except Exception as e:
            print(f"Socket connection failed for {host}:{port} - {e}")
            return False, 0

    def clean_host(self, host):
        """Extract hostname from URL, removing protocol, port, and path"""
        import urllib.parse

        # If it looks like a full URL, parse it properly
        if "://" in host:
            parsed = urllib.parse.urlparse(host)
            return parsed.hostname  # This gives us just the hostname without port

        # If it's just a hostname with port, extract just the hostname
        if ":" in host:
            return host.split(":")[0]

        # If it's just a hostname, return as-is
        return host

    def get_default_port(self, server):
        """Get the appropriate default port for a server"""
        import urllib.parse

        # If port is explicitly set in config, use it
        if "port" in server and server["port"] is not None:
            return server["port"]

        host = server.get("host", "")

        # If it's a full URL, extract port from it
        if "://" in host:
            parsed = urllib.parse.urlparse(host)
            if parsed.port:
                return parsed.port
            # Use default port based on scheme
            if parsed.scheme == "https":
                return 443
            else:
                return 80

        # For plain hostnames, use HTTPS default if it looks like HTTPS
        if host.startswith("https://"):
            return 443
        else:
            return 80

    def discover_docker_containers(self):
        """Discover all Docker containers"""
        try:
            # Get all containers (running and stopped)
            result = subprocess.run(
                [
                    "docker",
                    "ps",
                    "-a",
                    "--format",
                    "{{.Names}}\t{{.Status}}\t{{.Image}}",
                ],
                capture_output=True,
                text=True,
                timeout=10,
            )

            containers = []
            if result.returncode == 0 and result.stdout.strip():
                for line in result.stdout.strip().split("\n"):
                    if line.strip():
                        parts = line.split("\t")
                        if len(parts) >= 2:
                            name = parts[0]
                            status = parts[1]
                            image = parts[2] if len(parts) > 2 else "unknown"

                            containers.append(
                                {
                                    "name": name,
                                    "status": status,
                                    "image": image,
                                    "is_running": "Up" in status,
                                }
                            )

            return containers

        except subprocess.TimeoutExpired:
            print("Docker discovery timed out")
            return []
        except FileNotFoundError:
            print("Docker not installed or not in PATH")
            return []
        except Exception as e:
            print(f"Error discovering Docker containers: {e}")
            return []

    def check_docker_container(self, container_name):
        """Check if a Docker container is running"""
        try:
            start_time = time.time()

            # Check if Docker is available
            result = subprocess.run(
                [
                    "docker",
                    "ps",
                    "--filter",
                    f"name={container_name}",
                    "--format",
                    "{{.Status}}",
                ],
                capture_output=True,
                text=True,
                timeout=5,
            )

            response_time = int((time.time() - start_time) * 1000)

            if result.returncode == 0 and result.stdout.strip():
                # Container exists and has status
                status_line = result.stdout.strip()
                is_running = "Up" in status_line
                return is_running, response_time
            else:
                # Container not found or Docker not available
                return False, response_time

        except subprocess.TimeoutExpired:
            return False, 5000  # 5 second timeout
        except FileNotFoundError:
            # Docker command not found
            print(f"Docker not installed or not in PATH")
            return False, 0
        except Exception as e:
            print(f"Error checking Docker container {container_name}: {e}")
            return False, 0

    def check_all_servers(self):
        """Check all servers and Docker containers in parallel for faster results"""
        import concurrent.futures

        # Check internet connectivity once at the start
        has_internet = self.check_internet_connectivity()

        def check_single_server(index_server_pair):
            i, server = index_server_pair

            if server.get("type") == "docker_service":
                # Check Docker service with pre-discovered containers (fast)
                containers = server.get("containers", [])
                running_count = 0
                container_statuses = {}

                for container in containers:
                    container_name = container["name"]
                    is_running = container["is_running"]

                    container_statuses[container_name] = {
                        "status": "operational" if is_running else "down",
                        "image": container["image"],
                        "docker_status": container["status"],
                    }

                    if is_running:
                        running_count += 1

                # Overall service status
                total_containers = len(containers)
                if total_containers == 0:
                    overall_status = "down"
                elif running_count == total_containers:
                    overall_status = "operational"
                elif running_count > 0:
                    overall_status = "degraded"
                else:
                    overall_status = "down"

                return i, {
                    "status": overall_status,
                    "response_time": 25,  # Quick since containers are pre-discovered
                    "containers": container_statuses,
                    "message": f"{running_count}/{total_containers} containers running",
                }
            else:
                # Check regular server/service
                if not has_internet:
                    return i, {
                        "status": "down",
                        "response_time": 0,
                        "message": "No internet connection",
                    }

                host = server.get("host", "")

                # If it's a full URL, use it directly; otherwise use host/port approach
                if "://" in host:
                    is_online, response_time = self.check_server_url(host, timeout=2)
                else:
                    port = self.get_default_port(server)
                    clean_host = self.clean_host(host)
                    is_online, response_time = self.check_server(
                        clean_host, port, timeout=2
                    )

                status_message = f"{response_time}ms response time"
                if not is_online and response_time == 0:
                    status_message = "Connection failed"
                elif not is_online:
                    status_message = f"Server error ({response_time}ms)"

                return i, {
                    "status": "operational" if is_online else "down",
                    "response_time": response_time,
                    "message": status_message,
                }

        # Execute all server checks in parallel
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            # Submit all server checks
            future_to_index = {
                executor.submit(check_single_server, (i, server)): i
                for i, server in enumerate(self.servers)
            }

            # Process results as they complete
            try:
                for future in concurrent.futures.as_completed(
                    future_to_index, timeout=8
                ):
                    try:
                        index, status_info = future.result()
                        self.server_status[index] = status_info
                        # Update UI immediately as each server completes
                        GLib.idle_add(self.update_server_display, index)
                    except Exception as e:
                        index = future_to_index[future]
                        print(f"Error checking server {index}: {e}")
                        self.server_status[index] = {
                            "status": "down",
                            "response_time": 0,
                            "message": "Check failed",
                        }
                        GLib.idle_add(self.update_server_display, index)
            except concurrent.futures.TimeoutError:
                # Handle timeout - mark remaining futures as timed out
                print("Some server checks timed out, marking as down...")
                for future, index in future_to_index.items():
                    if not future.done():
                        future.cancel()  # Try to cancel if possible
                        self.server_status[index] = {
                            "status": "down",
                            "response_time": 0,
                            "message": "Connection timeout",
                        }
                        GLib.idle_add(self.update_server_display, index)

        # Update summary, timestamp, and network status
        GLib.idle_add(self.update_summary)
        GLib.idle_add(self.update_timestamp)
        GLib.idle_add(self.update_network_status)

    def update_server_display(self, index):
        """Update the display for a specific server"""
        if index not in self.service_widgets:
            return False

        status_info = self.server_status[index]
        widgets = self.service_widgets[index]

        status = status_info["status"]
        response_time = status_info["response_time"]

        # Update response time and message
        if "message" in status_info:
            # Use the detailed message (works for both Docker services and regular servers)
            widgets["response_label"].set_text(status_info["message"])
        else:
            # Fallback for regular service without detailed message
            widgets["response_label"].set_text(f"{response_time}ms response time")

        # Remove old status classes
        status_context = widgets["status_text"].get_style_context()
        dot_context = widgets["status_dot"].get_style_context()

        for cls in [
            "status-operational",
            "status-degraded",
            "status-down",
            "status-checking",
        ]:
            status_context.remove_class(cls)
            dot_context.remove_class(cls)

        # Update status text and add new classes
        if status == "operational":
            widgets["status_text"].set_text("Operational")
            status_context.add_class("status-operational")
            dot_context.add_class("status-operational")
        elif status == "degraded":
            widgets["status_text"].set_text("Degraded")
            status_context.add_class("status-degraded")
            dot_context.add_class("status-degraded")
        elif status == "down":
            widgets["status_text"].set_text("Down")
            status_context.add_class("status-down")
            dot_context.add_class("status-down")
        else:
            widgets["status_text"].set_text("Checking")
            status_context.add_class("status-checking")
            dot_context.add_class("status-checking")

        return False

    def update_summary(self):
        """Update the overall status summary"""
        operational = sum(
            1
            for status in self.server_status.values()
            if status["status"] == "operational"
        )
        total = len(self.servers)
        self.status_summary.set_text(f"{operational} / {total} Operational")
        return False

    def update_timestamp(self):
        """Update the last updated timestamp"""
        current_time = time.strftime("%H:%M:%S")
        self.last_updated.set_text(f"Last updated: {current_time}")
        return False

    def update_network_status(self):
        """Update the network connectivity status indicator"""
        if self.check_internet_connectivity():
            self.network_status.set_text("🌐 Connected")
            self.network_status.get_style_context().remove_class("network-disconnected")
            self.network_status.get_style_context().add_class("network-connected")
        else:
            self.network_status.set_text("🚫 No Internet")
            self.network_status.get_style_context().remove_class("network-connected")
            self.network_status.get_style_context().add_class("network-disconnected")
        return False

    def start_monitoring(self):
        """Start the monitoring loop"""

        def monitor_loop():
            while True:
                self.check_all_servers()
                time.sleep(15)  # Check every 15 seconds for faster updates

        thread = threading.Thread(target=monitor_loop, daemon=True)
        thread.start()

        # Initial check
        thread = threading.Thread(target=self.check_all_servers, daemon=True)
        thread.start()

    def on_refresh(self, button):
        """Manual refresh button handler - re-discovers Docker containers"""
        button.set_label("🔄")

        # Set all servers to checking state
        for i in range(len(self.servers)):
            self.server_status[i] = {"status": "checking", "response_time": 0}
            GLib.idle_add(self.update_server_display, i)

        def full_refresh():
            # Re-discover Docker services
            self.refresh_docker_services()
            # Rebuild UI
            GLib.idle_add(self.rebuild_ui)
            # Check all servers
            self.check_all_servers()
            # Reset button
            GLib.idle_add(lambda: button.set_label("⟳"))

        thread = threading.Thread(target=full_refresh, daemon=True)
        thread.start()

    def on_theme_toggle(self, button):
        """Toggle between dark and light themes"""
        self.is_light_theme = not self.is_light_theme

        if self.is_light_theme:
            button.set_label("☀️")
            button.set_tooltip_text("Switch to Dark Theme")
            # Add light-theme CSS class to the main container
            self.main_box.get_style_context().add_class("light-theme")
        else:
            button.set_label("🌙")
            button.set_tooltip_text("Switch to Light Theme")
            # Remove light-theme CSS class from the main container
            self.main_box.get_style_context().remove_class("light-theme")

        # Rebuild UI to apply theme changes to container names (without re-checking services)
        self.rebuild_ui_theme_only()

        # Force a redraw to apply the new theme
        self.queue_draw()

    def on_minimize(self, button):
        """Toggle minimize state"""
        self.minimized = not self.minimized

        if self.minimized:
            # Store current size before minimizing
            current_width, current_height = self.get_size()
            if current_height > 200:  # Only store if not already minimized
                self.full_width = current_width
                self.full_height = current_height

            self.services_container.hide()
            button.set_label("+")
            button.get_style_context().add_class("expand-button")
            button.set_tooltip_text("Expand")

            # Force resize to minimized size
            self.resize(self.minimized_width, self.minimized_height)
        else:
            self.services_container.show()
            button.set_label("−")
            button.set_tooltip_text("Minimize")
            button.get_style_context().remove_class("expand-button")
            button.get_style_context().add_class("minimize-button")

            # Force resize to full size
            self.resize(self.full_width, self.full_height)

    def on_close(self, button):
        """Close button handler"""
        Gtk.main_quit()

    def on_draw(self, widget, cr):
        """Draw rounded background with transparency"""
        # Background with transparency - theme dependent
        if self.is_light_theme:
            # Light theme: light gray background rgb(245, 245, 245)
            cr.set_source_rgba(245 / 255, 245 / 255, 245 / 255, 0.97)
        else:
            # Dark theme: dark background #131211 = rgb(19, 18, 17)
            cr.set_source_rgba(19 / 255, 18 / 255, 17 / 255, 0.95)

        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        radius = 12

        # Rounded rectangle
        cr.arc(radius, radius, radius, 3.14, 3.14 * 1.5)
        cr.arc(width - radius, radius, radius, 3.14 * 1.5, 0)
        cr.arc(width - radius, height - radius, radius, 0, 3.14 * 0.5)
        cr.arc(radius, height - radius, radius, 3.14 * 0.5, 3.14)
        cr.close_path()
        cr.fill()

        # Border (commented out to remove white border)
        # cr.set_source_rgba(51 / 255, 65 / 255, 85 / 255, 0.8)
        # cr.set_line_width(1)
        # cr.arc(radius, radius, radius, 3.14, 3.14 * 1.5)
        # cr.arc(width - radius, radius, radius, 3.14 * 1.5, 0)
        # cr.arc(width - radius, height - radius, radius, 0, 3.14 * 0.5)
        # cr.arc(radius, height - radius, radius, 3.14 * 0.5, 3.14)
        # cr.close_path()
        # cr.stroke()

        return False

    def on_button_press(self, widget, event):
        if event.button == 1:
            self.is_dragging = True
            self.drag_start_x = event.x_root - self.get_position()[0]
            self.drag_start_y = event.y_root - self.get_position()[1]
        return True

    def on_button_release(self, widget, event):
        if event.button == 1:
            self.is_dragging = False
        return True

    def on_motion(self, widget, event):
        if self.is_dragging:
            new_x = int(event.x_root - self.drag_start_x)
            new_y = int(event.y_root - self.drag_start_y)
            self.move(new_x, new_y)
        return True


def main():
    parser = argparse.ArgumentParser(description="Server Status Monitor Widget")
    parser.add_argument("--check", action="store_true", help="Check dependencies")

    args = parser.parse_args()

    if args.check:
        print("Checking dependencies...")
        print("✅ GTK3 is available")

        css_file = Path(__file__).parent / "widget-gtk.css"
        if css_file.exists():
            print("✅ CSS file found")
        else:
            print("⚠️  CSS file not found")
        return

    try:
        widget = ServerMonitorWidget()
        widget.connect("destroy", Gtk.main_quit)
        widget.show_all()

        print("Server Status Widget started!")
        print("• Drag to move around your desktop")
        print("• Edit widget-gtk.css to customize styling")
        print("• Press Ctrl+C or click X to close")

        Gtk.main()
    except KeyboardInterrupt:
        print("\nWidget closed.")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
