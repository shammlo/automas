#!/usr/bin/env python3
"""
Test parallel monitoring performance
"""

import sys
import time
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_parallel_vs_sequential():
    """Compare parallel vs sequential monitoring performance"""
    print("🧪 Testing parallel vs sequential monitoring...")

    try:
        from core.settings import SettingsManager
        from core.health_checker import HealthChecker
        from core.performance_optimizer import PerformanceOptimizer

        config_dir = Path(__file__).parent.parent
        settings = SettingsManager(config_dir)
        health_checker = HealthChecker()
        optimizer = PerformanceOptimizer(max_workers=3)

        # Get regular services (non-Docker)
        regular_services = [s for s in settings.servers if s.type != "docker_service"]

        if len(regular_services) < 2:
            print("⚠️ Need at least 2 services to test parallel processing")
            return False

        print(f"Testing with {len(regular_services)} services...")

        # Test sequential processing
        print("\n📊 Sequential processing:")
        start_time = time.time()
        sequential_results = []
        for server in regular_services:
            result = health_checker.check_server(server, timeout=5)
            sequential_results.append(result)
        sequential_time = time.time() - start_time

        print(f"  Time: {sequential_time:.2f}s")
        print(f"  Results: {len(sequential_results)} checks completed")

        # Test parallel processing
        print("\n⚡ Parallel processing:")
        start_time = time.time()
        parallel_results = optimizer.parallel_health_checks(
            regular_services, health_checker, timeout=5
        )
        parallel_time = time.time() - start_time

        print(f"  Time: {parallel_time:.2f}s")
        print(f"  Results: {len(parallel_results)} checks completed")

        # Calculate improvement
        if parallel_time > 0:
            speedup = sequential_time / parallel_time
            improvement = ((sequential_time - parallel_time) / sequential_time) * 100

            print(f"\n🚀 Performance improvement:")
            print(f"  Speedup: {speedup:.2f}x faster")
            print(f"  Time saved: {improvement:.1f}%")

            # Parallel should be significantly faster for multiple services
            if speedup > 1.5:  # At least 50% faster
                print("✅ Parallel processing is working effectively!")
                return True
            else:
                print("⚠️ Parallel processing improvement is minimal")
                return False
        else:
            print("⚠️ Could not measure parallel processing time")
            return False

        # Cleanup
        optimizer.shutdown()

    except Exception as e:
        print(f"❌ Parallel monitoring test failed: {e}")
        import traceback

        traceback.print_exc()
        return False


def test_batch_monitoring_simulation():
    """Simulate the batch monitoring process"""
    print("\n🧪 Testing batch monitoring simulation...")

    try:
        from core.settings import SettingsManager
        from core.health_checker import HealthChecker
        from core.performance_optimizer import PerformanceOptimizer

        config_dir = Path(__file__).parent.parent
        settings = SettingsManager(config_dir)
        health_checker = HealthChecker()
        optimizer = PerformanceOptimizer(max_workers=3)

        # Separate services like the real batch monitoring does
        docker_services = []
        regular_services = []

        for i, server in enumerate(settings.servers):
            if server.type == "docker_service":
                docker_services.append((i, server))
            else:
                regular_services.append((i, server))

        print(f"Docker services: {len(docker_services)}")
        print(f"Regular services: {len(regular_services)}")

        # Test batch processing
        start_time = time.time()

        # Process Docker services in batch
        if docker_services:
            docker_results = optimizer.batch_docker_checks(docker_services)
            print(f"Docker batch results: {len(docker_results)}")

        # Process regular services in parallel
        if regular_services:
            servers_only = [server for _, server in regular_services]
            parallel_results = optimizer.parallel_health_checks(
                servers_only, health_checker, timeout=5
            )
            print(f"Parallel results: {len(parallel_results)}")

        batch_time = time.time() - start_time

        print(f"✅ Batch monitoring completed in {batch_time:.2f}s")
        print(
            f"✅ Total services processed: {len(docker_services) + len(regular_services)}"
        )

        # Cleanup
        optimizer.shutdown()

        return True

    except Exception as e:
        print(f"❌ Batch monitoring simulation failed: {e}")
        import traceback

        traceback.print_exc()
        return False


def test_concurrent_futures():
    """Test that concurrent futures are working properly"""
    print("\n🧪 Testing concurrent futures implementation...")

    try:
        from concurrent.futures import ThreadPoolExecutor, as_completed
        import time

        def mock_health_check(service_id):
            """Mock health check that takes some time"""
            time.sleep(0.5)  # Simulate network delay
            return f"Service {service_id} checked"

        services = [f"service_{i}" for i in range(5)]

        # Test sequential
        start_time = time.time()
        sequential_results = []
        for service in services:
            result = mock_health_check(service)
            sequential_results.append(result)
        sequential_time = time.time() - start_time

        # Test parallel with ThreadPoolExecutor
        start_time = time.time()
        parallel_results = []
        with ThreadPoolExecutor(max_workers=3) as executor:
            futures = {
                executor.submit(mock_health_check, service): service
                for service in services
            }
            for future in as_completed(futures):
                result = future.result()
                parallel_results.append(result)
        parallel_time = time.time() - start_time

        print(f"Sequential time: {sequential_time:.2f}s")
        print(f"Parallel time: {parallel_time:.2f}s")
        print(f"Speedup: {sequential_time / parallel_time:.2f}x")

        # Should be significantly faster
        if parallel_time < sequential_time * 0.7:  # At least 30% faster
            print("✅ Concurrent futures are working correctly!")
            return True
        else:
            print("⚠️ Concurrent futures not providing expected speedup")
            return False

    except Exception as e:
        print(f"❌ Concurrent futures test failed: {e}")
        return False


def main():
    """Run parallel monitoring tests"""
    print("🛰️ Sato Parallel Monitoring Tests")
    print("=" * 60)

    tests = [
        test_concurrent_futures,
        test_parallel_vs_sequential,
        test_batch_monitoring_simulation,
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
    print(f"🧪 Parallel monitoring tests completed: {passed}/{total} passed")

    if passed == total:
        print("🎉 Parallel monitoring is working efficiently!")
        print("💡 Status checking should now be much faster with parallel processing.")
        return 0
    else:
        print("⚠️ Some parallel monitoring tests failed.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
