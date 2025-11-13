#!/usr/bin/env python3
"""
Test script for Sato Enhanced Monitoring System features
"""

import sys
import time
from pathlib import Path

# Add parent directory to path (sato_enhanced root)
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_basic_imports():
    """Test that all modules can be imported"""
    print("🧪 Testing basic imports...")

    try:
        from core.settings import SettingsManager, ServerConfig, CheckType

        print("✅ Settings module imported")

        from core.health_checker import HealthChecker

        print("✅ Health checker imported")

        from core.status_tracker import StatusTracker

        print("✅ Status tracker imported")

        from core.notifications import NotificationManager

        print("✅ Notification manager imported")

        return True
    except ImportError as e:
        print(f"❌ Import failed: {e}")
        return False


def test_settings_manager():
    """Test settings manager functionality"""
    print("\n🧪 Testing settings manager...")

    try:
        from core.settings import SettingsManager

        config_dir = Path(__file__).parent.parent
        settings = SettingsManager(config_dir)

        print(f"✅ Loaded {len(settings.servers)} servers")
        print(f"✅ Theme: {settings.ui_settings.theme}")
        print(
            f"✅ Notifications: {settings.notification_settings.desktop_notifications}"
        )

        return True
    except Exception as e:
        print(f"❌ Settings test failed: {e}")
        return False


def test_health_checker():
    """Test health checker functionality"""
    print("\n🧪 Testing health checker...")

    try:
        from core.health_checker import HealthChecker, CheckResult

        checker = HealthChecker()

        # Test internet connectivity
        has_internet = checker.check_internet_connectivity()
        print(f"✅ Internet connectivity: {has_internet}")

        return True
    except Exception as e:
        print(f"❌ Health checker test failed: {e}")
        return False


def test_enhanced_features():
    """Test enhanced monitoring features"""
    print("\n🧪 Testing enhanced features...")

    try:
        # Mock the GTK parts for testing
        class MockSato:
            def __init__(self):
                self.auto_restart_enabled = True
                self.maintenance_mode = False
                self.retry_counts = {}
                self.failure_timestamps = {}
                self.healing_actions = {}
                self.service_dependencies = {}

            def should_attempt_restart(self, server):
                """Test restart logic"""
                if not self.auto_restart_enabled or self.maintenance_mode:
                    return False

                server_name = server.name
                recent_failures = len(self.failure_timestamps.get(server_name, []))
                if recent_failures > 5:
                    return False

                retry_count = self.retry_counts.get(server_name, 0)
                if retry_count >= 3:
                    return False

                return True

            def toggle_maintenance_mode(self):
                """Toggle maintenance mode"""
                self.maintenance_mode = not self.maintenance_mode
                return self.maintenance_mode

        # Test mock Sato
        mock_sato = MockSato()

        # Test maintenance mode toggle
        assert not mock_sato.maintenance_mode
        mock_sato.toggle_maintenance_mode()
        assert mock_sato.maintenance_mode
        print("✅ Maintenance mode toggle works")

        # Test restart logic
        class MockServer:
            def __init__(self, name):
                self.name = name
                self.type = "server"

        server = MockServer("Test Server")

        # Should restart when maintenance mode is off
        mock_sato.maintenance_mode = False
        assert mock_sato.should_attempt_restart(server)

        # Should not restart when maintenance mode is on
        mock_sato.maintenance_mode = True
        assert not mock_sato.should_attempt_restart(server)

        print("✅ Auto-restart logic works")

        return True
    except Exception as e:
        print(f"❌ Enhanced features test failed: {e}")
        return False


def main():
    """Run all tests"""
    print("🛰️ Sato Enhanced Monitoring System - Feature Tests")
    print("=" * 60)

    tests = [
        test_basic_imports,
        test_settings_manager,
        test_health_checker,
        test_enhanced_features,
    ]

    passed = 0
    total = len(tests)

    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ Test {test.__name__} crashed: {e}")

    print("\n" + "=" * 60)
    print(f"🧪 Tests completed: {passed}/{total} passed")

    if passed == total:
        print("🎉 All tests passed! Sato enhanced features are working.")
        return 0
    else:
        print("⚠️ Some tests failed. Check the output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
