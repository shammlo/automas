#!/usr/bin/env python3
"""
Test Notifications System
"""

import sys
import os
from pathlib import Path
import time

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from core.notifications import NotificationManager
from core.settings import NotificationSettings


def test_notifications():
    """Test the notification system functionality"""
    print("🧪 Testing Notification System...")

    # Create test settings
    settings = NotificationSettings(
        desktop_notifications=True,
        sound_alerts=False,  # Disable sound for testing
        notify_on_status_change=True,
        notify_on_slow_response=True,
        notification_timeout=3000,
    )

    # Initialize notification manager
    notifier = NotificationManager(settings)
    print("✅ Notification manager initialized")

    # Test system availability
    print(
        f"\n🖥️  Desktop notifications available: {'✅' if notifier.desktop_available else '❌'}"
    )
    print(f"🔊 Sound system available: {'✅' if notifier.sound_available else '❌'}")

    # Test notification rate limiting
    print(f"\n⏱️  Testing rate limiting...")

    server_name = "Test Server"

    # First notification should go through
    should_notify1 = notifier.should_notify(server_name, "status_change")
    print(f"   First notification: {'✅' if should_notify1 else '❌'}")

    # Immediate second notification should be blocked
    should_notify2 = notifier.should_notify(server_name, "status_change")
    print(
        f"   Immediate second notification: {'❌' if not should_notify2 else '✅ (unexpected)'}"
    )

    # Different notification type should go through
    should_notify3 = notifier.should_notify(server_name, "slow_response")
    print(f"   Different type notification: {'✅' if should_notify3 else '❌'}")

    # Test status change notifications
    print(f"\n🔄 Testing status change notifications...")

    if notifier.desktop_available:
        print("   Sending test notifications (you should see desktop notifications)...")

        # Service down notification
        notifier.notify_status_change(
            "Web Server", "operational", "down", 0, "Connection timeout"
        )
        print("   📤 Sent 'service down' notification")
        time.sleep(2)

        # Service restored notification
        notifier.notify_status_change(
            "Web Server", "down", "operational", 150, "Service restored"
        )
        print("   📤 Sent 'service restored' notification")
        time.sleep(2)

        # Service degraded notification
        notifier.notify_status_change(
            "Database", "operational", "degraded", 2500, "High response time"
        )
        print("   📤 Sent 'service degraded' notification")
        time.sleep(2)
    else:
        print("   ⚠️  Desktop notifications not available, skipping visual tests")

    # Test slow response notification
    print(f"\n⏱️  Testing slow response notifications...")

    if notifier.desktop_available:
        notifier.notify_slow_response("API Gateway", 3000, 1000)
        print("   📤 Sent 'slow response' notification")
        time.sleep(2)

    # Test webhook formatting (without actually sending)
    print(f"\n🪝 Testing webhook formatting...")

    # Test Slack formatting
    slack_payload = notifier.format_slack_message(
        "Test Service", "operational", "down", 0, "Test message"
    )
    print("   Slack format:")
    print(f"      Color: {slack_payload['attachments'][0]['color']}")
    print(f"      Title: {slack_payload['attachments'][0]['title']}")
    print(f"      Fields: {len(slack_payload['attachments'][0]['fields'])}")

    # Test Discord formatting
    discord_payload = notifier.format_discord_message(
        "Test Service", "operational", "down", 0, "Test message"
    )
    print("   Discord format:")
    print(f"      Color: {discord_payload['embeds'][0]['color']}")
    print(f"      Title: {discord_payload['embeds'][0]['title']}")
    print(f"      Fields: {len(discord_payload['embeds'][0]['fields'])}")

    # Test notification system test
    print(f"\n🧪 Running notification system test...")
    notifier.test_notifications()

    print(f"\n✅ All notification tests completed!")

    # Instructions for manual testing
    print(f"\n📋 Manual Testing Instructions:")
    print(f"   1. Check if you received desktop notifications during the test")
    print(f"   2. Notifications should have appeared with different icons:")
    print(f"      - ❌ for service down")
    print(f"      - ✅ for service restored")
    print(f"      - ⚠️ for service degraded")
    print(f"      - ⏱️ for slow response")
    print(f"   3. If you want to test webhooks, add a webhook URL to settings")

    # Test enhanced notifications
    print(f"\n🔔 Testing enhanced notification features...")

    # Test grouping
    print("  Testing notification grouping...")
    notifier.notify_status_change("Service A", "operational", "down")
    notifier.notify_status_change("Service B", "operational", "down")
    notifier.notify_status_change("Service C", "operational", "down")

    # Wait for grouping
    import time

    time.sleep(6)

    # Test smart rules
    print("  Testing smart rules (should suppress repeated states)...")
    notifier.notify_status_change("Service A", "down", "down")  # Should be suppressed

    # Test flap detection
    print("  Testing flap detection...")
    for i in range(5):
        status = "down" if i % 2 == 0 else "operational"
        notifier.notify_status_change(
            "Flapping Service", "operational" if status == "down" else "down", status
        )

    # Show stats
    if hasattr(notifier, "get_notification_stats"):
        stats = notifier.get_notification_stats()
        print(f"  Enhanced notification stats: {stats}")

    print(f"\n🎉 Enhanced notification tests completed!")


if __name__ == "__main__":
    test_notifications()
