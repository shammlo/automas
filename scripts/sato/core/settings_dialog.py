#!/usr/bin/env python3
"""
Settings Dialog for Enhanced Server Monitor
"""

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

from .settings import SettingsManager, ServerConfig, CheckType, ThemeType


class SettingsDialog(Gtk.Dialog):
    def __init__(self, parent, settings_manager):
        super().__init__(title="Server Monitor Settings", transient_for=parent)

        self.settings_manager = settings_manager
        self.parent_window = parent

        # Dialog setup
        self.set_default_size(600, 500)
        self.set_resizable(True)

        # Add buttons
        self.add_button("Cancel", Gtk.ResponseType.CANCEL)
        self.add_button("Apply", Gtk.ResponseType.APPLY)
        self.add_button("OK", Gtk.ResponseType.OK)

        # Create content
        self.create_content()

        # Load current settings
        self.load_settings()

    def create_content(self):
        """Create the settings dialog content"""
        content_area = self.get_content_area()
        content_area.set_spacing(10)
        content_area.set_margin_start(20)
        content_area.set_margin_end(20)
        content_area.set_margin_top(10)
        content_area.set_margin_bottom(10)

        # Create notebook for tabs
        self.notebook = Gtk.Notebook()
        content_area.pack_start(self.notebook, True, True, 0)

        # Create tabs
        self.create_general_tab()
        self.create_monitoring_tab()
        self.create_notifications_tab()
        self.create_servers_tab()

    def create_general_tab(self):
        """Create general settings tab"""
        # Main container
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        vbox.set_margin_start(20)
        vbox.set_margin_end(20)
        vbox.set_margin_top(20)
        vbox.set_margin_bottom(20)

        # Theme settings
        theme_frame = Gtk.Frame(label="Appearance")
        theme_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        theme_box.set_margin_start(15)
        theme_box.set_margin_end(15)
        theme_box.set_margin_top(10)
        theme_box.set_margin_bottom(15)

        # Theme selection
        theme_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        theme_label = Gtk.Label(label="Theme:")
        theme_label.set_halign(Gtk.Align.START)

        self.theme_combo = Gtk.ComboBoxText()
        self.theme_combo.append("dark", "Dark")
        self.theme_combo.append("light", "Light")
        self.theme_combo.append("auto", "Auto")

        theme_hbox.pack_start(theme_label, False, False, 0)
        theme_hbox.pack_end(self.theme_combo, False, False, 0)
        theme_box.pack_start(theme_hbox, False, False, 0)

        # Opacity setting
        opacity_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        opacity_label = Gtk.Label(label="Window Opacity:")
        opacity_label.set_halign(Gtk.Align.START)

        self.opacity_scale = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, 0.5, 1.0, 0.05
        )
        self.opacity_scale.set_hexpand(True)
        self.opacity_scale.set_show_fill_level(True)
        self.opacity_scale.set_digits(2)

        opacity_hbox.pack_start(opacity_label, False, False, 0)
        opacity_hbox.pack_start(self.opacity_scale, True, True, 0)
        theme_box.pack_start(opacity_hbox, False, False, 0)

        # Animation setting
        self.animation_check = Gtk.CheckButton(label="Enable animations")
        theme_box.pack_start(self.animation_check, False, False, 0)

        theme_frame.add(theme_box)
        vbox.pack_start(theme_frame, False, False, 0)

        # Window behavior
        behavior_frame = Gtk.Frame(label="Window Behavior")
        behavior_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        behavior_box.set_margin_start(15)
        behavior_box.set_margin_end(15)
        behavior_box.set_margin_top(10)
        behavior_box.set_margin_bottom(15)

        self.always_on_top_check = Gtk.CheckButton(label="Always on top")
        self.minimize_to_tray_check = Gtk.CheckButton(label="Minimize to system tray")
        self.auto_hide_check = Gtk.CheckButton(label="Auto-hide when focus lost")

        behavior_box.pack_start(self.always_on_top_check, False, False, 0)
        behavior_box.pack_start(self.minimize_to_tray_check, False, False, 0)
        behavior_box.pack_start(self.auto_hide_check, False, False, 0)

        behavior_frame.add(behavior_box)
        vbox.pack_start(behavior_frame, False, False, 0)

        # Add to notebook
        self.notebook.append_page(vbox, Gtk.Label(label="General"))

    def create_monitoring_tab(self):
        """Create monitoring settings tab"""
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        vbox.set_margin_start(20)
        vbox.set_margin_end(20)
        vbox.set_margin_top(20)
        vbox.set_margin_bottom(20)

        # Global settings
        global_frame = Gtk.Frame(label="Global Monitoring Settings")
        global_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        global_box.set_margin_start(15)
        global_box.set_margin_end(15)
        global_box.set_margin_top(10)
        global_box.set_margin_bottom(15)

        # Check interval
        interval_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        interval_label = Gtk.Label(label="Default check interval (seconds):")
        interval_label.set_halign(Gtk.Align.START)

        self.interval_spin = Gtk.SpinButton.new_with_range(5, 300, 5)

        interval_hbox.pack_start(interval_label, False, False, 0)
        interval_hbox.pack_end(self.interval_spin, False, False, 0)
        global_box.pack_start(interval_hbox, False, False, 0)

        # Parallel checks
        self.parallel_checks = Gtk.CheckButton(label="Enable parallel checking")
        global_box.pack_start(self.parallel_checks, False, False, 0)

        # Max concurrent
        concurrent_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        concurrent_label = Gtk.Label(label="Max concurrent checks:")
        concurrent_label.set_halign(Gtk.Align.START)

        self.concurrent_spin = Gtk.SpinButton.new_with_range(1, 20, 1)

        concurrent_hbox.pack_start(concurrent_label, False, False, 0)
        concurrent_hbox.pack_end(self.concurrent_spin, False, False, 0)
        global_box.pack_start(concurrent_hbox, False, False, 0)

        global_frame.add(global_box)
        vbox.pack_start(global_frame, False, False, 0)

        # Thresholds
        threshold_frame = Gtk.Frame(label="Response Time Thresholds")
        threshold_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        threshold_box.set_margin_start(15)
        threshold_box.set_margin_end(15)
        threshold_box.set_margin_top(10)
        threshold_box.set_margin_bottom(15)

        # Warning threshold
        warning_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        warning_label = Gtk.Label(label="Warning threshold (ms):")
        warning_label.set_halign(Gtk.Align.START)

        self.warning_spin = Gtk.SpinButton.new_with_range(100, 10000, 100)

        warning_hbox.pack_start(warning_label, False, False, 0)
        warning_hbox.pack_end(self.warning_spin, False, False, 0)
        threshold_box.pack_start(warning_hbox, False, False, 0)

        # Critical threshold
        critical_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        critical_label = Gtk.Label(label="Critical threshold (ms):")
        critical_label.set_halign(Gtk.Align.START)

        self.critical_spin = Gtk.SpinButton.new_with_range(500, 30000, 500)

        critical_hbox.pack_start(critical_label, False, False, 0)
        critical_hbox.pack_end(self.critical_spin, False, False, 0)
        threshold_box.pack_start(critical_hbox, False, False, 0)

        threshold_frame.add(threshold_box)
        vbox.pack_start(threshold_frame, False, False, 0)

        # History settings
        history_frame = Gtk.Frame(label="History & Data")
        history_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        history_box.set_margin_start(15)
        history_box.set_margin_end(15)
        history_box.set_margin_top(10)
        history_box.set_margin_bottom(15)

        self.uptime_tracking_check = Gtk.CheckButton(label="Enable uptime tracking")
        history_box.pack_start(self.uptime_tracking_check, False, False, 0)

        # Retention period
        retention_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        retention_label = Gtk.Label(label="Data retention (days):")
        retention_label.set_halign(Gtk.Align.START)

        self.retention_spin = Gtk.SpinButton.new_with_range(1, 365, 1)

        retention_hbox.pack_start(retention_label, False, False, 0)
        retention_hbox.pack_end(self.retention_spin, False, False, 0)
        history_box.pack_start(retention_hbox, False, False, 0)

        history_frame.add(history_box)
        vbox.pack_start(history_frame, False, False, 0)

        self.notebook.append_page(vbox, Gtk.Label(label="Monitoring"))

    def create_notifications_tab(self):
        """Create notifications settings tab"""
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        vbox.set_margin_start(20)
        vbox.set_margin_end(20)
        vbox.set_margin_top(20)
        vbox.set_margin_bottom(20)

        # Desktop notifications
        desktop_frame = Gtk.Frame(label="Desktop Notifications")
        desktop_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        desktop_box.set_margin_start(15)
        desktop_box.set_margin_end(15)
        desktop_box.set_margin_top(10)
        desktop_box.set_margin_bottom(15)

        self.desktop_notifications_check = Gtk.CheckButton(
            label="Enable desktop notifications"
        )
        self.status_change_notifications_check = Gtk.CheckButton(
            label="Notify on status changes"
        )
        self.slow_response_notifications_check = Gtk.CheckButton(
            label="Notify on slow responses"
        )
        self.sound_alerts_check = Gtk.CheckButton(label="Enable sound alerts")

        desktop_box.pack_start(self.desktop_notifications_check, False, False, 0)
        desktop_box.pack_start(self.status_change_notifications_check, False, False, 0)
        desktop_box.pack_start(self.slow_response_notifications_check, False, False, 0)
        desktop_box.pack_start(self.sound_alerts_check, False, False, 0)

        # Notification timeout
        timeout_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        timeout_label = Gtk.Label(label="Notification timeout (ms):")
        timeout_label.set_halign(Gtk.Align.START)

        self.notification_timeout_spin = Gtk.SpinButton.new_with_range(1000, 10000, 500)

        timeout_hbox.pack_start(timeout_label, False, False, 0)
        timeout_hbox.pack_end(self.notification_timeout_spin, False, False, 0)
        desktop_box.pack_start(timeout_hbox, False, False, 0)

        desktop_frame.add(desktop_box)
        vbox.pack_start(desktop_frame, False, False, 0)

        # Webhook notifications
        webhook_frame = Gtk.Frame(label="Webhook Integration")
        webhook_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        webhook_box.set_margin_start(15)
        webhook_box.set_margin_end(15)
        webhook_box.set_margin_top(10)
        webhook_box.set_margin_bottom(15)

        webhook_url_hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        webhook_url_label = Gtk.Label(label="Webhook URL:")
        webhook_url_label.set_halign(Gtk.Align.START)

        self.webhook_url_entry = Gtk.Entry()
        self.webhook_url_entry.set_placeholder_text(
            "https://hooks.slack.com/... or Discord webhook URL"
        )
        self.webhook_url_entry.set_hexpand(True)

        webhook_url_hbox.pack_start(webhook_url_label, False, False, 0)
        webhook_url_hbox.pack_start(self.webhook_url_entry, True, True, 0)
        webhook_box.pack_start(webhook_url_hbox, False, False, 0)

        # Test webhook button
        test_webhook_btn = Gtk.Button(label="Test Webhook")
        test_webhook_btn.connect("clicked", self.on_test_webhook)
        webhook_box.pack_start(test_webhook_btn, False, False, 0)

        webhook_frame.add(webhook_box)
        vbox.pack_start(webhook_frame, False, False, 0)

        self.notebook.append_page(vbox, Gtk.Label(label="Notifications"))

    def create_servers_tab(self):
        """Create servers management tab"""
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        vbox.set_margin_start(20)
        vbox.set_margin_end(20)
        vbox.set_margin_top(20)
        vbox.set_margin_bottom(20)

        # Toolbar
        toolbar_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        add_btn = Gtk.Button(label="Add Server")
        add_btn.connect("clicked", self.on_add_server)

        edit_btn = Gtk.Button(label="Edit Server")
        edit_btn.connect("clicked", self.on_edit_server)

        remove_btn = Gtk.Button(label="Remove Server")
        remove_btn.connect("clicked", self.on_remove_server)

        toolbar_box.pack_start(add_btn, False, False, 0)
        toolbar_box.pack_start(edit_btn, False, False, 0)
        toolbar_box.pack_start(remove_btn, False, False, 0)

        vbox.pack_start(toolbar_box, False, False, 0)

        # Servers list
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_min_content_height(300)

        # Create list store
        self.servers_store = Gtk.ListStore(
            str, str, str, str, int, bool
        )  # name, host, type, check_type, interval, enabled

        # Create tree view
        self.servers_tree = Gtk.TreeView(model=self.servers_store)

        # Add columns
        columns = [
            ("Name", 0),
            ("Host", 1),
            ("Type", 2),
            ("Check Type", 3),
            ("Interval", 4),
            ("Enabled", 5),
        ]

        for title, col_id in columns:
            if col_id == 5:  # Enabled column - checkbox
                renderer = Gtk.CellRendererToggle()
                renderer.connect("toggled", self.on_server_enabled_toggled)
                column = Gtk.TreeViewColumn(title, renderer, active=col_id)
            else:
                renderer = Gtk.CellRendererText()
                column = Gtk.TreeViewColumn(title, renderer, text=col_id)

            column.set_resizable(True)
            column.set_sort_column_id(col_id)
            self.servers_tree.append_column(column)

        scrolled.add(self.servers_tree)
        vbox.pack_start(scrolled, True, True, 0)

        self.notebook.append_page(vbox, Gtk.Label(label="Servers"))

    def load_settings(self):
        """Load current settings into the dialog"""
        ui_settings = self.settings_manager.ui_settings
        monitoring_settings = self.settings_manager.monitoring_settings
        notification_settings = self.settings_manager.notification_settings

        # General tab
        self.theme_combo.set_active_id(ui_settings.theme.value)
        self.opacity_scale.set_value(ui_settings.opacity)
        self.animation_check.set_active(ui_settings.animation_enabled)
        self.always_on_top_check.set_active(ui_settings.always_on_top)
        self.minimize_to_tray_check.set_active(ui_settings.minimize_to_tray)
        self.auto_hide_check.set_active(ui_settings.auto_hide)

        # Monitoring tab
        self.interval_spin.set_value(monitoring_settings.global_check_interval)
        self.parallel_checks.set_active(monitoring_settings.parallel_checks)
        self.concurrent_spin.set_value(monitoring_settings.max_concurrent_checks)
        self.warning_spin.set_value(monitoring_settings.max_response_time_warning)
        self.critical_spin.set_value(monitoring_settings.max_response_time_critical)
        self.uptime_tracking_check.set_active(
            monitoring_settings.enable_uptime_tracking
        )
        self.retention_spin.set_value(monitoring_settings.history_retention_days)

        # Notifications tab
        self.desktop_notifications_check.set_active(
            notification_settings.desktop_notifications
        )
        self.status_change_notifications_check.set_active(
            notification_settings.notify_on_status_change
        )
        self.slow_response_notifications_check.set_active(
            notification_settings.notify_on_slow_response
        )
        self.sound_alerts_check.set_active(notification_settings.sound_alerts)
        self.notification_timeout_spin.set_value(
            notification_settings.notification_timeout
        )

        if notification_settings.webhook_url:
            self.webhook_url_entry.set_text(notification_settings.webhook_url)

        # Servers tab
        self.load_servers_list()

    def load_servers_list(self):
        """Load servers into the list"""
        self.servers_store.clear()

        for server in self.settings_manager.servers:
            self.servers_store.append(
                [
                    server.name,
                    server.host,
                    server.type,
                    (
                        server.check_type.value
                        if hasattr(server.check_type, "value")
                        else str(server.check_type)
                    ),
                    server.check_interval,
                    server.enabled,
                ]
            )

    def save_settings(self):
        """Save settings from the dialog"""
        ui_settings = self.settings_manager.ui_settings
        monitoring_settings = self.settings_manager.monitoring_settings
        notification_settings = self.settings_manager.notification_settings

        # General tab
        ui_settings.theme = ThemeType(self.theme_combo.get_active_id())
        ui_settings.opacity = self.opacity_scale.get_value()
        ui_settings.animation_enabled = self.animation_check.get_active()
        ui_settings.always_on_top = self.always_on_top_check.get_active()
        ui_settings.minimize_to_tray = self.minimize_to_tray_check.get_active()
        ui_settings.auto_hide = self.auto_hide_check.get_active()

        # Monitoring tab
        monitoring_settings.global_check_interval = int(self.interval_spin.get_value())
        monitoring_settings.parallel_checks = self.parallel_checks.get_active()
        monitoring_settings.max_concurrent_checks = int(
            self.concurrent_spin.get_value()
        )
        monitoring_settings.max_response_time_warning = int(
            self.warning_spin.get_value()
        )
        monitoring_settings.max_response_time_critical = int(
            self.critical_spin.get_value()
        )
        monitoring_settings.enable_uptime_tracking = (
            self.uptime_tracking_check.get_active()
        )
        monitoring_settings.history_retention_days = int(
            self.retention_spin.get_value()
        )

        # Notifications tab
        notification_settings.desktop_notifications = (
            self.desktop_notifications_check.get_active()
        )
        notification_settings.notify_on_status_change = (
            self.status_change_notifications_check.get_active()
        )
        notification_settings.notify_on_slow_response = (
            self.slow_response_notifications_check.get_active()
        )
        notification_settings.sound_alerts = self.sound_alerts_check.get_active()
        notification_settings.notification_timeout = int(
            self.notification_timeout_spin.get_value()
        )

        webhook_url = self.webhook_url_entry.get_text().strip()
        notification_settings.webhook_url = webhook_url if webhook_url else None

        # Save to disk
        self.settings_manager.save_settings()

    def on_test_webhook(self, button):
        """Test webhook notification"""
        webhook_url = self.webhook_url_entry.get_text().strip()
        if not webhook_url:
            self.show_message("Error", "Please enter a webhook URL first.")
            return

        # Create temporary notification settings
        from .settings import NotificationSettings
        from .notifications import NotificationManager

        temp_settings = NotificationSettings(webhook_url=webhook_url)
        notifier = NotificationManager(temp_settings)

        # Send test notification
        notifier.send_webhook_notification(
            "Test Server",
            "unknown",
            "operational",
            123,
            "Test webhook notification from settings",
        )

        self.show_message(
            "Test Sent",
            "Test webhook notification sent! Check your webhook destination.",
        )

    def on_add_server(self, button):
        """Add new server"""
        dialog = ServerEditDialog(self, None)
        dialog.show_all()  # Ensure all widgets are visible
        response = dialog.run()

        if response == Gtk.ResponseType.OK:
            server = dialog.get_server_config()
            self.settings_manager.add_server(server)
            self.load_servers_list()

        dialog.destroy()

    def on_edit_server(self, button):
        """Edit selected server"""
        selection = self.servers_tree.get_selection()
        model, treeiter = selection.get_selected()

        if treeiter is None:
            self.show_message("No Selection", "Please select a server to edit.")
            return

        # Get server index
        path = model.get_path(treeiter)
        server_index = path.get_indices()[0]
        server = self.settings_manager.servers[server_index]

        dialog = ServerEditDialog(self, server)
        dialog.show_all()  # Ensure all widgets are visible
        response = dialog.run()

        if response == Gtk.ResponseType.OK:
            new_server = dialog.get_server_config()
            self.settings_manager.update_server(server.name, new_server)
            self.load_servers_list()

        dialog.destroy()

    def on_remove_server(self, button):
        """Remove selected server"""
        selection = self.servers_tree.get_selection()
        model, treeiter = selection.get_selected()

        if treeiter is None:
            self.show_message("No Selection", "Please select a server to remove.")
            return

        server_name = model.get_value(treeiter, 0)

        # Confirm removal
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text=f"Remove server '{server_name}'?",
        )
        dialog.format_secondary_text("This action cannot be undone.")

        response = dialog.run()
        dialog.destroy()

        if response == Gtk.ResponseType.YES:
            self.settings_manager.remove_server(server_name)
            self.load_servers_list()

    def on_server_enabled_toggled(self, renderer, path):
        """Toggle server enabled state"""
        treeiter = self.servers_store.get_iter(path)
        current_value = self.servers_store.get_value(treeiter, 5)

        # Update store
        self.servers_store.set_value(treeiter, 5, not current_value)

        # Update server config
        server_index = int(path)
        self.settings_manager.servers[server_index].enabled = not current_value
        self.settings_manager.save_servers()

    def show_message(self, title, message):
        """Show message dialog"""
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


class ServerEditDialog(Gtk.Dialog):
    def __init__(self, parent, server_config):
        title = "Edit Server" if server_config else "Add Server"
        super().__init__(title=title, transient_for=parent)

        self.server_config = server_config
        self.set_default_size(450, 350)
        self.set_resizable(True)

        # Add buttons
        self.add_button("Cancel", Gtk.ResponseType.CANCEL)
        self.add_button("OK", Gtk.ResponseType.OK)

        self.create_content()

        if server_config:
            self.load_server_config()

        # Show all widgets
        self.show_all()

    def create_content(self):
        """Create server edit dialog content"""
        content_area = self.get_content_area()
        content_area.set_spacing(10)
        content_area.set_margin_start(20)
        content_area.set_margin_end(20)
        content_area.set_margin_top(10)
        content_area.set_margin_bottom(10)

        # Create form
        grid = Gtk.Grid()
        grid.set_row_spacing(10)
        grid.set_column_spacing(10)

        # Name
        grid.attach(Gtk.Label(label="Name:", halign=Gtk.Align.START), 0, 0, 1, 1)
        self.name_entry = Gtk.Entry()
        grid.attach(self.name_entry, 1, 0, 1, 1)

        # Host
        grid.attach(Gtk.Label(label="Host:", halign=Gtk.Align.START), 0, 1, 1, 1)
        self.host_entry = Gtk.Entry()
        self.host_entry.set_placeholder_text("example.com or https://api.example.com")
        grid.attach(self.host_entry, 1, 1, 1, 1)

        # Port
        grid.attach(Gtk.Label(label="Port:", halign=Gtk.Align.START), 0, 2, 1, 1)
        self.port_spin = Gtk.SpinButton.new_with_range(1, 65535, 1)
        self.port_spin.set_value(80)
        grid.attach(self.port_spin, 1, 2, 1, 1)

        # Check type
        grid.attach(Gtk.Label(label="Check Type:", halign=Gtk.Align.START), 0, 3, 1, 1)
        self.check_type_combo = Gtk.ComboBoxText()
        self.check_type_combo.append("http", "HTTP/HTTPS")
        self.check_type_combo.append("ping", "Ping")
        self.check_type_combo.append("tcp", "TCP Socket")
        self.check_type_combo.append("custom", "Custom Command")
        self.check_type_combo.set_active(0)
        grid.attach(self.check_type_combo, 1, 3, 1, 1)

        # Check interval
        grid.attach(
            Gtk.Label(label="Check Interval (s):", halign=Gtk.Align.START), 0, 4, 1, 1
        )
        self.interval_spin = Gtk.SpinButton.new_with_range(5, 300, 5)
        self.interval_spin.set_value(15)
        grid.attach(self.interval_spin, 1, 4, 1, 1)

        # Group
        grid.attach(Gtk.Label(label="Group:", halign=Gtk.Align.START), 0, 5, 1, 1)
        self.group_entry = Gtk.Entry()
        self.group_entry.set_text("Default")
        grid.attach(self.group_entry, 1, 5, 1, 1)

        # Icon
        grid.attach(Gtk.Label(label="Icon:", halign=Gtk.Align.START), 0, 6, 1, 1)
        self.icon_entry = Gtk.Entry()
        self.icon_entry.set_placeholder_text("🖥️ (emoji or leave empty)")
        grid.attach(self.icon_entry, 1, 6, 1, 1)

        # Enabled
        self.enabled_check = Gtk.CheckButton(label="Enabled")
        self.enabled_check.set_active(True)
        grid.attach(self.enabled_check, 0, 7, 2, 1)

        content_area.pack_start(grid, True, True, 0)

    def load_server_config(self):
        """Load server configuration into form"""
        if not self.server_config:
            return

        self.name_entry.set_text(self.server_config.name)
        self.host_entry.set_text(self.server_config.host)

        if self.server_config.port:
            self.port_spin.set_value(self.server_config.port)

        check_type = (
            self.server_config.check_type.value
            if hasattr(self.server_config.check_type, "value")
            else str(self.server_config.check_type)
        )
        self.check_type_combo.set_active_id(check_type)

        self.interval_spin.set_value(self.server_config.check_interval)
        self.group_entry.set_text(self.server_config.group)

        if hasattr(self.server_config, "icon") and self.server_config.icon:
            self.icon_entry.set_text(self.server_config.icon)

        self.enabled_check.set_active(self.server_config.enabled)

    def get_server_config(self):
        """Get server configuration from form"""
        port = int(self.port_spin.get_value())
        icon = self.icon_entry.get_text().strip()

        return ServerConfig(
            name=self.name_entry.get_text(),
            host=self.host_entry.get_text(),
            port=port if port != 80 else None,
            check_type=CheckType(self.check_type_combo.get_active_id()),
            check_interval=int(self.interval_spin.get_value()),
            group=self.group_entry.get_text(),
            icon=icon if icon else None,
            enabled=self.enabled_check.get_active(),
        )
