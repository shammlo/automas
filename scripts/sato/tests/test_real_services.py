#!/usr/bin/env python3
"""
Test real service connectivity
"""

import sys
import time
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))


def test_real_service_connectivity():
    """Test connectivity to actual configured services"""
    print("🧪 Testing real service connectivity...")

    try:
        from core.settings import SettingsManager
        from core.health_checker import HealthChecker

        config_dir = Path(__file__).parent.parent
        settings = SettingsManager(config_dir)
        checker = HealthChecker()

        print(f"Testing {len(settings.servers)} configured services...\n")

        results = []
        for i, server in enumerate(settings.servers):
            print(f"Testing {i+1}. {server.name}")
            print(f"  URL: {checker.build_url(server)}")
            print(f"  Expected codes: {server.expected_status_codes}")

            start_time = time.time()
            result = checker.check_server(server, timeout=10)  # Generous timeout
            check_time = time.time() - start_time

            print(f"  Result: {'✅ HEALTHY' if result.is_healthy else '❌ UNHEALTHY'}")
            print(f"  Message: {result.message}")
            print(f"  Response time: {result.response_time}ms")
            print(f"  Check time: {check_time:.2f}s")
            print()

            results.append(
                {
                    "name": server.name,
                    "healthy": result.is_healthy,
                    "message": result.message,
                    "response_time": result.response_time,
                }
            )

        # Summary
        healthy_count = sum(1 for r in results if r["healthy"])
        print(f"📊 Summary: {healthy_count}/{len(results)} services are healthy")

        if healthy_count == 0:
            print("⚠️ All services are failing - this might indicate:")
            print("  - Network connectivity issues")
            print("  - Services are actually down")
            print("  - Timeout too aggressive")
            print("  - Authentication required (401 might be expected)")

        return True

    except Exception as e:
        print(f"❌ Real service test failed: {e}")
        import traceback

        traceback.print_exc()
        return False


def main():
    """Run real service connectivity test"""
    print("🛰️ Sato Real Service Connectivity Test")
    print("=" * 60)

    test_real_service_connectivity()

    print("=" * 60)
    print("💡 If all services are failing, try:")
    print("  1. Check your internet connection")
    print("  2. Verify the service URLs are correct")
    print("  3. Check if the services require authentication")
    print("  4. Consider if 401 responses should be treated as healthy")


if __name__ == "__main__":
    main()
