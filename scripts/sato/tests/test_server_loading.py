#!/usr/bin/env python3
"""
Test server loading and health checking
"""

import sys
import time
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_server_loading():
    """Test that servers load correctly from config"""
    print("🧪 Testing server loading...")

    try:
        from core.settings import SettingsManager

        config_dir = Path(__file__).parent.parent
        settings = SettingsManager(config_dir)

        print(f"✅ Loaded {len(settings.servers)} servers")

        for i, server in enumerate(settings.servers):
            print(f"  {i+1}. {server.name}")
            print(f"     Host: {server.host}")
            print(f"     Type: {server.check_type}")
            print(f"     Expected codes: {server.expected_status_codes}")
            print()

        return len(settings.servers) > 0

    except Exception as e:
        print(f"❌ Server loading test failed: {e}")
        return False


def test_url_building():
    """Test URL building for different server configurations"""
    print("🧪 Testing URL building...")

    try:
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        checker = HealthChecker()

        # Test different server configurations
        test_servers = [
            ServerConfig(
                name="HTTPS with port",
                host="api-dev.example.com",
                port=5443,
                check_type=CheckType.HTTP,
            ),
            ServerConfig(
                name="Full URL",
                host="https://api-uat.example.com",
                check_type=CheckType.HTTP,
            ),
            ServerConfig(
                name="URL with path",
                host="https://admin-api-dev.example.com:6069/api/",
                check_type=CheckType.HTTP,
            ),
        ]

        for server in test_servers:
            url = checker.build_url(server)
            print(f"✅ {server.name}: {url}")

        return True

    except Exception as e:
        print(f"❌ URL building test failed: {e}")
        return False


def test_single_health_check():
    """Test a single health check"""
    print("🧪 Testing single health check...")

    try:
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        checker = HealthChecker()

        # Test with a simple HTTP service
        server = ServerConfig(
            name="Test Server",
            host="httpbin.org",
            check_type=CheckType.HTTP,
            expected_status_codes=[200],
        )

        print(f"Testing: {checker.build_url(server)}")

        start_time = time.time()
        result = checker.check_server(server, timeout=5)
        check_time = time.time() - start_time

        print(f"✅ Health check completed in {check_time:.2f}s")
        print(f"✅ Result: {result.is_healthy}")
        print(f"✅ Message: {result.message}")
        print(f"✅ Response time: {result.response_time}ms")

        return result is not None

    except Exception as e:
        print(f"❌ Health check test failed: {e}")
        import traceback

        traceback.print_exc()
        return False


def main():
    """Run server loading and health check tests"""
    print("🛰️ Sato Server Loading & Health Check Tests")
    print("=" * 60)

    tests = [
        test_server_loading,
        test_url_building,
        test_single_health_check,
    ]

    passed = 0
    total = len(tests)

    for test in tests:
        try:
            if test():
                passed += 1
            print()
        except Exception as e:
            print(f"❌ Test {test.__name__} crashed: {e}")

    print("=" * 60)
    print(f"🧪 Tests completed: {passed}/{total} passed")

    if passed == total:
        print("🎉 Server loading and health checking are working!")
        return 0
    else:
        print("⚠️ Some tests failed. Check the output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
