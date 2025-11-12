#!/usr/bin/env python3
"""
System Tray Integration for Server Status Widget
"""

import gi

gi.require_version("Gtk", "3.0")

# Try to import AppIndicator3, but don't fail if it's not available
APPINDICATOR_AVAILABLE = False
try:
    gi.require_version("AppIndicator3", "0.1")
    from gi.repository import AppIndicator3 as AppIndicator

    APPINDICATOR_AVAILABLE = True
except (ImportError, ValueError):
    print("AppIndicator3 not available, using StatusIcon fallback")
    AppIndicator = None

from gi.repository import Gtk, GdkPixbuf, Gdk
import tempfile
import os
from pathlib import Path


class SystemTrayManager:
    def __init__(self, main_window, settings_manager):
        self.main_window = main_window
        self.settings_manager = settings_manager
        self.indicator = None
        self.status_icon = None
        self.menu = None

        # Create tray icon
        self.setup_tray()

    def is_available(self):
        """Check if system tray is available and working"""
        return (self.indicator is not None) or (self.status_icon is not None)

    def setup_tray(self):
        """Setup system tray icon"""
        if APPINDICATOR_AVAILABLE:
            self.setup_app_indicator()
        else:
            self.setup_status_icon()

    def setup_app_indicator(self):
        """Setup AppIndicator (preferred method for Ubuntu/GNOME)"""
        try:
            # Create a temporary icon file
            icon_path = self.create_tray_icon("operational")

            self.indicator = AppIndicator.Indicator.new(
                "server-monitor",
                icon_path,
                AppIndicator.IndicatorCategory.APPLICATION_STATUS,
            )

            self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)
            self.indicator.set_title("Server Monitor")

            # Create menu
            self.create_tray_menu()
            self.indicator.set_menu(self.menu)

            print("✅ AppIndicator system tray initialized")

        except Exception as e:
            print(f"❌ Failed to setup AppIndicator: {e}")
            self.setup_status_icon()

    def setup_status_icon(self):
        """Setup StatusIcon (fallback method)"""
        try:
            # Create icon
            icon_pixbuf = self.create_status_icon_pixbuf("operational")

            self.status_icon = Gtk.StatusIcon()
            self.status_icon.set_from_pixbuf(icon_pixbuf)
            self.status_icon.set_tooltip_text("Server Monitor")
            self.status_icon.set_visible(True)

            # Connect signals
            self.status_icon.connect("activate", self.on_tray_click)
            self.status_icon.connect("popup-menu", self.on_tray_right_click)

            print("✅ StatusIcon system tray initialized")

        except Exception as e:
            print(f"❌ Failed to setup StatusIcon: {e}")

    def create_tray_menu(self):
        """Create the system tray context menu"""
        self.menu = Gtk.Menu()

        # Show/Hide Window
        show_item = Gtk.MenuItem(label="Show Window")
        show_item.connect("activate", self.on_show_window)
        self.menu.append(show_item)

        hide_item = Gtk.MenuItem(label="Hide Window")
        hide_item.connect("activate", self.on_hide_window)
        self.menu.append(hide_item)

        # Separator
        separator1 = Gtk.SeparatorMenuItem()
        self.menu.append(separator1)

        # Refresh
        refresh_item = Gtk.MenuItem(label="Refresh All")
        refresh_item.connect("activate", self.on_refresh_all)
        self.menu.append(refresh_item)

        # Settings
        settings_item = Gtk.MenuItem(label="Settings")
        settings_item.connect("activate", self.on_show_settings)
        self.menu.append(settings_item)

        # Separator
        separator2 = Gtk.SeparatorMenuItem()
        self.menu.append(separator2)

        # Theme toggle
        theme_item = Gtk.MenuItem(label="Toggle Theme")
        theme_item.connect("activate", self.on_toggle_theme)
        self.menu.append(theme_item)

        # Separator
        separator3 = Gtk.SeparatorMenuItem()
        self.menu.append(separator3)

        # About
        about_item = Gtk.MenuItem(label="About")
        about_item.connect("activate", self.on_show_about)
        self.menu.append(about_item)

        # Quit
        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", self.on_quit)
        self.menu.append(quit_item)

        self.menu.show_all()

    def update_tray_status(
        self, overall_status: str, operational_count: int, total_count: int
    ):
        """Update tray icon based on overall system status"""
        # Determine icon status
        if operational_count == total_count:
            icon_status = "operational"
        elif operational_count == 0:
            icon_status = "down"
        else:
            icon_status = "degraded"

        # Update tooltip
        tooltip = f"Server Monitor: {operational_count}/{total_count} operational"

        if self.indicator:
            # Update AppIndicator
            icon_path = self.create_tray_icon(icon_status)
            self.indicator.set_icon(icon_path)
            self.indicator.set_title(tooltip)

        elif self.status_icon:
            # Update StatusIcon
            icon_pixbuf = self.create_status_icon_pixbuf(icon_status)
            self.status_icon.set_from_pixbuf(icon_pixbuf)
            self.status_icon.set_tooltip_text(tooltip)

    def create_tray_icon(self, status: str) -> str:
        """Create tray icon file and return path"""
        # Create a simple colored circle icon
        try:
            import cairo

            # Determine color based on status
            if status == "operational":
                color = (0.0, 0.8, 0.0)  # Green
            elif status == "down":
                color = (0.8, 0.0, 0.0)  # Red
            else:  # degraded
                color = (0.8, 0.6, 0.0)  # Orange

            # Create icon surface
            size = 22
            surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
            ctx = cairo.Context(surface)

            # Draw circle
            ctx.set_source_rgba(*color, 1.0)
            ctx.arc(size / 2, size / 2, size / 2 - 2, 0, 2 * 3.14159)
            ctx.fill()

            # Add border
            ctx.set_source_rgba(0.2, 0.2, 0.2, 1.0)
            ctx.set_line_width(1)
            ctx.arc(size / 2, size / 2, size / 2 - 2, 0, 2 * 3.14159)
            ctx.stroke()

            # Save to temporary file
            temp_dir = Path(tempfile.gettempdir())
            icon_path = temp_dir / f"server_monitor_{status}.png"
            surface.write_to_png(str(icon_path))

            return str(icon_path)

        except Exception as e:
            print(f"Error creating tray icon: {e}")
            # Return a fallback icon path
            return "applications-system"

    def create_status_icon_pixbuf(self, status: str):
        """Create pixbuf for StatusIcon"""
        try:
            # Create a simple colored square
            size = 22
            pixbuf = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, size, size)

            # Determine color based on status
            if status == "operational":
                color = 0x00CC00FF  # Green
            elif status == "down":
                color = 0xCC0000FF  # Red
            else:  # degraded
                color = 0xCC9900FF  # Orange

            pixbuf.fill(color)
            return pixbuf

        except Exception as e:
            print(f"Error creating status icon pixbuf: {e}")
            # Return default icon
            return Gtk.IconTheme.get_default().load_icon("applications-system", 22, 0)

    def on_tray_click(self, status_icon):
        """Handle tray icon click (toggle window visibility)"""
        if self.main_window.get_visible():
            self.main_window.hide()
            print("🔽 Window hidden via system tray")
        else:
            self.main_window.show_all()
            self.main_window.present()
            print("🔼 Window restored via system tray")

    def on_tray_right_click(self, status_icon, button, activate_time):
        """Handle tray icon right-click (show menu)"""
        if not self.menu:
            self.create_tray_menu()

        self.menu.popup(None, None, None, None, button, activate_time)

    def on_show_window(self, menu_item):
        """Show main window"""
        self.main_window.show_all()
        self.main_window.present()

    def on_hide_window(self, menu_item):
        """Hide main window"""
        self.main_window.hide()

    def on_refresh_all(self, menu_item):
        """Refresh all servers"""
        if hasattr(self.main_window, "on_refresh"):
            # Simulate refresh button click
            self.main_window.on_refresh(None)

    def on_show_settings(self, menu_item):
        """Show settings dialog"""
        if hasattr(self.main_window, "show_settings_dialog"):
            self.main_window.show_settings_dialog()

    def on_toggle_theme(self, menu_item):
        """Toggle theme"""
        if hasattr(self.main_window, "on_theme_toggle"):
            self.main_window.on_theme_toggle(None)

    def on_show_about(self, menu_item):
        """Show about dialog"""
        dialog = Gtk.AboutDialog()
        dialog.set_transient_for(self.main_window)
        dialog.set_program_name("Server Status Monitor")
        dialog.set_version("2.0")
        dialog.set_comments("A desktop widget for monitoring server status")
        dialog.set_authors(["Server Monitor Team"])
        dialog.set_license_type(Gtk.License.MIT_X11)
        dialog.set_logo_icon_name("applications-system")

        dialog.run()
        dialog.destroy()

    def on_quit(self, menu_item):
        """Quit application"""
        Gtk.main_quit()

    def show_notification_from_tray(
        self, title: str, message: str, urgency: str = "normal"
    ):
        """Show notification when window is hidden"""
        if not self.main_window.get_visible():
            # Only show notification if window is hidden
            if hasattr(self.main_window, "notification_manager"):
                self.main_window.notification_manager.send_desktop_notification(
                    title, message, urgency
                )

    def cleanup(self):
        """Cleanup tray resources"""
        if self.indicator:
            self.indicator.set_status(AppIndicator.IndicatorStatus.PASSIVE)

        if self.status_icon:
            self.status_icon.set_visible(False)

        # Clean up temporary icon files
        try:
            temp_dir = Path(tempfile.gettempdir())
            for icon_file in temp_dir.glob("server_monitor_*.png"):
                icon_file.unlink()
        except:
            pass
