#!/usr/bin/env python3
"""
Test monitoring responsiveness improvements
"""

import sys
import time
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_http_check_speed():
    """Test HTTP check speed with optimized timeouts"""
    print("🧪 Testing HTTP check speed...")

    try:
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        checker = HealthChecker()

        # Test with a fast responding service
        server = ServerConfig(
            name="Fast Test Server",
            host="httpbin.org",
            check_type=CheckType.HTTP,
            expected_status_codes=[200],
        )

        # Test multiple times to get average
        times = []
        for i in range(3):
            start_time = time.time()
            result = checker.check_server(server, timeout=3)
            check_time = time.time() - start_time
            times.append(check_time)
            print(f"  Check {i+1}: {check_time:.2f}s - {result.message}")

        avg_time = sum(times) / len(times)
        print(f"✅ Average HTTP check time: {avg_time:.2f}s")

        # Should be under 2 seconds for good responsiveness
        if avg_time < 2.0:
            print("✅ HTTP checks are responsive!")
            return True
        else:
            print("⚠️ HTTP checks might still be slow")
            return False

    except Exception as e:
        print(f"❌ HTTP check speed test failed: {e}")
        return False


def test_parallel_check_speed():
    """Test parallel check speed with optimized settings"""
    print("\n🧪 Testing parallel check speed...")

    try:
        from core.settings import SettingsManager
        from core.health_checker import HealthChecker
        from core.performance_optimizer import PerformanceOptimizer

        config_dir = Path(__file__).parent.parent
        settings = SettingsManager(config_dir)
        health_checker = HealthChecker()
        optimizer = PerformanceOptimizer(max_workers=3)

        # Get regular services
        regular_services = [s for s in settings.servers if s.type != "docker_service"]

        if len(regular_services) < 2:
            print("⚠️ Need at least 2 services to test parallel speed")
            return True

        print(f"Testing parallel checks with {len(regular_services)} services...")

        # Test parallel processing speed
        start_time = time.time()
        parallel_results = optimizer.parallel_health_checks(
            regular_services, health_checker, timeout=4
        )
        parallel_time = time.time() - start_time

        print(f"✅ Parallel check time: {parallel_time:.2f}s")
        print(f"✅ Results: {len(parallel_results)} services checked")

        # Should be under 6 seconds for good responsiveness
        if parallel_time < 6.0:
            print("✅ Parallel checks are responsive!")
            success = True
        else:
            print("⚠️ Parallel checks might be slow")
            success = False

        # Cleanup
        optimizer.shutdown()
        return success

    except Exception as e:
        print(f"❌ Parallel check speed test failed: {e}")
        return False


def test_quick_http_check():
    """Test the ultra-fast quick HTTP check"""
    print("\n🧪 Testing quick HTTP check speed...")

    try:
        from core.performance_optimizer import FastHealthChecker

        checker = FastHealthChecker()

        # Test quick HTTP check
        start_time = time.time()
        result = checker.quick_http_check("http://httpbin.org/status/200", timeout=1.5)
        check_time = time.time() - start_time

        print(f"✅ Quick HTTP check time: {check_time:.2f}s")
        print(f"✅ Result: {result.is_healthy}, {result.message}")

        # Should be very fast
        if check_time < 1.8:
            print("✅ Quick HTTP check is very responsive!")
            return True
        else:
            print("⚠️ Quick HTTP check could be faster")
            return False

    except Exception as e:
        print(f"❌ Quick HTTP check test failed: {e}")
        return False


def test_timeout_effectiveness():
    """Test that timeouts work quickly for unresponsive services"""
    print("\n🧪 Testing timeout effectiveness...")

    try:
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        checker = HealthChecker()

        # Test with a non-existent service (should timeout quickly)
        server = ServerConfig(
            name="Timeout Test",
            host="192.0.2.1",  # Reserved IP that should not respond
            check_type=CheckType.HTTP,
            port=12345,
        )

        start_time = time.time()
        result = checker.check_server(server, timeout=3)
        timeout_time = time.time() - start_time

        print(f"✅ Timeout test time: {timeout_time:.2f}s")
        print(f"✅ Result: {result.message}")

        # Should timeout within 4 seconds (3s timeout + small buffer)
        if timeout_time < 4.0 and not result.is_healthy:
            print("✅ Timeouts are working effectively!")
            return True
        else:
            print("⚠️ Timeouts might be too slow")
            return False

    except Exception as e:
        print(f"❌ Timeout test failed: {e}")
        return False


def main():
    """Run responsiveness tests"""
    print("🛰️ Sato Responsiveness Tests")
    print("=" * 50)

    tests = [
        test_http_check_speed,
        test_parallel_check_speed,
        test_quick_http_check,
        test_timeout_effectiveness,
    ]

    passed = 0
    total = len(tests)

    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ Test {test.__name__} crashed: {e}")

    print("\n" + "=" * 50)
    print(f"🧪 Responsiveness tests completed: {passed}/{total} passed")

    if passed == total:
        print("🎉 Sato monitoring is now highly responsive!")
        print("💡 Status updates should appear much faster.")
        return 0
    else:
        print("⚠️ Some responsiveness tests failed.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
