#!/usr/bin/env python3
"""
🛰️ Sato Enhanced Monitoring System
A comprehensive infrastructure monitoring system with advanced capabilities
"""

import gi
import json
import threading
import time
import sys
from pathlib import Path

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib

# Import our enhanced components
from core.settings import SettingsManager, ServerConfig, CheckType, ThemeType
from core.health_checker import HealthChecker
from core.status_tracker import StatusTracker
from core.notifications import NotificationManager
from core.system_tray import SystemTrayManager
from core.performance_optimizer import PerformanceOptimizer, FastHealthChecker


class SatoMonitoringSystem(Gtk.Window):
    def __init__(self):
        super().__init__()

        # Initialize core components
        self.config_dir = Path(__file__).parent
        self.settings_manager = SettingsManager(self.config_dir)

        # Add Docker services to the settings manager
        self.discover_and_add_docker_services()

        self.health_checker = HealthChecker()
        self.fast_health_checker = FastHealthChecker()
        self.performance_optimizer = PerformanceOptimizer(max_workers=3)
        self.status_tracker = StatusTracker(
            self.config_dir / "history.json",
            self.settings_manager.monitoring_settings.history_retention_days,
        )
        # Initialize notification manager (now includes enhanced features)
        self.notification_manager = NotificationManager(
            self.settings_manager.notification_settings
        )

        # Load CSS styling
        self.load_css()

        # Server status tracking
        self.server_status = {}
        self.service_widgets = {}
        self.last_status = {}  # Track status changes for notifications

        # Theme state
        self.is_light_theme = self.settings_manager.ui_settings.theme == ThemeType.LIGHT

        # Monitoring control
        self.monitoring_active = True
        self.monitoring_threads = {}

        # Advanced features
        self.auto_restart_enabled = True
        self.maintenance_mode = False
        self.retry_counts = {}  # Track retry attempts per service
        self.failure_timestamps = {}  # Track failure times for backoff
        self.healing_actions = {}  # Track healing actions taken
        self.service_dependencies = {}  # Service dependency mapping

        # Alert grouping and acknowledgment
        self.alert_groups = {}  # Group related alerts
        self.acknowledged_alerts = {}  # Track acknowledged alerts
        self.alert_suppression_window = 300  # 5 minutes
        self.pending_alerts = {}  # Alerts waiting to be grouped

        # Animated backgrounds (disabled by default to prevent performance issues)
        self.animation_enabled = False  # Temporarily disabled
        self.animation_frame = 0
        self.animation_timer_id = None
        self.background_colors = [
            (19 / 255, 18 / 255, 17 / 255, 0.95),  # Dark base
            (25 / 255, 24 / 255, 23 / 255, 0.95),  # Slightly lighter
            (19 / 255, 22 / 255, 20 / 255, 0.95),  # Green tint
            (22 / 255, 19 / 255, 20 / 255, 0.95),  # Red tint
        ]

        # Setup window
        self.setup_window()

        # Create UI
        self.create_ui()

        # Apply initial settings
        self.apply_compact_mode()

        # Setup system tray
        self.system_tray = SystemTrayManager(self, self.settings_manager)

        # Connect signals
        self.connect_signals()

        # Start monitoring after a short delay to ensure UI is ready
        GLib.timeout_add_seconds(1, self.start_enhanced_monitoring)

        # Initialize advanced features
        GLib.timeout_add_seconds(
            2, lambda: (self.discover_service_dependencies(), False)
        )

        # Start controlled animation if enabled
        if self.animation_enabled:
            self.start_animation()

        print("🛰️ Sato Enhanced Monitoring System initialized!")
        print(f"📊 Monitoring {len(self.settings_manager.servers)} servers")
        print(f"🎨 Theme: {self.settings_manager.ui_settings.theme.value}")
        print(
            f"🔔 Notifications: {'enabled' if self.settings_manager.notification_settings.desktop_notifications else 'disabled'}"
        )
        print(
            f"🔄 Auto-restart: {'enabled' if self.auto_restart_enabled else 'disabled'}"
        )
        print(
            f"🔧 Maintenance mode: {'enabled' if self.maintenance_mode else 'disabled'}"
        )
        print(f"⚡ Parallel processing: enabled (3 workers)")
        print(f"🚀 Performance optimizations: active")
        print(f"💨 Responsiveness: optimized (8s cycles, 3s timeouts)")

    def setup_window(self):
        """Setup window properties from settings"""
        ui_settings = self.settings_manager.ui_settings

        # Window decoration
        self.set_decorated(False)
        self.set_type_hint(Gdk.WindowTypeHint.NORMAL)

        # Window behavior
        self.set_keep_above(ui_settings.always_on_top)
        self.set_default_size(ui_settings.window_width, ui_settings.window_height)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_resizable(True)

        # Size constraints
        self.set_size_request(675, 800)
        geometry = Gdk.Geometry()
        geometry.min_width = 675
        geometry.min_height = 800
        geometry.max_width = 1000
        geometry.max_height = 1200
        self.set_geometry_hints(
            self, geometry, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE
        )

        # Transparency and opacity
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
            self.set_app_paintable(True)
            # Apply opacity setting
            self.set_window_opacity(ui_settings.opacity)

        # Auto-hide setup
        self.auto_hide_enabled = ui_settings.auto_hide
        if self.auto_hide_enabled:
            self.connect("focus-out-event", self.on_focus_out)

        # Dragging support
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.is_dragging = False

    def set_window_opacity(self, opacity):
        """Set window opacity without deprecation warnings"""
        import warnings

        with warnings.catch_warnings():
            warnings.simplefilter("ignore", DeprecationWarning)
            try:
                self.set_opacity(opacity)
                return True
            except AttributeError:
                # Fallback for older GTK versions
                return False

    def load_css(self):
        """Load CSS styling from external file"""
        css_file = self.config_dir / "config" / "widget-gtk.css"

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

    def create_ui(self):
        """Create the enhanced user interface"""
        # Main container
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.main_box.set_margin_top(20)
        self.main_box.set_margin_bottom(20)
        self.main_box.set_margin_start(20)
        self.main_box.set_margin_end(20)

        # Apply theme class if light theme
        if self.is_light_theme:
            self.main_box.get_style_context().add_class("light-theme")

        # Create header
        self.create_header()

        # Spacing
        self.main_box.pack_start(Gtk.Box(), False, False, 20)

        # Create services container with scrolling
        self.create_services_container()

        # Create footer
        self.create_footer()

        self.add(self.main_box)

    def create_header(self):
        """Create the header section"""
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        header_box.set_valign(Gtk.Align.START)

        # Title section
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title_box.set_valign(Gtk.Align.START)

        title = Gtk.Label(label="System Status")
        title.get_style_context().add_class("widget-title")
        title.set_halign(Gtk.Align.START)

        self.last_updated = Gtk.Label(label="Last updated: Now")
        self.last_updated.get_style_context().add_class("widget-subtitle")
        self.last_updated.set_halign(Gtk.Align.START)

        self.network_status = Gtk.Label(label="🌐 Connected")
        self.network_status.get_style_context().add_class("network-status")
        self.network_status.set_halign(Gtk.Align.START)

        title_box.pack_start(title, False, False, 0)
        title_box.pack_start(self.last_updated, False, False, 0)
        title_box.pack_start(self.network_status, False, False, 0)

        header_box.pack_start(title_box, True, True, 0)

        # Buttons
        self.create_header_buttons(header_box)

        self.main_box.pack_start(header_box, False, False, 0)

    def create_header_buttons(self, header_box):
        """Create header buttons"""
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        button_box.set_halign(Gtk.Align.END)
        button_box.set_valign(Gtk.Align.START)

        # Refresh button
        self.refresh_btn = Gtk.Button(label="🔄")
        self.refresh_btn.set_tooltip_text("Refresh All (Ctrl+R)")
        self.refresh_btn.set_size_request(30, 30)
        self.refresh_btn.connect("clicked", self.on_refresh)

        # Settings button
        self.settings_btn = Gtk.Button(label="⚙️")
        self.settings_btn.set_tooltip_text("Settings (Ctrl+S)")
        self.settings_btn.set_size_request(30, 30)
        self.settings_btn.connect("clicked", self.on_settings)

        # Theme toggle button
        theme_icon = "☀️" if self.is_light_theme else "🌙"
        self.theme_btn = Gtk.Button(label=theme_icon)
        self.theme_btn.set_tooltip_text("Toggle Theme (Ctrl+T)")
        self.theme_btn.set_size_request(30, 30)
        self.theme_btn.connect("clicked", self.on_theme_toggle)

        # Minimize button
        self.minimize_btn = Gtk.Button(label="➖")
        self.minimize_btn.set_tooltip_text("Minimize to Tray")
        self.minimize_btn.set_size_request(30, 30)
        self.minimize_btn.get_style_context().add_class("minimize-button")
        self.minimize_btn.connect("clicked", self.on_minimize)

        # Close button
        close_btn = Gtk.Button(label="❌")
        close_btn.set_tooltip_text("Close")
        close_btn.set_size_request(30, 30)
        close_btn.get_style_context().add_class("close-button")
        close_btn.connect("clicked", self.on_close)

        # Maintenance mode button
        self.maintenance_btn = Gtk.Button(label="🔧")
        self.maintenance_btn.set_tooltip_text("Toggle Maintenance Mode")
        self.maintenance_btn.set_size_request(30, 30)
        self.maintenance_btn.connect("clicked", self.on_maintenance_toggle)

        # Alert management button
        self.alerts_btn = Gtk.Button(label="🔔")
        self.alerts_btn.set_tooltip_text("Alert Management")
        self.alerts_btn.set_size_request(30, 30)
        self.alerts_btn.connect("clicked", lambda btn: self.show_alert_management())

        # Help button
        help_btn = Gtk.Button(label="❔")
        help_btn.set_tooltip_text("Keyboard Shortcuts")
        help_btn.set_size_request(30, 30)
        help_btn.connect("clicked", self.show_keyboard_shortcuts)

        button_box.pack_start(self.refresh_btn, False, False, 0)
        button_box.pack_start(self.settings_btn, False, False, 0)
        button_box.pack_start(self.theme_btn, False, False, 0)
        button_box.pack_start(self.maintenance_btn, False, False, 0)
        button_box.pack_start(self.alerts_btn, False, False, 0)
        button_box.pack_start(help_btn, False, False, 0)
        button_box.pack_start(self.minimize_btn, False, False, 0)
        button_box.pack_start(close_btn, False, False, 0)

        header_box.pack_start(button_box, False, False, 0)

    def create_services_container(self):
        """Create scrollable services container"""
        # Services sections with scrollable container
        self.services_container = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL, spacing=20
        )

        # Create scrolled window for services
        self.scrolled_window = Gtk.ScrolledWindow()
        self.scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scrolled_window.set_max_content_height(800)
        self.scrolled_window.set_propagate_natural_height(True)
        self.scrolled_window.add(self.services_container)

        # Build services sections
        self.rebuild_services_ui()

        self.main_box.pack_start(self.scrolled_window, True, True, 0)

    def create_footer(self):
        """Create the footer section"""
        self.main_box.pack_start(Gtk.Box(), False, False, 20)

        footer_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        footer_label = Gtk.Label(label="Overall Status")
        footer_label.get_style_context().add_class("footer-label")
        footer_label.set_halign(Gtk.Align.START)

        self.status_summary = Gtk.Label(label="0 / 0 Operational")
        self.status_summary.get_style_context().add_class("footer-status")
        self.status_summary.set_halign(Gtk.Align.END)

        footer_box.pack_start(footer_label, True, True, 0)
        footer_box.pack_start(self.status_summary, False, False, 0)

        self.main_box.pack_start(footer_box, False, False, 0)

    def rebuild_services_ui(self):
        """Rebuild the services UI from settings"""

        # Clear existing services and widget references
        for child in self.services_container.get_children():
            self.services_container.remove(child)

        # Initialize/clear widget dictionary
        if not hasattr(self, "service_widgets"):
            self.service_widgets = {}
        else:
            self.service_widgets.clear()

        # Group servers by type and group
        server_groups = self.settings_manager.get_servers_by_group()

        # Create sections for each group
        for group_name, servers in server_groups.items():
            if not servers:
                continue

            # Separate by type within group
            regular_servers = [s for s in servers if s.type == "server"]
            docker_services = [s for s in servers if s.type == "docker_service"]

            # Create group section
            if regular_servers:
                section = self.create_services_section(
                    f"{group_name.upper()} SERVICES", regular_servers
                )
                self.services_container.pack_start(section, False, False, 0)

            if docker_services:
                section = self.create_services_section(
                    f"{group_name.upper()} CONTAINERS", docker_services
                )
                self.services_container.pack_start(section, False, False, 0)

        # Initialize server status tracking (preserve existing data during rebuilds)
        if not hasattr(self, "server_status"):
            self.server_status = {}

        # Only initialize status for new servers or if starting fresh
        for i, server in enumerate(self.settings_manager.servers):
            if i not in self.server_status:
                self.server_status[i] = {
                    "status": "checking",
                    "response_time": 0,
                    "message": "Initializing...",
                }

        self.services_container.show_all()

    def create_services_section(self, title, servers):
        """Create a services section"""
        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)

        # Section title
        title_label = Gtk.Label(label=title)
        title_label.get_style_context().add_class("section-title")
        title_label.set_halign(Gtk.Align.START)
        section_box.pack_start(title_label, False, False, 0)

        # Services
        for server in servers:
            # Find server index in the main list
            server_index = self.settings_manager.servers.index(server)
            service_row = self.create_service_row(server_index, server)
            section_box.pack_start(service_row, False, False, 0)

        return section_box

    def create_service_row(self, index, server):
        """Create a service row with enhanced features"""
        # Create main service row
        event_box = Gtk.EventBox()
        event_box.get_style_context().add_class("service-item")

        # Main container
        main_container = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_container.set_margin_top(10)
        main_container.set_margin_bottom(10)
        main_container.set_margin_start(12)
        main_container.set_margin_end(12)

        # Service header row
        row_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        # Service icon
        icon_text = self.get_service_icon(server)
        icon_label = Gtk.Label(label=icon_text)
        icon_label.get_style_context().add_class("service-icon")
        row_box.pack_start(icon_label, False, False, 0)

        # Service details
        details_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        name_label = Gtk.Label(label=server.name)
        name_label.get_style_context().add_class("service-name")
        name_label.set_halign(Gtk.Align.START)

        # Enhanced response info
        response_label = Gtk.Label(label="Initializing...")
        response_label.get_style_context().add_class("service-response")
        response_label.set_halign(Gtk.Align.START)

        details_box.pack_start(name_label, False, False, 0)
        details_box.pack_start(response_label, False, False, 0)

        row_box.pack_start(details_box, True, True, 0)

        # Status section
        status_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)

        status_text = Gtk.Label(label="Checking")
        status_text.get_style_context().add_class("status-checking")

        status_dot = Gtk.Label(label="●")
        status_dot.get_style_context().add_class("status-dot")
        status_dot.get_style_context().add_class("status-checking")

        status_box.pack_start(status_text, False, False, 0)
        status_box.pack_start(status_dot, False, False, 0)

        row_box.pack_start(status_box, False, False, 0)

        main_container.pack_start(row_box, False, False, 0)

        # Add container details for Docker services
        containers_box = None
        if server.type == "docker_service" and hasattr(server, "containers"):
            containers_box = self.create_containers_section(server)
            main_container.pack_start(containers_box, False, False, 0)

        event_box.add(main_container)

        # Add click handler for service details popup
        event_box.connect("button-press-event", self.on_service_click, index)

        # Store widget references
        self.service_widgets[index] = {
            "event_box": event_box,
            "status_text": status_text,
            "status_dot": status_dot,
            "response_label": response_label,
            "containers_box": containers_box,
            "server": server,
            "sparkline": None,  # Will be added later
        }

        return event_box

    def create_containers_section(self, server):
        """Create containers section for Docker services"""
        containers_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        containers_box.set_margin_start(28)
        containers_box.set_margin_top(8)

        if hasattr(server, "containers"):
            for container in server.containers:
                container_row = self.create_container_row(container)
                containers_box.pack_start(container_row, False, False, 0)

        return containers_box

    def create_container_row(self, container):
        """Create a container row"""
        container_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        container_box.set_margin_top(3)
        container_box.set_margin_bottom(3)
        container_box.set_margin_start(8)
        container_box.set_margin_end(8)

        # Status dot
        status_dot = Gtk.Label(label="●")
        if container.get("is_running", False):
            status_dot.set_markup('<span color="#10b981">●</span>')
        else:
            status_dot.set_markup('<span color="#ef4444">●</span>')

        container_box.pack_start(status_dot, False, False, 0)

        # Container name
        name_label = Gtk.Label(label=container.get("name", "Unknown"))
        container_color = "#1f2937" if self.is_light_theme else "#e2e8f0"
        name_label.set_markup(
            f'<span size="small" color="{container_color}">{container.get("name", "Unknown")}</span>'
        )
        name_label.set_halign(Gtk.Align.START)
        container_box.pack_start(name_label, True, True, 0)

        # Status text
        status_text = "Running" if container.get("is_running", False) else "Stopped"
        status_label = Gtk.Label(label=status_text)
        if container.get("is_running", False):
            status_label.set_markup(
                f'<span size="small" color="#10b981">{status_text}</span>'
            )
        else:
            status_label.set_markup(
                f'<span size="small" color="#ef4444">{status_text}</span>'
            )

        container_box.pack_start(status_label, False, False, 0)

        return container_box

    def get_service_icon(self, server):
        """Get icon for a service"""
        # Custom icon from config
        if hasattr(server, "icon") and server.icon:
            return server.icon

        # Docker services
        if server.type == "docker_service":
            return "🐳"

        # Default icon mapping
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
        }

        return icon_map.get(server.name, "☁️")

    def discover_and_add_docker_services(self):
        """Discover Docker services and add them to settings manager"""
        try:
            import subprocess

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
                print("🐳 No Docker containers found or Docker not available")
                return

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
                            name, self.get_service_name_from_container(name)
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

            # Add each service to settings manager
            for service_name, containers in services.items():
                # Sort containers alphabetically by name
                sorted_containers = sorted(containers, key=lambda x: x["name"].lower())

                # Create server config for Docker service
                docker_service = ServerConfig(
                    name=service_name,
                    host="localhost",  # Docker services are local
                    type="docker_service",
                    check_type=CheckType.CUSTOM,  # We'll use custom checking for Docker
                    group="Docker Services",
                    icon="🐳",
                )

                # Add containers as attribute
                docker_service.containers = sorted_containers

                # Check if this service already exists
                existing_service = self.settings_manager.get_server_by_name(
                    service_name
                )
                if not existing_service:
                    self.settings_manager.servers.append(docker_service)
                    print(
                        f"🐳 Added Docker service: {service_name} ({len(sorted_containers)} containers)"
                    )
                else:
                    # Update existing service with new container info
                    existing_service.containers = sorted_containers
                    print(
                        f"🐳 Updated Docker service: {service_name} ({len(sorted_containers)} containers)"
                    )

        except Exception as e:
            print(f"⚠️ Error discovering Docker services: {e}")

    def get_container_projects(self):
        """Get Docker Compose project names for all containers"""
        try:
            import subprocess

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

    def get_service_name_from_container(self, container_name):
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

    def start_enhanced_monitoring(self):
        """Start enhanced monitoring with performance optimizations"""
        print("🔄 Starting enhanced monitoring with parallel processing...")

        # Enable parallel monitoring for better performance
        self.settings_manager.monitoring_settings.parallel_checks = True

        # Optimize server settings for performance
        for i, server in enumerate(self.settings_manager.servers):
            if getattr(server, "enabled", True):
                # Optimize check intervals for responsiveness
                if not hasattr(server, "check_interval") or server.check_interval < 8:
                    server.check_interval = 10  # Minimum 10 seconds for faster updates

                # Optimize timeouts for quick response
                if not hasattr(server, "timeout") or server.timeout > 5:
                    server.timeout = 3  # Maximum 3 seconds timeout for faster response

                # Initialize performance tracking
                if not hasattr(server, "_consecutive_success"):
                    server._consecutive_success = 0

        # Start batch monitoring instead of individual threads
        self.start_batch_monitoring()

        # Start global update thread
        self.start_global_updates()

        return False  # Don't repeat this timeout

    def start_batch_monitoring(self):
        """Start batch monitoring for better performance"""

        def batch_monitor():
            while self.monitoring_active:
                try:
                    # Separate Docker services for batch processing
                    docker_services = []
                    regular_services = []

                    for i, server in enumerate(self.settings_manager.servers):
                        if getattr(server, "enabled", True):
                            if server.type == "docker_service":
                                docker_services.append((i, server))
                            else:
                                regular_services.append((i, server))

                    # Batch process Docker services
                    if docker_services:
                        docker_results = self.performance_optimizer.batch_docker_checks(
                            docker_services
                        )
                        for server_index, result in docker_results.items():
                            self.process_check_result(server_index, result)

                    # Process regular services with independent threads for immediate updates
                    for server_index, server in regular_services:

                        def create_check_thread(srv_idx, srv):
                            def check_and_update():
                                try:
                                    result = self.health_checker.check_server(
                                        srv, timeout=4
                                    )
                                    # Process result immediately when ready
                                    self.process_check_result(srv_idx, result)
                                except Exception as e:
                                    from core.health_checker import CheckResult

                                    error_result = CheckResult(
                                        False, 0, f"Check failed: {str(e)}"
                                    )
                                    self.process_check_result(srv_idx, error_result)

                            # Start independent thread - results appear as soon as ready
                            thread = threading.Thread(
                                target=check_and_update, daemon=True
                            )
                            thread.start()
                            return thread

                        create_check_thread(server_index, server)

                except Exception as e:
                    print(f"❌ Error in batch monitoring: {e}")

                # Wait before next batch (optimized for responsiveness)
                time.sleep(8)  # Check every 8 seconds for faster response

        # Start batch monitoring thread
        self.batch_thread = threading.Thread(target=batch_monitor, daemon=True)
        self.batch_thread.start()

    def process_check_result(self, server_index, result):
        """Process a health check result"""
        try:
            server = self.settings_manager.servers[server_index]

            # Update status
            old_status = self.server_status.get(server_index, {}).get(
                "status", "unknown"
            )
            new_status = (
                "operational"
                if result.is_healthy
                else (
                    "degraded"
                    if hasattr(result, "is_degraded") and result.is_degraded
                    else "down"
                )
            )

            # Track consecutive successes for optimization
            if result.is_healthy:
                server._consecutive_success = (
                    getattr(server, "_consecutive_success", 0) + 1
                )
            else:
                server._consecutive_success = 0

            # Check for status change
            if old_status != new_status and old_status != "checking":
                self.handle_status_change(server, old_status, new_status, result)

            # Update server status
            self.server_status[server_index] = {
                "status": new_status,
                "response_time": result.response_time,
                "message": result.message,
                "details": getattr(result, "details", {}),
            }

            # Record in status tracker
            self.status_tracker.record_status(
                server.name, new_status, result.response_time, result.message
            )

            # Update UI
            GLib.idle_add(self.update_server_display, server_index)

        except Exception as e:
            print(f"❌ Error processing result for server {server_index}: {e}")

    def start_server_monitoring(self, server_index, server):
        """Start monitoring thread for a specific server"""

        def monitor_server():
            while self.monitoring_active:
                try:
                    # Special handling for Docker services
                    if server.type == "docker_service":
                        result = self.check_docker_service(server)
                    else:
                        # Regular health check
                        timeout = getattr(
                            server, "timeout", 5
                        )  # Default timeout if not set
                        result = self.health_checker.check_server(server, timeout)

                    # Update status
                    old_status = self.server_status.get(server_index, {}).get(
                        "status", "unknown"
                    )
                    new_status = (
                        "operational"
                        if result.is_healthy
                        else (
                            "degraded"
                            if hasattr(result, "is_degraded") and result.is_degraded
                            else "down"
                        )
                    )

                    # Check for status change
                    if old_status != new_status and old_status != "checking":
                        self.handle_status_change(
                            server, old_status, new_status, result
                        )

                    # Update server status
                    self.server_status[server_index] = {
                        "status": new_status,
                        "response_time": result.response_time,
                        "message": result.message,
                        "details": result.details,
                    }

                    # Record in status tracker
                    self.status_tracker.record_status(
                        server.name, new_status, result.response_time, result.message
                    )

                    # Update UI
                    GLib.idle_add(self.update_server_display, server_index)

                except Exception as e:
                    print(f"❌ Error monitoring {server.name}: {e}")
                    self.server_status[server_index] = {
                        "status": "down",
                        "response_time": 0,
                        "message": f"Monitor error: {str(e)}",
                    }
                    GLib.idle_add(self.update_server_display, server_index)

                # Wait for next check
                time.sleep(server.check_interval)

        # Start monitoring thread
        thread = threading.Thread(target=monitor_server, daemon=True)
        thread.start()
        self.monitoring_threads[server_index] = thread

    def check_docker_service(self, server):
        """Check Docker service status with performance optimization"""
        try:
            import subprocess
            from core.health_checker import CheckResult

            start_time = time.time()

            if not hasattr(server, "containers") or not server.containers:
                return CheckResult(False, 0, "No containers found")

            # Optimized: Check all containers in a single command
            container_names = [c["name"] for c in server.containers]

            try:
                # Single docker command to check all containers at once
                result = subprocess.run(
                    ["docker", "ps", "--format", "{{.Names}}\t{{.Status}}"],
                    capture_output=True,
                    text=True,
                    timeout=3,  # Reduced timeout
                )

                running_containers = set()
                if result.returncode == 0 and result.stdout.strip():
                    for line in result.stdout.strip().split("\n"):
                        if "\t" in line:
                            name, status = line.split("\t", 1)
                            if "Up" in status and name in container_names:
                                running_containers.add(name)

                # Update container status
                running_count = 0
                for container in server.containers:
                    container_name = container["name"]
                    is_running = container_name in running_containers
                    container["is_running"] = is_running
                    if is_running:
                        running_count += 1

            except subprocess.TimeoutExpired:
                # If Docker is slow/unresponsive, mark all as unknown
                for container in server.containers:
                    container["is_running"] = False
                running_count = 0

            response_time = int((time.time() - start_time) * 1000)
            total_containers = len(server.containers)

            # Determine overall status
            if running_count == total_containers:
                is_healthy = True
                message = f"All {total_containers} containers running"
            elif running_count > 0:
                is_healthy = False
                message = f"{running_count}/{total_containers} containers running"
            else:
                is_healthy = False
                message = f"No containers running ({total_containers} total)"

            # Create result with degraded flag
            result = CheckResult(is_healthy, response_time, message)
            if running_count > 0 and running_count < total_containers:
                result.is_degraded = True

            return result

        except Exception as e:
            return CheckResult(False, 0, f"Docker check failed: {str(e)}")

    def start_global_updates(self):
        """Start global update thread with optimized frequency"""

        def global_updates():
            update_counter = 0
            while self.monitoring_active:
                try:
                    # Update summary and timestamp every cycle
                    GLib.idle_add(self.update_summary)
                    GLib.idle_add(self.update_timestamp)

                    # Update network status and system tray less frequently
                    if update_counter % 3 == 0:  # Every 15 seconds
                        GLib.idle_add(self.update_network_status)
                        GLib.idle_add(self.update_system_tray)

                    update_counter += 1

                except Exception as e:
                    print(f"Error in global updates: {e}")

                time.sleep(3)  # Update every 3 seconds for more responsive UI

        thread = threading.Thread(target=global_updates, daemon=True)
        thread.start()

    def handle_status_change(self, server, old_status, new_status, result):
        """Handle server status changes with advanced features"""

        # Check for flapping (rapid status changes)
        if self.is_service_flapping(server, new_status):
            print(f"🔄 Service {server.name} is flapping, suppressing alerts")
            return

        print(f"📊 Status change: {server.name} {old_status} → {new_status}")

        # Check if alert should be grouped or suppressed
        if not self.should_send_alert(server, old_status, new_status):
            print(f"🔇 Alert suppressed for {server.name} (grouped or acknowledged)")
        else:
            # Send notification with grouping
            self.send_grouped_notification(server, old_status, new_status, result)

        # Advanced handling for failures
        if new_status == "down" and old_status != "down":
            self.handle_service_failure(server, result)
        elif new_status == "operational" and old_status in ["down", "degraded"]:
            self.handle_service_recovery(server, result)

    def is_service_flapping(self, server, new_status):
        """Detect if a service is flapping (rapid status changes)"""
        server_name = server.name
        current_time = time.time()

        # Initialize flap tracking if needed
        if not hasattr(self, "status_change_history"):
            self.status_change_history = {}

        if server_name not in self.status_change_history:
            self.status_change_history[server_name] = []

        # Add current status change
        self.status_change_history[server_name].append(
            {"status": new_status, "timestamp": current_time}
        )

        # Keep only last 5 minutes of history
        self.status_change_history[server_name] = [
            change
            for change in self.status_change_history[server_name]
            if current_time - change["timestamp"] < 300  # 5 minutes
        ]

        # Check if there are too many changes in short time
        recent_changes = len(self.status_change_history[server_name])

        # If more than 4 status changes in 5 minutes, consider it flapping
        if recent_changes > 4:
            return True

        return False

    def handle_service_failure(self, server, result):
        """Handle service failure with intelligent retry and auto-restart"""
        server_name = server.name
        current_time = time.time()

        # Initialize tracking if needed
        if server_name not in self.retry_counts:
            self.retry_counts[server_name] = 0
            self.failure_timestamps[server_name] = []

        # Record failure timestamp
        self.failure_timestamps[server_name].append(current_time)

        # Clean old timestamps (keep last hour)
        self.failure_timestamps[server_name] = [
            ts
            for ts in self.failure_timestamps[server_name]
            if current_time - ts < 3600
        ]

        # Check if we should attempt auto-restart
        if self.should_attempt_restart(server):
            self.attempt_auto_restart(server)

        # Check for cascading failures
        self.check_cascade_failures(server)

    def should_attempt_restart(self, server):
        """Determine if we should attempt auto-restart"""
        if not self.auto_restart_enabled or self.maintenance_mode:
            return False

        server_name = server.name

        # Check if this is an external service that cannot be restarted
        if self.is_external_service(server):
            print(f"🌐 External service {server_name} cannot be restarted")
            return False

        # Don't restart if too many recent failures
        recent_failures = len(self.failure_timestamps.get(server_name, []))
        if recent_failures > 5:  # Max 5 failures per hour
            print(f"🚫 Too many failures for {server_name}, skipping restart")
            return False

        # Don't restart certain service types
        if server.type in ["external_api", "third_party"]:
            return False

        # Check retry count with exponential backoff
        retry_count = self.retry_counts.get(server_name, 0)
        if retry_count >= 3:  # Max 3 restart attempts
            print(f"🚫 Max restart attempts reached for {server_name}")
            return False

        return True

    def attempt_auto_restart(self, server):
        """Attempt to auto-restart a failed service"""
        server_name = server.name
        retry_count = self.retry_counts.get(server_name, 0)

        print(
            f"🔄 Attempting auto-restart for {server_name} (attempt {retry_count + 1})"
        )

        # Exponential backoff delay
        delay = min(30 * (2**retry_count), 300)  # Max 5 minutes

        def restart_after_delay():
            time.sleep(delay)
            success = self.execute_restart_command(server)

            if success:
                print(f"✅ Auto-restart successful for {server_name}")
                self.retry_counts[server_name] = 0  # Reset on success
                self.healing_actions[server_name] = {
                    "action": "auto_restart",
                    "timestamp": time.time(),
                    "success": True,
                }
            else:
                print(f"❌ Auto-restart failed for {server_name}")
                self.retry_counts[server_name] = retry_count + 1
                self.healing_actions[server_name] = {
                    "action": "auto_restart",
                    "timestamp": time.time(),
                    "success": False,
                }

        # Execute restart in background thread
        restart_thread = threading.Thread(target=restart_after_delay, daemon=True)
        restart_thread.start()

    def execute_restart_command(self, server):
        """Execute restart command for a service"""
        try:
            # Check if auto-restart is disabled for this server
            if hasattr(server, "auto_restart") and server.auto_restart == False:
                print(f"🚫 Auto-restart disabled for {server.name}")
                return False

            # Check if restart_command is explicitly set to null/None
            if hasattr(server, "restart_command") and server.restart_command is None:
                print(f"🚫 No restart command configured for {server.name}")
                return False

            if server.type == "docker_service":
                return self.restart_docker_service(server)
            elif hasattr(server, "restart_command") and server.restart_command:
                return self.execute_custom_restart(server)
            else:
                # Only try common patterns for local services, not external APIs
                if self.is_external_service(server):
                    print(f"🌐 External service {server.name} cannot be restarted")
                    return False
                return self.try_common_restart_patterns(server)
        except Exception as e:
            print(f"❌ Restart command failed for {server.name}: {e}")
            return False

    def is_external_service(self, server):
        """Check if this is an external service that cannot be restarted"""
        if hasattr(server, "host"):
            host = server.host
            # Check if it's an external URL or domain
            if host.startswith("http://") or host.startswith("https://"):
                return True
            # Check if it's not localhost or local IP
            if not (
                host.startswith("localhost")
                or host.startswith("127.0.0.1")
                or host.startswith("0.0.0.0")
            ):
                return True
        return False

    def restart_docker_service(self, server):
        """Restart Docker service"""
        try:
            import subprocess

            if hasattr(server, "containers"):
                for container in server.containers:
                    container_name = container["name"]
                    print(f"🐳 Restarting container: {container_name}")

                    result = subprocess.run(
                        ["docker", "restart", container_name],
                        capture_output=True,
                        text=True,
                        timeout=30,
                    )

                    if result.returncode != 0:
                        print(f"❌ Failed to restart {container_name}: {result.stderr}")
                        return False

                return True
        except Exception as e:
            print(f"❌ Docker restart failed: {e}")
            return False

    def execute_custom_restart(self, server):
        """Execute custom restart command"""
        try:
            import subprocess

            result = subprocess.run(
                server.restart_command.split(),
                capture_output=True,
                text=True,
                timeout=60,
            )

            return result.returncode == 0
        except Exception as e:
            print(f"❌ Custom restart failed: {e}")
            return False

    def try_common_restart_patterns(self, server):
        """Try common restart patterns based on service name/type"""
        try:
            import subprocess

            # Common systemd service restart
            service_name = server.name.lower().replace(" ", "-")

            patterns = [
                f"systemctl restart {service_name}",
                f"service {service_name} restart",
                f"sudo systemctl restart {service_name}",
            ]

            for pattern in patterns:
                try:
                    result = subprocess.run(
                        pattern.split(), capture_output=True, text=True, timeout=30
                    )

                    if result.returncode == 0:
                        print(f"✅ Restart successful with: {pattern}")
                        return True
                except:
                    continue

            return False
        except Exception as e:
            print(f"❌ Common restart patterns failed: {e}")
            return False

    def handle_service_recovery(self, server, result):
        """Handle service recovery"""
        server_name = server.name

        # Reset retry counts on recovery
        if server_name in self.retry_counts:
            self.retry_counts[server_name] = 0

        # Log recovery
        print(f"✅ Service recovered: {server_name}")

        # Record healing success
        if server_name in self.healing_actions:
            self.healing_actions[server_name]["recovery_time"] = time.time()

    def check_cascade_failures(self, failed_server):
        """Check for cascading failures and dependencies"""
        server_name = failed_server.name

        # Check if this failure might cause other services to fail
        dependent_services = self.service_dependencies.get(server_name, [])

        if dependent_services:
            print(
                f"⚠️ {server_name} failure may affect: {', '.join(dependent_services)}"
            )

            # Increase monitoring frequency for dependent services
            for dep_service in dependent_services:
                self.increase_monitoring_frequency(dep_service)

    def increase_monitoring_frequency(self, service_name):
        """Temporarily increase monitoring frequency for a service"""
        for i, server in enumerate(self.settings_manager.servers):
            if server.name == service_name:
                # Temporarily reduce check interval
                original_interval = server.check_interval
                server.check_interval = max(5, original_interval // 2)

                print(f"📈 Increased monitoring frequency for {service_name}")

                # Reset after 10 minutes
                def reset_frequency():
                    time.sleep(600)  # 10 minutes
                    server.check_interval = original_interval
                    print(f"📉 Reset monitoring frequency for {service_name}")

                reset_thread = threading.Thread(target=reset_frequency, daemon=True)
                reset_thread.start()
                break

    def toggle_maintenance_mode(self):
        """Toggle maintenance mode"""
        self.maintenance_mode = not self.maintenance_mode

        if self.maintenance_mode:
            print("🔧 Maintenance mode ENABLED - Auto-restart disabled")
            # Optionally pause notifications for maintenance
            self.notification_manager.maintenance_mode = True
        else:
            print("✅ Maintenance mode DISABLED - Auto-restart enabled")
            self.notification_manager.maintenance_mode = False

        return self.maintenance_mode

    def schedule_maintenance_window(self, start_time, duration_minutes):
        """Schedule a maintenance window"""

        def maintenance_scheduler():
            # Wait until start time
            current_time = time.time()
            if start_time > current_time:
                time.sleep(start_time - current_time)

            # Enable maintenance mode
            print(
                f"🔧 Scheduled maintenance window started ({duration_minutes} minutes)"
            )
            self.maintenance_mode = True

            # Wait for duration
            time.sleep(duration_minutes * 60)

            # Disable maintenance mode
            self.maintenance_mode = False
            print("✅ Scheduled maintenance window ended")

        scheduler_thread = threading.Thread(target=maintenance_scheduler, daemon=True)
        scheduler_thread.start()

    def discover_service_dependencies(self):
        """Auto-discover service dependencies based on failure patterns"""
        # This would analyze historical failure data to identify dependencies
        # For now, we'll set up some common patterns

        # Database dependencies
        db_services = [
            s.name
            for s in self.settings_manager.servers
            if "database" in s.name.lower() or "db" in s.name.lower()
        ]
        api_services = [
            s.name for s in self.settings_manager.servers if "api" in s.name.lower()
        ]

        # APIs typically depend on databases
        for db_service in db_services:
            self.service_dependencies[db_service] = api_services

        print(
            f"🔗 Discovered {len(self.service_dependencies)} dependency relationships"
        )

    def start_animation(self):
        """Start controlled animation timer"""
        if self.animation_timer_id is not None:
            GLib.source_remove(self.animation_timer_id)

        def animation_tick():
            if self.animation_enabled:
                self.animation_frame = (self.animation_frame + 1) % 120
                self.queue_draw()
                return True  # Continue animation
            return False  # Stop animation

        # Update every 100ms (10fps) instead of 16ms (60fps) to reduce CPU usage
        self.animation_timer_id = GLib.timeout_add(100, animation_tick)

    def stop_animation(self):
        """Stop animation timer"""
        if self.animation_timer_id is not None:
            GLib.source_remove(self.animation_timer_id)
            self.animation_timer_id = None

    def should_send_alert(self, server, old_status, new_status):
        """Determine if an alert should be sent (not grouped or acknowledged)"""
        server_name = server.name
        current_time = time.time()

        # Check if alert is acknowledged
        if server_name in self.acknowledged_alerts:
            ack_time = self.acknowledged_alerts[server_name]
            if current_time - ack_time < 3600:  # 1 hour acknowledgment window
                return False

        # Check for alert grouping
        alert_key = f"{server.group}_{new_status}"

        if alert_key in self.pending_alerts:
            # Add to existing group
            self.pending_alerts[alert_key]["services"].append(server_name)
            self.pending_alerts[alert_key]["last_update"] = current_time
            return False  # Don't send individual alert
        else:
            # Start new alert group
            self.pending_alerts[alert_key] = {
                "services": [server_name],
                "status": new_status,
                "group": server.group,
                "first_alert": current_time,
                "last_update": current_time,
            }

            # Schedule group alert after delay
            GLib.timeout_add_seconds(30, self.send_grouped_alert, alert_key)
            return False  # Wait for group

    def send_grouped_alert(self, alert_key):
        """Send grouped alert after delay"""
        if alert_key not in self.pending_alerts:
            return False

        alert_info = self.pending_alerts[alert_key]
        services = alert_info["services"]
        status = alert_info["status"]
        group = alert_info["group"]

        # Create grouped message
        if len(services) == 1:
            message = f"{services[0]} is {status}"
        else:
            message = f"{len(services)} services in {group} are {status}: {', '.join(services[:3])}"
            if len(services) > 3:
                message += f" and {len(services) - 3} more"

        # Send grouped notification
        if hasattr(self.notification_manager, "send_grouped_notification"):
            self.notification_manager.send_grouped_notification(
                f"{group} Alert", message, status, len(services)
            )
        else:
            # Fallback to regular notification
            self.notification_manager.notify_status_change(
                f"{group} Group", "operational", status, 0, message
            )

        # Store in alert groups for acknowledgment
        self.alert_groups[alert_key] = alert_info

        # Remove from pending
        del self.pending_alerts[alert_key]

        print(f"📢 Sent grouped alert: {message}")
        return False

    def send_grouped_notification(self, server, old_status, new_status, result):
        """Send notification with grouping support"""
        # For immediate critical alerts, bypass grouping
        if new_status == "down" and old_status == "operational":
            self.notification_manager.notify_status_change(
                server.name,
                old_status,
                new_status,
                result.response_time,
                result.message,
            )

    def acknowledge_alert(self, server_name_or_group):
        """Acknowledge an alert to suppress future notifications"""
        current_time = time.time()
        self.acknowledged_alerts[server_name_or_group] = current_time

        # Remove from pending alerts if exists
        for alert_key in list(self.pending_alerts.keys()):
            if server_name_or_group in self.pending_alerts[alert_key]["services"]:
                self.pending_alerts[alert_key]["services"].remove(server_name_or_group)
                if not self.pending_alerts[alert_key]["services"]:
                    del self.pending_alerts[alert_key]

        print(f"✅ Alert acknowledged for {server_name_or_group}")
        return True

    def show_alert_management(self):
        """Show alert management dialog"""
        dialog = Gtk.Dialog(
            title="Alert Management",
            parent=self,
            modal=True,
            destroy_with_parent=True,
        )
        dialog.set_default_size(600, 400)

        content = dialog.get_content_area()
        content.set_spacing(10)
        content.set_margin_start(20)
        content.set_margin_end(20)
        content.set_margin_top(20)
        content.set_margin_bottom(20)

        # Title
        title = Gtk.Label(label="Alert Management")
        title.get_style_context().add_class("dialog-section-title")
        content.pack_start(title, False, False, 0)

        # Notebook for tabs
        notebook = Gtk.Notebook()

        # Active alerts tab
        active_alerts_box = self.create_active_alerts_tab()
        notebook.append_page(active_alerts_box, Gtk.Label(label="Active Alerts"))

        # Acknowledged alerts tab
        ack_alerts_box = self.create_acknowledged_alerts_tab()
        notebook.append_page(ack_alerts_box, Gtk.Label(label="Acknowledged"))

        # Alert groups tab
        groups_box = self.create_alert_groups_tab()
        notebook.append_page(groups_box, Gtk.Label(label="Alert Groups"))

        content.pack_start(notebook, True, True, 0)

        # Buttons
        dialog.add_button("Close", Gtk.ResponseType.CLOSE)

        content.show_all()
        dialog.run()
        dialog.destroy()

    def create_active_alerts_tab(self):
        """Create active alerts tab"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)

        # List of current alerts
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        listbox = Gtk.ListBox()

        # Add current down services
        for i, server in enumerate(self.settings_manager.servers):
            if i in self.server_status and self.server_status[i]["status"] == "down":
                row = self.create_alert_row(server.name, "down", i)
                listbox.add(row)

        if listbox.get_children():
            scrolled.add(listbox)
        else:
            # No active alerts
            no_alerts_label = Gtk.Label(label="No active alerts")
            no_alerts_label.get_style_context().add_class("dim-label")
            box.pack_start(no_alerts_label, True, True, 0)
            return box

        scrolled.add(listbox)
        box.pack_start(scrolled, True, True, 0)

        return box

    def create_acknowledged_alerts_tab(self):
        """Create acknowledged alerts tab"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        listbox = Gtk.ListBox()

        current_time = time.time()
        for alert_name, ack_time in self.acknowledged_alerts.items():
            time_ago = int((current_time - ack_time) / 60)  # minutes
            row = self.create_ack_alert_row(alert_name, time_ago)
            listbox.add(row)

        if listbox.get_children():
            scrolled.add(listbox)
        else:
            # No acknowledged alerts
            no_ack_label = Gtk.Label(label="No acknowledged alerts")
            no_ack_label.get_style_context().add_class("dim-label")
            box.pack_start(no_ack_label, True, True, 0)
            return box

        scrolled.add(listbox)
        box.pack_start(scrolled, True, True, 0)

        return box

    def create_alert_groups_tab(self):
        """Create alert groups tab"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        listbox = Gtk.ListBox()

        for group_key, group_info in self.alert_groups.items():
            row = self.create_group_row(group_key, group_info)
            listbox.add(row)

        if listbox.get_children():
            scrolled.add(listbox)
        else:
            # No alert groups
            no_groups_label = Gtk.Label(label="No alert groups")
            no_groups_label.get_style_context().add_class("dim-label")
            box.pack_start(no_groups_label, True, True, 0)
            return box

        scrolled.add(listbox)
        box.pack_start(scrolled, True, True, 0)

        return box

    def create_alert_row(self, service_name, status, server_index):
        """Create alert row with acknowledge button"""
        row = Gtk.ListBoxRow()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_margin_start(10)
        box.set_margin_end(10)
        box.set_margin_top(5)
        box.set_margin_bottom(5)

        # Status icon
        status_icon = "🔴" if status == "down" else "🟡"
        icon_label = Gtk.Label(label=status_icon)
        box.pack_start(icon_label, False, False, 0)

        # Service name
        name_label = Gtk.Label(label=service_name)
        name_label.set_halign(Gtk.Align.START)
        box.pack_start(name_label, True, True, 0)

        # Acknowledge button
        ack_button = Gtk.Button(label="Acknowledge")
        ack_button.connect("clicked", lambda btn: self.acknowledge_alert(service_name))
        box.pack_start(ack_button, False, False, 0)

        row.add(box)
        return row

    def create_ack_alert_row(self, alert_name, minutes_ago):
        """Create acknowledged alert row"""
        row = Gtk.ListBoxRow()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_margin_start(10)
        box.set_margin_end(10)
        box.set_margin_top(5)
        box.set_margin_bottom(5)

        # Ack icon
        icon_label = Gtk.Label(label="✅")
        box.pack_start(icon_label, False, False, 0)

        # Alert name
        name_label = Gtk.Label(label=alert_name)
        name_label.set_halign(Gtk.Align.START)
        box.pack_start(name_label, True, True, 0)

        # Time ago
        time_label = Gtk.Label(label=f"{minutes_ago}m ago")
        box.pack_start(time_label, False, False, 0)

        row.add(box)
        return row

    def create_group_row(self, group_key, group_info):
        """Create alert group row"""
        row = Gtk.ListBoxRow()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_margin_start(10)
        box.set_margin_end(10)
        box.set_margin_top(5)
        box.set_margin_bottom(5)

        # Group icon
        icon_label = Gtk.Label(label="📊")
        box.pack_start(icon_label, False, False, 0)

        # Group info
        services_count = len(group_info["services"])
        group_text = (
            f"{group_info['group']} - {services_count} services {group_info['status']}"
        )
        name_label = Gtk.Label(label=group_text)
        name_label.set_halign(Gtk.Align.START)
        box.pack_start(name_label, True, True, 0)

        row.add(box)
        return row

    def update_server_display(self, index):
        """Update server display"""
        if index not in self.service_widgets or index not in self.server_status:

            return False

        status_info = self.server_status[index]
        widgets = self.service_widgets[index]

        status = status_info["status"]
        response_time = status_info["response_time"]
        message = status_info.get("message", "")

        # Update response label
        widgets["response_label"].set_text(
            message or f"{response_time}ms response time"
        )

        # Update status
        status_context = widgets["status_text"].get_style_context()
        dot_context = widgets["status_dot"].get_style_context()

        # Remove old classes
        for cls in [
            "status-operational",
            "status-degraded",
            "status-down",
            "status-checking",
        ]:
            status_context.remove_class(cls)
            dot_context.remove_class(cls)

        # Add new classes and text
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
        """Update overall status summary"""
        operational = sum(
            1
            for status in self.server_status.values()
            if status["status"] == "operational"
        )
        total = len(self.settings_manager.servers)
        self.status_summary.set_text(f"{operational} / {total} Operational")
        return False

    def update_timestamp(self):
        """Update timestamp"""
        current_time = time.strftime("%H:%M:%S")
        self.last_updated.set_text(f"Last updated: {current_time}")
        return False

    def update_network_status(self):
        """Update network status"""
        has_internet = self.health_checker.check_internet_connectivity()
        if has_internet:
            self.network_status.set_text("🌐 Connected")
            self.network_status.get_style_context().remove_class("network-disconnected")
            self.network_status.get_style_context().add_class("network-connected")
        else:
            self.network_status.set_text("🚫 No Internet")
            self.network_status.get_style_context().remove_class("network-connected")
            self.network_status.get_style_context().add_class("network-disconnected")
        return False

    def update_system_tray(self):
        """Update system tray status"""
        operational = sum(
            1
            for status in self.server_status.values()
            if status["status"] == "operational"
        )
        total = len(self.settings_manager.servers)

        if hasattr(self, "system_tray"):
            self.system_tray.update_tray_status(
                (
                    "operational"
                    if operational == total
                    else "down" if operational == 0 else "degraded"
                ),
                operational,
                total,
            )
        return False

    def connect_signals(self):
        """Connect window signals"""
        self.connect("button-press-event", self.on_button_press)
        self.connect("button-release-event", self.on_button_release)
        self.connect("motion-notify-event", self.on_motion)
        self.connect("draw", self.on_draw)
        self.connect("destroy", self.on_destroy)
        self.connect("key-press-event", self.on_key_press)

        # Enable keyboard focus
        self.set_can_focus(True)
        self.set_focus_on_map(True)

    # Event handlers
    def on_refresh(self, button):
        """Refresh all servers"""
        button.set_label("🔄")
        print("🔄 Manual refresh triggered")

        # Reset all statuses to checking
        for i in range(len(self.settings_manager.servers)):
            self.server_status[i] = {
                "status": "checking",
                "response_time": 0,
                "message": "Refreshing...",
            }
            GLib.idle_add(self.update_server_display, i)

        # Reset button after delay
        GLib.timeout_add_seconds(2, lambda: button.set_label("⟳"))

    def on_settings(self, button):
        """Show settings dialog"""
        print("⚙️ Opening settings dialog")

        try:
            from core.settings_dialog import SettingsDialog

            dialog = SettingsDialog(self, self.settings_manager)
            dialog.show_all()

            response = dialog.run()

            if response in [Gtk.ResponseType.OK, Gtk.ResponseType.APPLY]:
                # Save settings
                dialog.save_settings()
                print("✅ Settings saved")

                # Apply changes that require UI updates
                self.apply_settings_changes()

                if response == Gtk.ResponseType.OK:
                    dialog.destroy()
            else:
                dialog.destroy()

        except ImportError as e:
            print(f"❌ Settings dialog not available: {e}")
            self.show_info_dialog(
                "Settings",
                "Settings dialog is not available. Please check the installation.",
            )

    def on_theme_toggle(self, button):
        """Toggle theme"""
        self.is_light_theme = not self.is_light_theme

        # Update settings
        self.settings_manager.ui_settings.theme = (
            ThemeType.LIGHT if self.is_light_theme else ThemeType.DARK
        )
        self.settings_manager.save_settings()

        # Update button
        if self.is_light_theme:
            button.set_label("☀️")
            button.set_tooltip_text("Switch to Dark Theme")
            self.main_box.get_style_context().add_class("light-theme")
        else:
            button.set_label("🌙")
            button.set_tooltip_text("Switch to Light Theme")
            self.main_box.get_style_context().remove_class("light-theme")

        # Apply theme changes without rebuilding UI (preserves monitoring state)
        self.apply_theme_changes()
        self.queue_draw()

    def on_maintenance_toggle(self, button):
        """Toggle maintenance mode"""
        is_maintenance = self.toggle_maintenance_mode()

        if is_maintenance:
            button.set_label("🔧")
            button.set_tooltip_text("Disable Maintenance Mode")
            button.get_style_context().add_class("maintenance-active")
        else:
            button.set_label("🔧")
            button.set_tooltip_text("Enable Maintenance Mode")
            button.get_style_context().remove_class("maintenance-active")

    def on_minimize(self, button):
        """Minimize window with smart behavior"""
        if self.settings_manager.ui_settings.minimize_to_tray and hasattr(
            self, "system_tray"
        ):
            # Only hide to tray if system tray is available
            if self.system_tray and self.system_tray.is_available():
                self.hide()
                print("🔽 Minimized to system tray (click tray icon to restore)")
            else:
                # Fallback to normal minimize if no system tray
                self.iconify()
                print("🔽 Minimized to taskbar (system tray not available)")
        else:
            # Normal minimize to taskbar
            self.iconify()
            print("🔽 Minimized to taskbar")

    def on_close(self, button):
        """Close application"""
        self.on_destroy()

    def on_destroy(self, widget=None):
        """Cleanup and exit"""
        print("🛑 Shutting down enhanced monitor...")

        # Stop monitoring
        self.monitoring_active = False

        # Stop animation
        self.stop_animation()

        # Cleanup performance optimizer
        if hasattr(self, "performance_optimizer"):
            self.performance_optimizer.shutdown()

        # Save final status
        self.status_tracker.save_history()

        # Cleanup system tray
        if hasattr(self, "system_tray"):
            self.system_tray.cleanup()

        Gtk.main_quit()

    def on_draw(self, widget, cr):
        """Draw window background with optional subtle animation"""
        width = widget.get_allocated_width()
        height = widget.get_allocated_height()
        radius = 12

        if self.animation_enabled:
            # Simple animated background with health-based colors
            progress = self.animation_frame / 120.0

            # Determine base color based on system health
            operational_count = sum(
                1
                for status in self.server_status.values()
                if status.get("status") == "operational"
            )
            total_count = len(self.server_status) or 1
            health_ratio = operational_count / total_count

            if health_ratio >= 0.9:
                base_color = (19 / 255, 22 / 255, 20 / 255, 0.95)  # Green tint
            elif health_ratio >= 0.7:
                base_color = (19 / 255, 18 / 255, 17 / 255, 0.95)  # Neutral
            else:
                base_color = (22 / 255, 19 / 255, 17 / 255, 0.95)  # Red tint

            # Very subtle animation wave
            import math

            wave = 0.01 * math.sin(progress * 2 * math.pi)
            animated_color = (
                min(1.0, max(0.0, base_color[0] + wave)),
                min(1.0, max(0.0, base_color[1] + wave)),
                min(1.0, max(0.0, base_color[2] + wave)),
                base_color[3],
            )

            if self.is_light_theme:
                light_base = (245 / 255, 245 / 255, 245 / 255, 0.97)
                animated_color = (
                    max(0.8, light_base[0] - wave * 0.05),
                    max(0.8, light_base[1] - wave * 0.05),
                    max(0.8, light_base[2] - wave * 0.05),
                    light_base[3],
                )

            cr.set_source_rgba(*animated_color)
        else:
            # Static background
            if self.is_light_theme:
                cr.set_source_rgba(245 / 255, 245 / 255, 245 / 255, 0.97)
            else:
                cr.set_source_rgba(19 / 255, 18 / 255, 17 / 255, 0.95)

        # Rounded rectangle
        cr.arc(radius, radius, radius, 3.14, 3.14 * 1.5)
        cr.arc(width - radius, radius, radius, 3.14 * 1.5, 0)
        cr.arc(width - radius, height - radius, radius, 0, 3.14 * 0.5)
        cr.arc(radius, height - radius, radius, 3.14 * 0.5, 3.14)
        cr.close_path()
        cr.fill()

        return False

    # Dragging support
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

    def on_focus_out(self, widget, event):
        """Handle focus out event for auto-hide"""
        if self.auto_hide_enabled and not self.is_dragging:
            # Small delay to prevent accidental hiding
            GLib.timeout_add(200, self.check_and_hide)
        return False

    def check_and_hide(self):
        """Check if we should hide the window"""
        if self.auto_hide_enabled and not self.has_focus():
            self.hide()
        return False

    def on_key_press(self, widget, event):
        """Handle keyboard shortcuts"""
        # Get modifier state
        ctrl = event.state & Gdk.ModifierType.CONTROL_MASK

        if ctrl:
            key = Gdk.keyval_name(event.keyval).lower()

            if key == "r":  # Ctrl+R - Refresh
                self.on_refresh(self.refresh_btn)
                return True
            elif key == "s":  # Ctrl+S - Settings
                self.on_settings(self.settings_btn)
                return True
            elif key == "t":  # Ctrl+T - Toggle theme
                self.on_theme_toggle(self.theme_btn)
                return True
            elif key == "h":  # Ctrl+H - Hide/Show
                if self.get_visible():
                    self.hide()
                    print("🔽 Window hidden (Ctrl+H to restore)")
                else:
                    self.show_all()
                    self.present()  # Bring to front
                    print("🔼 Window restored")
                return True
            elif key == "m":  # Ctrl+M - Minimize
                self.on_minimize(self.minimize_btn)
                return True
            elif key == "q":  # Ctrl+Q - Quit
                self.on_destroy()
                return True
            elif key == "c":  # Ctrl+C - Toggle compact mode
                self.toggle_compact_mode()
                return True
            elif key == "plus" or key == "equal":  # Ctrl++ - Increase opacity
                self.adjust_opacity(0.05)
                return True
            elif key == "minus":  # Ctrl+- - Decrease opacity
                self.adjust_opacity(-0.05)
                return True
            elif key == "x":  # Ctrl+X - Toggle maintenance mode
                self.on_maintenance_toggle(self.maintenance_btn)
                return True
            elif key == "d":  # Ctrl+D - Discover dependencies
                self.discover_service_dependencies()
                return True
            elif key == "a":  # Ctrl+A - Alert management
                self.show_alert_management()
                return True

        return False

    def toggle_compact_mode(self):
        """Toggle compact mode"""
        ui_settings = self.settings_manager.ui_settings
        ui_settings.compact_mode = not ui_settings.compact_mode
        self.settings_manager.save_settings()

        # Apply compact mode changes
        self.apply_compact_mode()
        print(
            f"🔄 Compact mode: {'enabled' if ui_settings.compact_mode else 'disabled'}"
        )

    def apply_compact_mode(self):
        """Apply compact mode styling"""
        if self.settings_manager.ui_settings.compact_mode:
            # Reduce margins and spacing
            self.main_box.set_margin_top(10)
            self.main_box.set_margin_bottom(10)
            self.main_box.set_margin_start(10)
            self.main_box.set_margin_end(10)
            self.services_container.set_spacing(10)
        else:
            # Restore normal margins and spacing
            self.main_box.set_margin_top(20)
            self.main_box.set_margin_bottom(20)
            self.main_box.set_margin_start(20)
            self.main_box.set_margin_end(20)
            self.services_container.set_spacing(20)

    def adjust_opacity(self, delta):
        """Adjust window opacity"""
        ui_settings = self.settings_manager.ui_settings
        new_opacity = max(0.3, min(1.0, ui_settings.opacity + delta))

        if new_opacity != ui_settings.opacity:
            ui_settings.opacity = new_opacity
            self.set_window_opacity(new_opacity)
            self.settings_manager.save_settings()
            print(f"🎨 Opacity: {int(new_opacity * 100)}%")

    def apply_settings_changes(self):
        """Apply settings changes that require UI updates"""
        ui_settings = self.settings_manager.ui_settings

        # Update theme
        new_theme = ui_settings.theme == ThemeType.LIGHT
        if new_theme != self.is_light_theme:
            self.is_light_theme = new_theme

            # Update theme button
            theme_icon = "☀️" if self.is_light_theme else "🌙"
            self.theme_btn.set_label(theme_icon)

            # Apply theme class
            if self.is_light_theme:
                self.main_box.get_style_context().add_class("light-theme")
            else:
                self.main_box.get_style_context().remove_class("light-theme")

            # Apply theme changes without rebuilding UI
            self.apply_theme_changes()
            self.queue_draw()

        # Update window behavior
        self.set_keep_above(ui_settings.always_on_top)

        # Update notification manager settings
        self.notification_manager.settings = self.settings_manager.notification_settings

        # Only rebuild services if servers actually changed (check if needed)
        # For now, we'll skip this to preserve monitoring state
        # self.rebuild_services_ui()

        print("✅ Settings changes applied")

    def on_service_click(self, widget, event, server_index):
        """Handle service click for details popup"""
        if event.button == 1 and event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS:
            # Double-click shows detailed popup
            self.show_service_details(server_index)
            return True
        return False

    def show_service_details(self, server_index):
        """Show detailed service information popup"""
        if server_index not in self.server_status:
            return

        server = self.settings_manager.servers[server_index]
        status_info = self.server_status[server_index]

        # Create popup dialog
        dialog = Gtk.Dialog(
            title=f"Service Details - {server.name}",
            parent=self,
            modal=True,
            destroy_with_parent=True,
        )
        dialog.set_default_size(500, 400)

        # Content area
        content = dialog.get_content_area()
        content.set_spacing(10)
        content.set_margin_start(20)
        content.set_margin_end(20)
        content.set_margin_top(20)
        content.set_margin_bottom(20)

        # Service info
        info_grid = Gtk.Grid()
        info_grid.set_row_spacing(8)
        info_grid.set_column_spacing(15)

        # Add service details
        details = [
            ("Name:", server.name),
            ("Host:", server.host),
            ("Type:", server.type),
            (
                "Check Type:",
                (
                    server.check_type.value
                    if hasattr(server.check_type, "value")
                    else str(server.check_type)
                ),
            ),
            ("Status:", status_info.get("status", "Unknown")),
            ("Response Time:", f"{status_info.get('response_time', 0)}ms"),
            ("Message:", status_info.get("message", "No message")),
            ("Check Interval:", f"{server.check_interval}s"),
            ("Timeout:", f"{server.timeout}s"),
            ("Group:", server.group),
        ]

        for i, (label, value) in enumerate(details):
            label_widget = Gtk.Label(label=label)
            label_widget.set_halign(Gtk.Align.START)
            label_widget.get_style_context().add_class("dialog-label")

            value_widget = Gtk.Label(label=str(value))
            value_widget.set_halign(Gtk.Align.START)
            value_widget.set_selectable(True)

            info_grid.attach(label_widget, 0, i, 1, 1)
            info_grid.attach(value_widget, 1, i, 1, 1)

        content.pack_start(info_grid, False, False, 0)

        # Response time history (if available)
        history = self.status_tracker.get_recent_response_times(server.name, limit=20)
        if history:
            history_label = Gtk.Label(label="Recent Response Times:")
            history_label.set_halign(Gtk.Align.START)
            history_label.get_style_context().add_class("dialog-section-title")
            content.pack_start(history_label, False, False, 10)

            # Create simple text-based sparkline
            sparkline = self.create_text_sparkline(history)
            sparkline_label = Gtk.Label(label=sparkline)
            sparkline_label.set_halign(Gtk.Align.START)
            sparkline_label.get_style_context().add_class("sparkline")
            content.pack_start(sparkline_label, False, False, 0)

        # Additional details if available
        if "details" in status_info and status_info["details"]:
            details_label = Gtk.Label(label="Additional Details:")
            details_label.set_halign(Gtk.Align.START)
            details_label.get_style_context().add_class("dialog-section-title")
            content.pack_start(details_label, False, False, 10)

            details_text = json.dumps(status_info["details"], indent=2)
            details_view = Gtk.TextView()
            details_view.get_buffer().set_text(details_text)
            details_view.set_editable(False)
            details_view.set_size_request(-1, 150)

            scrolled = Gtk.ScrolledWindow()
            scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
            scrolled.add(details_view)
            content.pack_start(scrolled, True, True, 0)

        # Buttons
        dialog.add_button("Close", Gtk.ResponseType.CLOSE)

        # Show dialog
        content.show_all()
        dialog.run()
        dialog.destroy()

    def create_text_sparkline(self, values):
        """Create a simple text-based sparkline"""
        if not values:
            return "No data"

        # Normalize values to 0-7 range for block characters
        min_val = min(values)
        max_val = max(values)

        if max_val == min_val:
            return "▄" * len(values)  # All same value

        # Unicode block characters for sparkline
        blocks = [" ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

        sparkline = ""
        for val in values:
            # Normalize to 0-8 range
            normalized = int(((val - min_val) / (max_val - min_val)) * 8)
            sparkline += blocks[normalized]

        return f"{sparkline} ({min_val}-{max_val}ms)"

    def show_keyboard_shortcuts(self, button):
        """Show keyboard shortcuts help dialog"""
        dialog = Gtk.Dialog(
            title="Keyboard Shortcuts",
            parent=self,
            modal=True,
            destroy_with_parent=True,
        )
        dialog.set_default_size(400, 350)

        content = dialog.get_content_area()
        content.set_spacing(10)
        content.set_margin_start(20)
        content.set_margin_end(20)
        content.set_margin_top(20)
        content.set_margin_bottom(20)

        # Title
        title = Gtk.Label(label="Keyboard Shortcuts")
        title.get_style_context().add_class("dialog-section-title")
        content.pack_start(title, False, False, 0)

        # Shortcuts grid
        shortcuts_grid = Gtk.Grid()
        shortcuts_grid.set_row_spacing(8)
        shortcuts_grid.set_column_spacing(20)

        shortcuts = [
            ("Ctrl+R", "Refresh all servers"),
            ("Ctrl+S", "Open settings"),
            ("Ctrl+T", "Toggle theme"),
            ("Ctrl+H", "Hide/Show window"),
            ("Ctrl+M", "Minimize to tray"),
            ("Ctrl+C", "Toggle compact mode"),
            ("Ctrl+X", "Toggle maintenance mode"),
            ("Ctrl+A", "Alert management"),
            ("Ctrl+D", "Discover dependencies"),
            ("Ctrl++", "Increase opacity"),
            ("Ctrl+-", "Decrease opacity"),
            ("Ctrl+Q", "Quit application"),
            ("Double-click", "Show service details"),
        ]

        for i, (shortcut, description) in enumerate(shortcuts):
            shortcut_label = Gtk.Label(label=shortcut)
            shortcut_label.set_halign(Gtk.Align.START)
            shortcut_label.get_style_context().add_class("dialog-label")

            desc_label = Gtk.Label(label=description)
            desc_label.set_halign(Gtk.Align.START)

            shortcuts_grid.attach(shortcut_label, 0, i, 1, 1)
            shortcuts_grid.attach(desc_label, 1, i, 1, 1)

        content.pack_start(shortcuts_grid, True, True, 0)

        # Close button
        dialog.add_button("Close", Gtk.ResponseType.CLOSE)

        content.show_all()
        dialog.run()
        dialog.destroy()

    def apply_theme_changes(self):
        """Apply theme changes to existing UI elements without rebuilding"""
        # Update container colors for Docker services
        for index, widgets in self.service_widgets.items():
            if "containers_box" in widgets and widgets["containers_box"]:
                # Update container text colors based on theme
                self.update_container_colors(widgets["containers_box"])

        # Force a redraw of all widgets to apply new theme
        self.services_container.queue_draw()

    def update_container_colors(self, containers_box):
        """Update container text colors for theme changes"""
        for container_row in containers_box.get_children():
            for child in container_row.get_children():
                if isinstance(child, Gtk.Label):
                    # Get current text and reapply with new theme colors
                    current_text = child.get_text()
                    if current_text and current_text not in ["●", "Running", "Stopped"]:
                        # This is a container name label - update color
                        container_color = (
                            "#1f2937" if self.is_light_theme else "#e2e8f0"
                        )
                        child.set_markup(
                            f'<span size="small" color="{container_color}">{current_text}</span>'
                        )

    def show_info_dialog(self, title, message):
        """Show information dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.destroy()


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Enhanced Server Status Monitor Widget"
    )
    parser.add_argument("--check", action="store_true", help="Check dependencies")
    parser.add_argument(
        "--test-notifications", action="store_true", help="Test notification system"
    )

    args = parser.parse_args()

    if args.check:
        print("Checking enhanced dependencies...")
        print("✅ GTK3 is available")

        # Check components
        try:
            from core.settings import SettingsManager

            print("✅ Settings manager available")
        except ImportError as e:
            print(f"❌ Settings manager: {e}")

        try:
            from core.health_checker import HealthChecker

            print("✅ Health checker available")
        except ImportError as e:
            print(f"❌ Health checker: {e}")

        try:
            from core.notifications import NotificationManager

            print("✅ Notification manager available")
        except ImportError as e:
            print(f"❌ Notification manager: {e}")

        return

    if args.test_notifications:
        print("Testing notification system...")
        from core.settings import NotificationSettings
        from core.notifications import NotificationManager

        settings = NotificationSettings(desktop_notifications=True)
        notifier = NotificationManager(settings)
        notifier.test_notifications()
        return

    try:
        widget = SatoMonitoringSystem()
        widget.show_all()

        print("🛰️ Sato Enhanced Monitoring System started!")
        print("• Drag to move around your desktop")
        print("• Click minimize to hide to system tray")
        print("• Advanced monitoring with self-healing capabilities")
        print("• Press Ctrl+C or click X to close")

        Gtk.main()

    except KeyboardInterrupt:
        print("\n🛑 Widget closed by user.")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    main()
