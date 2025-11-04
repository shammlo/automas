#!/usr/bin/env python3
"""
Test System Tray Integration
"""

import sys
import os
from pathlib import Path
import time

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

from core.system_tray import SystemTrayManager
from core.settings import SettingsManager
import tempfile
import shutil


class MockMainWindow(Gtk.Window):
    """Mock main window for testing"""

    def __init__(self):
        super().__init__()
        self.set_title("Mock Server Monitor")
        self.set_default_size(400, 300)

        # Add some content
        label = Gtk.Label(
            label="Mock Server Monitor Window\nThis is for testing the system tray"
        )
        self.add(label)

        self.notification_manager = None

    def on_refresh(self, button):
        print("🔄 Mock refresh triggered from tray")

    def on_theme_toggle(self, button):
        print("🎨 Mock theme toggle triggered from tray")

    def show_settings_dialog(self):
        print("⚙️ Mock settings dialog triggered from tray")


def test_system_tray():
    """Test the system tray functionality"""
    print("🧪 Testing System Tray Integration...")

    # Create temporary directory for settings
    test_dir = Path(tempfile.mkdtemp())

    try:
        # Initialize components
        settings_manager = SettingsManager(test_dir)
        main_window = MockMainWindow()

        print("✅ Mock components initialized")

        # Initialize system tray
        tray_manager = SystemTrayManager(main_window, settings_manager)
        print("✅ System tray manager initialized")

        # Check tray availability
        if tray_manager.indicator:
            print("✅ AppIndicator system tray available")
        elif tray_manager.status_icon:
            print("✅ StatusIcon system tray available")
        else:
            print("❌ No system tray method available")
            return

        # Show main window initially
        main_window.show_all()
        print("✅ Main window shown")

        # Test tray status updates
        print("\n📊 Testing tray status updates...")

        test_statuses = [
            ("operational", 5, 5, "All services operational"),
            ("degraded", 3, 5, "Some services degraded"),
            ("down", 0, 5, "All services down"),
            ("operational", 5, 5, "Services restored"),
        ]

        def update_tray_status():
            for i, (status, operational, total, description) in enumerate(
                test_statuses
            ):
                print(f"   {i+1}. {description}")
                tray_manager.update_tray_status(status, operational, total)
                time.sleep(2)

            return False  # Don't repeat

        # Schedule tray updates
        GLib.timeout_add_seconds(2, update_tray_status)

        # Test tray menu (if available)
        if tray_manager.menu:
            print("✅ Tray context menu created")
            menu_items = []

            def collect_menu_items(container):
                for child in container.get_children():
                    if isinstance(child, Gtk.MenuItem):
                        label = (
                            child.get_label()
                            if hasattr(child, "get_label")
                            else "Separator"
                        )
                        menu_items.append(label)

            collect_menu_items(tray_manager.menu)
            print(f"   Menu items: {menu_items}")

        # Instructions for manual testing
        print(f"\n📋 Manual Testing Instructions:")
        print(f"   1. Look for the system tray icon (colored circle)")
        print(f"   2. The icon should change colors over the next 8 seconds:")
        print(f"      - Green: All operational")
        print(f"      - Orange: Some degraded")
        print(f"      - Red: All down")
        print(f"      - Green: Restored")
        print(f"   3. Try clicking the tray icon to hide/show the window")
        print(f"   4. Try right-clicking the tray icon to see the context menu")
        print(f"   5. Test menu items like 'Refresh All', 'Settings', etc.")
        print(f"   6. Close this window or press Ctrl+C to exit")

        # Auto-close after 30 seconds for automated testing
        def auto_close():
            print("\n⏰ Auto-closing test after 30 seconds...")
            Gtk.main_quit()
            return False

        GLib.timeout_add_seconds(30, auto_close)

        # Connect window close event
        main_window.connect("destroy", Gtk.main_quit)

        print(f"\n🚀 Starting GTK main loop for interactive testing...")
        print(f"   (Test will auto-close in 30 seconds)")

        # Start GTK main loop
        Gtk.main()

        print("✅ System tray test completed!")

    except Exception as e:
        print(f"❌ System tray test failed: {e}")
        import traceback

        traceback.print_exc()

    finally:
        # Cleanup
        if "tray_manager" in locals():
            tray_manager.cleanup()

        shutil.rmtree(test_dir)
        print(f"🧹 Cleaned up test directory")


if __name__ == "__main__":
    # Check if we're in a GUI environment
    if not os.environ.get("DISPLAY") and not os.environ.get("WAYLAND_DISPLAY"):
        print("❌ No display environment detected. System tray test requires a GUI.")
        print("   Please run this test in a desktop environment.")
        sys.exit(1)

    test_system_tray()
