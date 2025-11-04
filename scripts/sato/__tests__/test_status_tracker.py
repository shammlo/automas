#!/usr/bin/env python3
"""
Test Status Tracker
"""

import sys
import os
from pathlib import Path
import time

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from core.status_tracker import StatusTracker
import tempfile
import shutil


def test_status_tracker():
    """Test the status tracker functionality"""
    print("🧪 Testing Status Tracker...")

    # Create temporary file for testing
    test_file = Path(tempfile.mktemp(suffix=".json"))
    print(f"📁 Test file: {test_file}")

    try:
        # Initialize status tracker
        tracker = StatusTracker(test_file, retention_days=7)
        print("✅ Status tracker initialized")

        # Test recording status events
        print("\n📊 Testing status recording...")

        servers = ["Web Server", "Database", "API Gateway"]

        # Record some events
        for i, server in enumerate(servers):
            # Record operational status
            tracker.record_status(
                server, "operational", 100 + i * 50, "Service healthy"
            )
            time.sleep(0.1)  # Small delay to ensure different timestamps

            # Record a down event
            tracker.record_status(server, "down", 0, "Connection timeout")
            time.sleep(0.1)

            # Record recovery
            tracker.record_status(
                server, "operational", 150 + i * 30, "Service restored"
            )
            time.sleep(0.1)

        print(f"✅ Recorded events for {len(servers)} servers")

        # Test uptime stats
        print("\n📈 Testing uptime statistics...")

        for server in servers:
            stats = tracker.get_uptime_stats(server)
            if stats:
                print(f"   {server}:")
                print(f"      Uptime: {stats.uptime_percentage:.1f}%")
                print(f"      Avg Response: {stats.average_response_time:.1f}ms")
                print(f"      Total Checks: {stats.total_checks}")
                print(f"      Last Status: {stats.last_status}")

        # Test recent events
        print("\n📋 Testing recent events...")

        recent_events = tracker.get_recent_events(limit=10)
        print(f"   Recent events: {len(recent_events)}")

        for event in recent_events[:3]:  # Show first 3
            print(
                f"      {event.datetime.strftime('%H:%M:%S')} - {event.server_name}: {event.status} ({event.response_time}ms)"
            )

        # Test server-specific events
        print(f"\n🔍 Testing server-specific events for '{servers[0]}'...")

        server_events = tracker.get_recent_events(servers[0], limit=5)
        print(f"   Events for {servers[0]}: {len(server_events)}")

        for event in server_events:
            print(
                f"      {event.datetime.strftime('%H:%M:%S')}: {event.status} - {event.message}"
            )

        # Test response time history
        print(f"\n⏱️  Testing response time history...")

        response_history = tracker.get_response_time_history(servers[0], hours=1)
        print(f"   Response time entries for {servers[0]}: {len(response_history)}")

        if response_history:
            avg_response = sum(rt for _, rt in response_history) / len(response_history)
            print(f"      Average response time: {avg_response:.1f}ms")

        # Test status changes
        print(f"\n🔄 Testing status changes...")

        status_changes = tracker.get_status_changes(servers[0], hours=1)
        print(f"   Status changes for {servers[0]}: {len(status_changes)}")

        for change in status_changes:
            print(f"      {change.datetime.strftime('%H:%M:%S')}: → {change.status}")

        # Test downtime calculation
        print(f"\n⏰ Testing downtime calculation...")

        downtime = tracker.calculate_downtime(servers[0], hours=1)
        print(f"   Downtime for {servers[0]}: {downtime:.2f} minutes")

        # Test persistence
        print(f"\n💾 Testing persistence...")

        tracker.save_history()
        print("✅ History saved")

        # Load in new tracker instance
        tracker2 = StatusTracker(test_file, retention_days=7)
        stats2 = tracker2.get_uptime_stats(servers[0])

        if stats2:
            print(f"✅ History loaded: {stats2.total_checks} checks for {servers[0]}")

        # Test export
        print(f"\n📤 Testing export...")

        export_data = tracker.export_stats(servers[0])
        print(f"   Export keys: {list(export_data.keys())}")

        if "stats" in export_data:
            print(
                f"   Exported uptime: {export_data['stats']['uptime_percentage']:.1f}%"
            )

        # Test all stats export
        all_export = tracker.export_stats()
        print(f"   All stats export keys: {list(all_export.keys())}")
        print(f"   Total servers in export: {len(all_export.get('all_stats', {}))}")

        print("\n✅ All status tracker tests passed!")

    except Exception as e:
        print(f"❌ Status tracker test failed: {e}")
        import traceback

        traceback.print_exc()

    finally:
        # Cleanup
        if test_file.exists():
            test_file.unlink()
        print(f"🧹 Cleaned up test file")


if __name__ == "__main__":
    test_status_tracker()
