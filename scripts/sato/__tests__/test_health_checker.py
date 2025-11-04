#!/usr/bin/env python3
"""
Test Health Checker
"""

import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from core.health_checker import HealthChecker
from core.settings import ServerConfig, CheckType


def test_health_checker():
    """Test the health checker functionality"""
    print("🧪 Testing Health Checker...")

    checker = HealthChecker()
    print("✅ Health checker initialized")

    # Test HTTP check
    print("\n🌐 Testing HTTP checks...")

    # Test successful HTTP check
    http_server = ServerConfig(
        name="HTTPBin Test",
        host="https://httpbin.org/status/200",
        check_type=CheckType.HTTP,
        expected_status_codes=[200],
    )

    result = checker.check_http(http_server, timeout=10)
    print(
        f"   HTTPBin 200: {'✅' if result.is_healthy else '❌'} ({result.response_time}ms) - {result.message}"
    )
    if result.details:
        print(f"      Status Code: {result.details.get('status_code')}")

    # Test HTTP error handling
    http_error_server = ServerConfig(
        name="HTTPBin 404 Test",
        host="https://httpbin.org/status/404",
        check_type=CheckType.HTTP,
        expected_status_codes=[404],  # Expect 404 as valid
    )

    result = checker.check_http(http_error_server, timeout=10)
    print(
        f"   HTTPBin 404: {'✅' if result.is_healthy else '❌'} ({result.response_time}ms) - {result.message}"
    )

    # Test ping check
    print("\n🏓 Testing Ping checks...")

    ping_server = ServerConfig(
        name="Google Ping", host="8.8.8.8", check_type=CheckType.PING
    )

    result = checker.check_ping(ping_server, timeout=5)
    print(
        f"   Google DNS: {'✅' if result.is_healthy else '❌'} ({result.response_time}ms) - {result.message}"
    )

    # Test TCP check
    print("\n🔌 Testing TCP checks...")

    tcp_server = ServerConfig(
        name="Google DNS TCP", host="8.8.8.8", port=53, check_type=CheckType.TCP
    )

    result = checker.check_tcp(tcp_server, timeout=5)
    print(
        f"   Google DNS TCP: {'✅' if result.is_healthy else '❌'} ({result.response_time}ms) - {result.message}"
    )

    # Test custom check
    print("\n⚙️  Testing Custom checks...")

    custom_server = ServerConfig(
        name="Echo Test", host="localhost", check_type=CheckType.CUSTOM
    )
    # Add custom command as attribute
    custom_server.custom_command = ["echo", "Hello World"]

    result = checker.check_custom(custom_server, timeout=5)
    print(
        f"   Echo command: {'✅' if result.is_healthy else '❌'} ({result.response_time}ms) - {result.message}"
    )
    if result.details:
        print(f"      Output: {result.details.get('stdout')}")

    # Test internet connectivity
    print("\n🌍 Testing Internet connectivity...")
    has_internet = checker.check_internet_connectivity()
    print(f"   Internet: {'✅' if has_internet else '❌'}")

    # Test URL building
    print("\n🔗 Testing URL building...")

    test_configs = [
        ServerConfig(
            name="Full URL",
            host="https://example.com/api/health",
            check_type=CheckType.HTTP,
        ),
        ServerConfig(
            name="Host + Port", host="example.com", port=8080, check_type=CheckType.HTTP
        ),
        ServerConfig(
            name="HTTPS Default",
            host="example.com",
            port=443,
            check_type=CheckType.HTTP,
        ),
        ServerConfig(
            name="With Endpoint", host="example.com", port=80, check_type=CheckType.HTTP
        ),
    ]

    # Add custom endpoint to the last config
    test_configs[-1].custom_endpoint = "health"

    for config in test_configs:
        url = checker.build_url(config)
        print(f"   {config.name}: {url}")

    print("\n✅ All health checker tests completed!")


if __name__ == "__main__":
    test_health_checker()
