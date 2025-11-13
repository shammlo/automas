#!/usr/bin/env python3
"""
Test HTTP optimization improvements
"""

import sys
import time
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_optimized_http_check():
    """Test the optimized HTTP check performance"""
    print("🧪 Testing optimized HTTP check...")

    try:
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        checker = HealthChecker()

        # Create test server config
        server = ServerConfig(
            name="Test Server", host="httpbin.org", check_type=CheckType.HTTP, timeout=3
        )

        # Test optimized HTTP check
        start_time = time.time()
        result = checker.check_http(server, timeout=2)
        check_time = time.time() - start_time

        print(f"✅ HTTP check completed in {check_time:.2f}s")
        print(
            f"✅ Result: {result.is_healthy}, {result.response_time}ms, {result.message}"
        )
        print(f"✅ Method used: {result.details.get('method', 'GET')}")

        # Should be faster than 2.5 seconds
        if check_time < 2.5:
            print("✅ Optimized HTTP check is performing well")
            return True
        else:
            print("⚠️ HTTP check might still be slow")
            return False

    except Exception as e:
        print(f"❌ Optimized HTTP check test failed: {e}")
        return False


def test_head_vs_get_performance():
    """Compare HEAD vs GET request performance"""
    print("\n🧪 Testing HEAD vs GET performance...")

    try:
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        checker = HealthChecker()

        # Test with content check (should use GET)
        server_with_content = ServerConfig(
            name="Test Server with Content",
            host="httpbin.org",
            check_type=CheckType.HTTP,
            expected_content="httpbin",  # This should trigger GET request
        )

        start_time = time.time()
        result_get = checker.check_http(server_with_content, timeout=3)
        get_time = time.time() - start_time

        # Test without content check (should use HEAD)
        server_no_content = ServerConfig(
            name="Test Server No Content", host="httpbin.org", check_type=CheckType.HTTP
        )

        start_time = time.time()
        result_head = checker.check_http(server_no_content, timeout=3)
        head_time = time.time() - start_time

        print(f"✅ GET request time: {get_time:.2f}s")
        print(f"✅ HEAD request time: {head_time:.2f}s")
        print(f"✅ HEAD method used: {result_head.details.get('method') == 'HEAD'}")

        # HEAD should generally be faster or similar
        if head_time <= get_time + 0.5:  # Allow some variance
            print("✅ HEAD optimization is working")
            return True
        else:
            print("⚠️ HEAD optimization might need tuning")
            return False

    except Exception as e:
        print(f"❌ HEAD vs GET test failed: {e}")
        return False


def test_quick_http_check():
    """Test the ultra-fast quick HTTP check"""
    print("\n🧪 Testing quick HTTP check...")

    try:
        from core.health_checker import HealthChecker

        checker = HealthChecker()

        # Test quick HTTP check
        start_time = time.time()
        result = checker.quick_http_check("http://httpbin.org/status/200", timeout=2)
        check_time = time.time() - start_time

        print(f"✅ Quick HTTP check completed in {check_time:.2f}s")
        print(
            f"✅ Result: {result.is_healthy}, {result.response_time}ms, {result.message}"
        )
        print(f"✅ Method: {result.details.get('method', 'Unknown')}")

        # Should be very fast
        if check_time < 2.2 and result.details.get("method") == "HEAD":
            print("✅ Quick HTTP check is optimized")
            return True
        else:
            print("⚠️ Quick HTTP check needs optimization")
            return False

    except Exception as e:
        print(f"❌ Quick HTTP check test failed: {e}")
        return False


def test_error_handling_speed():
    """Test that error handling is fast"""
    print("\n🧪 Testing error handling speed...")

    try:
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        checker = HealthChecker()

        # Test with non-existent server (should fail fast)
        server = ServerConfig(
            name="Non-existent Server",
            host="this-domain-does-not-exist-12345.com",
            check_type=CheckType.HTTP,
        )

        start_time = time.time()
        result = checker.check_http(server, timeout=2)
        error_time = time.time() - start_time

        print(f"✅ Error handling completed in {error_time:.2f}s")
        print(f"✅ Result: {result.is_healthy}, {result.message}")

        # Error should be detected quickly (within timeout + small buffer)
        if error_time < 2.5 and not result.is_healthy:
            print("✅ Error handling is fast")
            return True
        else:
            print("⚠️ Error handling might be slow")
            return False

    except Exception as e:
        print(f"❌ Error handling test failed: {e}")
        return False


def main():
    """Run HTTP optimization tests"""
    print("🛰️ Sato HTTP Optimization Tests")
    print("=" * 50)

    tests = [
        test_optimized_http_check,
        test_head_vs_get_performance,
        test_quick_http_check,
        test_error_handling_speed,
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
    print(f"🧪 HTTP optimization tests completed: {passed}/{total} passed")

    if passed == total:
        print("🎉 All HTTP optimizations are working!")
        print("💡 HTTP status checking should be significantly faster now.")
        return 0
    else:
        print("⚠️ Some HTTP optimization tests failed. Check the output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
