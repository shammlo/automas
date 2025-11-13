#!/usr/bin/env python3
"""
Enhanced Server Status Monitor Widget
A comprehensive desktop widget with advanced monitoring capabilities
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
from settings import SettingsManager, ServerConfig, CheckType, ThemeType
from health_checker import HealthChecker
from status_tracker import StatusTracker
from notifications import NotificationManager
from system_tray import SystemTrayManager


class EnhancedServerMonitorWidget(Gtk.Window):
    def __init__(self):
        super().__init__()

        # Initialize core components
        self.config_dir = Path(__file__).parent
        self.settings_manager = SettingsManager(self.config_dir)
        self.health_checker = HealthChecker()
        self.status_tracker = StatusTracker(
            self.config_dir / "history.json",
            self.settings_manager.monitoring_settings.history_retention_days,
        )
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

        # Setup window
        self.setup_window()

        # Create UI
        self.create_ui()

        # Setup system tray
        self.system_tray = SystemTrayManager(self, self.settings_manager)

        # Connect signals
        self.connect_signals()

        # Start monitoring
        self.start_enhanced_monitoring()

        print("🚀 Enhanced Server Monitor initialized!")
        print(f"📊 Monitoring {len(self.settings_manager.servers)} servers")
        print(f"🎨 Theme: {self.settings_manager.ui_settings.theme.value}")
        print(
            f"🔔 Notifications: {'enabled' if self.settings_manager.notification_settings.desktop_notifications else 'disabled'}"
        )

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

        # Transparency
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
            self.set_app_paintable(True)

        # Dragging support
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.is_dragging = False

    def load_css(self):
        """Load CSS styling from external file"""
        css_file = self.config_dir / "widget-gtk.css"

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
        self.refresh_btn = Gtk.Button(label="⟳")
        self.refresh_btn.set_tooltip_text("Refresh All")
        self.refresh_btn.set_size_request(30, 30)
        self.refresh_btn.connect("clicked", self.on_refresh)

        # Settings button
        self.settings_btn = Gtk.Button(label="⚙️")
        self.settings_btn.set_tooltip_text("Settings")
        self.settings_btn.set_size_request(30, 30)
        self.settings_btn.connect("clicked", self.on_settings)

        # Theme toggle button
        theme_icon = "☀️" if self.is_light_theme else "🌙"
        self.theme_btn = Gtk.Button(label=theme_icon)
        self.theme_btn.set_tooltip_text("Toggle Theme")
        self.theme_btn.set_size_request(30, 30)
        self.theme_btn.connect("clicked", self.on_theme_toggle)

        # Minimize button
        self.minimize_btn = Gtk.Button(label="−")
        self.minimize_btn.set_tooltip_text("Minimize to Tray")
        self.minimize_btn.set_size_request(30, 30)
        self.minimize_btn.get_style_context().add_class("minimize-button")
        self.minimize_btn.connect("clicked", self.on_minimize)

        # Close button
        close_btn = Gtk.Button(label="✕")
        close_btn.set_tooltip_text("Close")
        close_btn.set_size_request(30, 30)
        close_btn.get_style_context().add_class("close-button")
        close_btn.connect("clicked", self.on_close)

        button_box.pack_start(self.refresh_btn, False, False, 0)
        button_box.pack_start(self.settings_btn, False, False, 0)
        button_box.pack_start(self.theme_btn, False, False, 0)
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
        # Clear existing services
        for child in self.services_container.get_children():
            self.services_container.remove(child)

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

        # Initialize server status tracking
        self.server_status = {}
        self.service_widgets = {}
        for i, server in enumerate(self.settings_manager.servers):
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

        # Store widget references
        self.service_widgets[index] = {
            "event_box": event_box,
            "status_text": status_text,
            "status_dot": status_dot,
            "response_label": response_label,
            "containers_box": containers_box,
            "server": server,
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

    def start_enhanced_monitoring(self):
        """Start enhanced monitoring with individual intervals"""
        print("🔄 Starting enhanced monitoring...")

        # Start individual monitoring threads for each server
        for i, server in enumerate(self.settings_manager.servers):
            if server.enabled:
                self.start_server_monitoring(i, server)

        # Start global update thread
        self.start_global_updates()

    def start_server_monitoring(self, server_index, server):
        """Start monitoring thread for a specific server"""

        def monitor_server():
            while self.monitoring_active:
                try:
                    # Perform health check
                    result = self.health_checker.check_server(server, server.timeout)

                    # Update status
                    old_status = self.server_status.get(server_index, {}).get(
                        "status", "unknown"
                    )
                    new_status = "operational" if result.is_healthy else "down"

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
                    print(f"Error monitoring {server.name}: {e}")
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

    def start_global_updates(self):
        """Start global update thread"""

        def global_updates():
            while self.monitoring_active:
                try:
                    # Update summary and UI elements
                    GLib.idle_add(self.update_summary)
                    GLib.idle_add(self.update_timestamp)
                    GLib.idle_add(self.update_network_status)
                    GLib.idle_add(self.update_system_tray)

                except Exception as e:
                    print(f"Error in global updates: {e}")

                time.sleep(5)  # Update every 5 seconds

        thread = threading.Thread(target=global_updates, daemon=True)
        thread.start()

    def handle_status_change(self, server, old_status, new_status, result):
        """Handle server status changes"""
        print(f"📊 Status change: {server.name} {old_status} → {new_status}")

        # Send notification
        self.notification_manager.notify_status_change(
            server.name, old_status, new_status, result.response_time, result.message
        )

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
        print("⚙️ Settings dialog requested")
        # TODO: Implement settings dialog
        self.show_info_dialog("Settings", "Settings dialog coming soon!")

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

    def on_minimize(self, button):
        """Minimize to system tray"""
        if self.settings_manager.ui_settings.minimize_to_tray:
            self.hide()
        else:
            self.iconify()

    def on_close(self, button):
        """Close application"""
        self.on_destroy()

    def on_destroy(self, widget=None):
        """Cleanup and exit"""
        print("🛑 Shutting down enhanced monitor...")

        # Stop monitoring
        self.monitoring_active = False

        # Save final status
        self.status_tracker.save_history()

        # Cleanup system tray
        if hasattr(self, "system_tray"):
            self.system_tray.cleanup()

        Gtk.main_quit()

    def on_draw(self, widget, cr):
        """Draw window background"""
        if self.is_light_theme:
            cr.set_source_rgba(245 / 255, 245 / 255, 245 / 255, 0.97)
        else:
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
            from settings import SettingsManager

            print("✅ Settings manager available")
        except ImportError as e:
            print(f"❌ Settings manager: {e}")

        try:
            from health_checker import HealthChecker

            print("✅ Health checker available")
        except ImportError as e:
            print(f"❌ Health checker: {e}")

        try:
            from notifications import NotificationManager

            print("✅ Notification manager available")
        except ImportError as e:
            print(f"❌ Notification manager: {e}")

        return

    if args.test_notifications:
        print("Testing notification system...")
        from settings import NotificationSettings
        from notifications import NotificationManager

        settings = NotificationSettings(desktop_notifications=True)
        notifier = NotificationManager(settings)
        notifier.test_notifications()
        return

    try:
        widget = EnhancedServerMonitorWidget()
        widget.show_all()

        print("🎉 Enhanced Server Status Widget started!")
        print("• Drag to move around your desktop")
        print("• Click minimize to hide to system tray")
        print("• Enhanced monitoring with notifications")
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
