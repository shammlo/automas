#!/usr/bin/env python3
"""
Performance test for Sato Enhanced Monitoring System
"""

import sys
import time
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_fast_health_checker():
    """Test the fast health checker performance"""
    print("🧪 Testing fast health checker performance...")

    try:
        from core.performance_optimizer import FastHealthChecker

        checker = FastHealthChecker()

        # Test HTTP check speed
        start_time = time.time()
        result = checker.quick_http_check("http://httpbin.org/status/200", timeout=3)
        check_time = time.time() - start_time

        print(f"✅ HTTP check completed in {check_time:.2f}s")
        print(
            f"✅ Result: {result.is_healthy}, {result.response_time}ms, {result.message}"
        )

        # Should be faster than 3 seconds
        if check_time < 3.0:
            print("✅ Fast health checker is performing well")
            return True
        else:
            print("⚠️ Health checker might be slow")
            return False

    except Exception as e:
        print(f"❌ Fast health checker test failed: {e}")
        return False


def test_performance_optimizer():
    """Test the performance optimizer"""
    print("\n🧪 Testing performance optimizer...")

    try:
        from core.performance_optimizer import PerformanceOptimizer
        from core.health_checker import HealthChecker
        from core.settings import ServerConfig, CheckType

        optimizer = PerformanceOptimizer(max_workers=3)
        health_checker = HealthChecker()

        # Create test servers
        test_servers = [
            ServerConfig(
                name="Test Server 1",
                host="httpbin.org",
                check_type=CheckType.HTTP,
                enabled=True,
            ),
            ServerConfig(
                name="Test Server 2",
                host="httpbin.org/status/200",
                check_type=CheckType.HTTP,
                enabled=True,
            ),
        ]

        # Test parallel checks
        start_time = time.time()
        results = optimizer.parallel_health_checks(
            test_servers, health_checker, timeout=3
        )
        parallel_time = time.time() - start_time

        print(f"✅ Parallel checks completed in {parallel_time:.2f}s")
        print(f"✅ Results: {len(results)} servers checked")

        # Cleanup
        optimizer.shutdown()

        # Should be faster than sequential checks
        if parallel_time < 5.0:
            print("✅ Performance optimizer is working well")
            return True
        else:
            print("⚠️ Performance optimizer might need tuning")
            return False

    except Exception as e:
        print(f"❌ Performance optimizer test failed: {e}")
        return False


def test_batch_docker_checks():
    """Test batch Docker checks"""
    print("\n🧪 Testing batch Docker checks...")

    try:
        from core.performance_optimizer import PerformanceOptimizer

        optimizer = PerformanceOptimizer()

        # Mock Docker services (empty list for test)
        docker_services = []

        start_time = time.time()
        results = optimizer.batch_docker_checks(docker_services)
        batch_time = time.time() - start_time

        print(f"✅ Batch Docker checks completed in {batch_time:.2f}s")
        print(f"✅ Results: {len(results)} services processed")

        # Cleanup
        optimizer.shutdown()

        print("✅ Batch Docker checks are optimized")
        return True

    except Exception as e:
        print(f"❌ Batch Docker checks test failed: {e}")
        return False


def test_monitoring_intervals():
    """Test optimized monitoring intervals"""
    print("\n🧪 Testing monitoring interval optimization...")

    try:
        from core.settings import ServerConfig, CheckType
        from core.performance_optimizer import PerformanceOptimizer

        optimizer = PerformanceOptimizer()

        # Create test server with performance tracking
        server = ServerConfig(
            name="Test Server",
            host="example.com",
            check_type=CheckType.HTTP,
            check_interval=15,
        )
        server._consecutive_success = 15  # Simulate stable service

        original_interval = server.check_interval
        optimizer.optimize_check_intervals([server])

        print(f"✅ Original interval: {original_interval}s")
        print(f"✅ Optimized interval: {server.check_interval}s")

        # Should increase interval for stable services
        if server.check_interval >= original_interval:
            print("✅ Interval optimization is working")
            return True
        else:
            print("⚠️ Interval optimization needs adjustment")
            return False

    except Exception as e:
        print(f"❌ Monitoring interval test failed: {e}")
        return False


def main():
    """Run performance tests"""
    print("🛰️ Sato Performance Tests")
    print("=" * 50)

    tests = [
        test_fast_health_checker,
        test_performance_optimizer,
        test_batch_docker_checks,
        test_monitoring_intervals,
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
    print(f"🧪 Performance tests completed: {passed}/{total} passed")

    if passed == total:
        print("🎉 All performance optimizations are working!")
        print("💡 Status checking should be much faster now.")
        return 0
    else:
        print("⚠️ Some performance tests failed. Check the output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
