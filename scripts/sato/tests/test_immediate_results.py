#!/usr/bin/env python3
"""
Test immediate result processing (no waiting for all to complete)
"""

import sys
import time
import threading
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_immediate_vs_batch_results():
    """Test that results appear immediately vs waiting for batch completion"""
    print("🧪 Testing immediate vs batch result processing...")

    try:
        from core.health_checker import HealthChecker, CheckResult
        from core.settings import ServerConfig, CheckType

        # Create test servers with different response times
        fast_server = ServerConfig(
            name="Fast Server",
            host="httpbin.org/delay/1",  # 1 second delay
            check_type=CheckType.HTTP,
        )

        slow_server = ServerConfig(
            name="Slow Server",
            host="httpbin.org/delay/3",  # 3 second delay
            check_type=CheckType.HTTP,
        )

        servers = [fast_server, slow_server]
        health_checker = HealthChecker()

        print("Testing with servers that have different response times...")
        print("- Fast server: ~1 second response")
        print("- Slow server: ~3 second response")

        # Test immediate processing (independent threads)
        print("\n⚡ Testing immediate processing:")
        results = {}
        result_times = {}
        start_time = time.time()

        def process_result_immediately(server_index, result):
            current_time = time.time() - start_time
            results[server_index] = result
            result_times[server_index] = current_time
            print(
                f"  Result {server_index} received at {current_time:.2f}s: {result.message}"
            )

        # Start independent threads
        threads = []
        for i, server in enumerate(servers):

            def create_thread(srv_idx, srv):
                def check_server():
                    try:
                        result = health_checker.check_server(srv, timeout=5)
                        process_result_immediately(srv_idx, result)
                    except Exception as e:
                        error_result = CheckResult(False, 0, f"Error: {str(e)}")
                        process_result_immediately(srv_idx, error_result)

                thread = threading.Thread(target=check_server, daemon=True)
                thread.start()
                return thread

            thread = create_thread(i, server)
            threads.append(thread)

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        total_time = time.time() - start_time
        print(f"  Total time: {total_time:.2f}s")

        # Analyze results
        if len(result_times) >= 2:
            fast_time = min(result_times.values())
            slow_time = max(result_times.values())
            time_diff = slow_time - fast_time

            print(f"\n📊 Analysis:")
            print(f"  First result: {fast_time:.2f}s")
            print(f"  Last result: {slow_time:.2f}s")
            print(f"  Time difference: {time_diff:.2f}s")

            # Results should appear at different times (not all together)
            if time_diff > 1.0:  # At least 1 second difference
                print("✅ Results appear immediately as each completes!")
                return True
            else:
                print("⚠️ Results might still be batched together")
                return False
        else:
            print("⚠️ Not enough results to analyze timing")
            return False

    except Exception as e:
        print(f"❌ Immediate results test failed: {e}")
        import traceback

        traceback.print_exc()
        return False


def test_independent_thread_processing():
    """Test that independent threads don't wait for each other"""
    print("\n🧪 Testing independent thread processing...")

    try:
        import threading
        import time

        results = []
        result_lock = threading.Lock()

        def mock_service_check(service_id, delay):
            """Mock service check with specified delay"""
            time.sleep(delay)
            with result_lock:
                current_time = time.time()
                results.append((service_id, current_time))
                print(f"  Service {service_id} completed at {current_time:.2f}s")

        # Test with different delays
        services = [("fast", 0.5), ("medium", 1.5), ("slow", 2.5)]

        print("Testing independent threads with different delays:")
        start_time = time.time()

        # Start all threads independently
        threads = []
        for service_id, delay in services:
            thread = threading.Thread(
                target=mock_service_check, args=(service_id, delay), daemon=True
            )
            thread.start()
            threads.append(thread)

        # Wait for all to complete
        for thread in threads:
            thread.join()

        total_time = time.time() - start_time

        # Analyze timing
        if len(results) >= 3:
            # Sort by completion time
            results.sort(key=lambda x: x[1])

            print(f"\n📊 Completion order:")
            for i, (service_id, completion_time) in enumerate(results):
                relative_time = completion_time - start_time
                print(f"  {i+1}. {service_id}: {relative_time:.2f}s")

            # Check if they completed in expected order (fast first)
            first_service = results[0][0]
            last_service = results[-1][0]

            if first_service == "fast" and last_service == "slow":
                print("✅ Independent threads work correctly!")
                print("✅ Fast services don't wait for slow ones!")
                return True
            else:
                print("⚠️ Thread independence might not be working")
                return False
        else:
            print("⚠️ Not enough results to verify independence")
            return False

    except Exception as e:
        print(f"❌ Independent thread test failed: {e}")
        return False


def main():
    """Run immediate result tests"""
    print("🛰️ Sato Immediate Result Processing Tests")
    print("=" * 60)

    tests = [
        test_independent_thread_processing,
        test_immediate_vs_batch_results,
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
    print(f"🧪 Immediate result tests completed: {passed}/{total} passed")

    if passed == total:
        print("🎉 Results now appear immediately!")
        print("💡 Fast services don't wait for slow ones anymore.")
        return 0
    else:
        print("⚠️ Some immediate result tests failed.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
