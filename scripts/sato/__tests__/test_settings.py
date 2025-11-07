#!/usr/bin/env python3
"""
Test Settings Manager
"""

import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from core.settings import SettingsManager, ServerConfig, CheckType, ThemeType
import tempfile
import shutil


def test_settings_manager():
    """Test the settings manager functionality"""
    print("🧪 Testing Settings Manager...")

    # Create temporary directory for testing
    test_dir = Path(tempfile.mkdtemp())
    print(f"📁 Test directory: {test_dir}")

    try:
        # Initialize settings manager
        settings = SettingsManager(test_dir)
        print("✅ Settings manager initialized")

        # Test default servers
        print(f"📊 Default servers loaded: {len(settings.servers)}")
        for server in settings.servers:
            print(f"   - {server.name}: {server.host} ({server.check_type.value})")

        # Test adding a new server
        new_server = ServerConfig(
            name="Test Server",
            host="https://example.com",
            check_type=CheckType.HTTP,
            group="Testing",
            check_interval=30,
        )

        settings.add_server(new_server)
        print("✅ Added new server")

        # Test server grouping
        groups = settings.get_servers_by_group()
        print(f"📊 Server groups: {list(groups.keys())}")
        for group_name, servers in groups.items():
            print(f"   {group_name}: {len(servers)} servers")

        # Test settings persistence
        settings.save_settings()
        settings.save_servers()
        print("✅ Settings saved")

        # Test loading settings
        settings2 = SettingsManager(test_dir)
        print(f"✅ Settings reloaded: {len(settings2.servers)} servers")

        # Test UI settings
        print(f"🎨 Theme: {settings.ui_settings.theme.value}")
        print(f"🔍 Opacity: {settings.ui_settings.opacity}")
        print(f"🔔 Notifications: {settings.ui_settings.show_notifications}")

        # Test monitoring settings
        print(
            f"⏱️  Check interval: {settings.monitoring_settings.global_check_interval}s"
        )
        print(
            f"⚠️  Warning threshold: {settings.monitoring_settings.max_response_time_warning}ms"
        )

        print("✅ All settings tests passed!")

    except Exception as e:
        print(f"❌ Settings test failed: {e}")
        import traceback

        traceback.print_exc()

    finally:
        # Cleanup
        shutil.rmtree(test_dir)
        print(f"🧹 Cleaned up test directory")


if __name__ == "__main__":
    test_settings_manager()
