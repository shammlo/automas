#!/usr/bin/env python3
"""
Notification System for Server Status Widget
"""

import subprocess
import threading
import time
import requests
from typing import Optional, Dict, Any, List
from pathlib import Path
from dataclasses import dataclass
from collections import defaultdict


@dataclass
class NotificationEvent:
    server_name: str
    old_status: str
    new_status: str
    timestamp: float
    response_time: int = 0
    message: str = ""


class NotificationManager:
    def __init__(self, settings):
        self.settings = settings
        self.last_notifications: Dict[str, float] = {}  # Prevent spam
        self.notification_cooldown = 60  # seconds

        # Enhanced notification features
        self.pending_notifications: List[NotificationEvent] = []
        self.notification_lock = threading.Lock()
        self.batch_timer = None
        self.batch_delay = 5  # seconds to wait before sending grouped notification

        # Smart rules tracking
        self.last_meaningful_status: Dict[str, str] = {}
        self.status_change_history: Dict[str, List[Dict]] = defaultdict(list)

        # Cooldown tracking
        self.last_notification_time: Dict[str, float] = {}
        self.cooldown_period = getattr(settings, "alert_cooldown_seconds", 300)

        # Check if notification system is available
        self.desktop_available = self.check_desktop_notifications()
        self.sound_available = self.check_sound_system()

    def check_desktop_notifications(self) -> bool:
        """Check if desktop notifications are available"""
        try:
            # Try notify-send (Linux)
            result = subprocess.run(
                ["which", "notify-send"], capture_output=True, text=True
            )
            if result.returncode == 0:
                return True

            # Try osascript (macOS)
            result = subprocess.run(
                ["which", "osascript"], capture_output=True, text=True
            )
            if result.returncode == 0:
                return True

            return False
        except:
            return False

    def check_sound_system(self) -> bool:
        """Check if sound system is available"""
        try:
            # Try paplay (PulseAudio - Linux)
            result = subprocess.run(["which", "paplay"], capture_output=True, text=True)
            if result.returncode == 0:
                return True

            # Try afplay (macOS)
            result = subprocess.run(["which", "afplay"], capture_output=True, text=True)
            if result.returncode == 0:
                return True

            return False
        except:
            return False

    def should_notify(self, server_name: str, notification_type: str) -> bool:
        """Check if we should send a notification (rate limiting)"""
        key = f"{server_name}_{notification_type}"
        current_time = time.time()

        if key in self.last_notifications:
            if current_time - self.last_notifications[key] < self.notification_cooldown:
                return False

        self.last_notifications[key] = current_time
        return True

    def notify_status_change(
        self,
        server_name: str,
        old_status: str,
        new_status: str,
        response_time: int = 0,
        message: str = "",
    ):
        """Enhanced notification with grouping and smart rules"""
        if not self.settings.notify_on_status_change:
            return

        # Use enhanced notifications if enabled
        if getattr(self.settings, "enhanced_notifications", True):
            return self._notify_status_change_enhanced(
                server_name, old_status, new_status, response_time, message
            )

        # Fallback to original behavior
        return self._notify_status_change_original(
            server_name, old_status, new_status, response_time, message
        )

    def _notify_status_change_enhanced(
        self,
        server_name: str,
        old_status: str,
        new_status: str,
        response_time: int = 0,
        message: str = "",
    ):
        """Enhanced notification with grouping and smart rules"""

        # Apply smart rules first
        if not self._should_notify_smart(server_name, old_status, new_status):
            return

        # Create notification event
        event = NotificationEvent(
            server_name=server_name,
            old_status=old_status,
            new_status=new_status,
            timestamp=time.time(),
            response_time=response_time,
            message=message,
        )

        # Add to pending notifications for grouping
        with self.notification_lock:
            self.pending_notifications.append(event)

            # Start or reset batch timer
            if self.batch_timer:
                self.batch_timer.cancel()

            self.batch_timer = threading.Timer(
                self.batch_delay, self._send_grouped_notifications
            )
            self.batch_timer.start()

    def _notify_status_change_original(
        self,
        server_name: str,
        old_status: str,
        new_status: str,
        response_time: int = 0,
        message: str = "",
    ):
        """Original notification behavior"""
        if not self.should_notify(server_name, "status_change"):
            return

        # Determine notification urgency and icon
        if new_status == "operational":
            urgency = "normal"
            icon = "✅"
            title = f"Service Restored: {server_name}"
            body = f"Service is now operational"
            if response_time > 0:
                body += f" ({response_time}ms)"
        elif new_status == "down":
            urgency = "critical"
            icon = "❌"
            title = f"Service Down: {server_name}"
            body = f"Service is not responding"
            if message:
                body += f"\n{message}"
        else:  # degraded
            urgency = "normal"
            icon = "⚠️"
            title = f"Service Issues: {server_name}"
            body = f"Service is experiencing issues"
            if message:
                body += f"\n{message}"

        # Send desktop notification
        if self.settings.desktop_notifications:
            self.send_desktop_notification(title, body, urgency, icon)

        # Play sound alert
        if self.settings.sound_alerts:
            self.play_sound_alert(new_status)

        # Send webhook notification
        if self.settings.webhook_url:
            self.send_webhook_notification(
                server_name, old_status, new_status, response_time, message
            )

    def send_grouped_notification(
        self, group_title: str, message: str, status: str, service_count: int
    ):
        """Send grouped notification for multiple services"""
        if not self.settings.desktop_notifications:
            return

        # Determine urgency and icon based on status
        if status == "operational":
            urgency = "normal"
            icon = "✅"
        elif status == "down":
            urgency = "critical"
            icon = "❌"
        else:  # degraded
            urgency = "normal"
            icon = "⚠️"

        # Send desktop notification
        self.send_desktop_notification(group_title, message, urgency, icon)

        # Play sound alert for critical grouped alerts
        if status == "down" and self.settings.sound_alerts:
            self.play_sound_alert(status)

        print(f"📢 Sent grouped notification: {group_title} - {message}")

    def notify_slow_response(
        self, server_name: str, response_time: int, threshold: int
    ):
        """Send notification for slow response time"""
        if not self.settings.notify_on_slow_response:
            return

        if not self.should_notify(server_name, "slow_response"):
            return

        title = f"Slow Response: {server_name}"
        body = f"Response time: {response_time}ms (threshold: {threshold}ms)"

        if self.settings.desktop_notifications:
            self.send_desktop_notification(title, body, "normal", "⏱️")

    def send_desktop_notification(
        self, title: str, body: str, urgency: str = "normal", icon: str = ""
    ):
        """Send desktop notification"""
        if not self.desktop_available:
            return

        def send_notification():
            try:
                # Linux (notify-send)
                result = subprocess.run(
                    ["which", "notify-send"], capture_output=True, text=True
                )
                if result.returncode == 0:
                    cmd = [
                        "notify-send",
                        "--urgency",
                        urgency,
                        "--expire-time",
                        str(self.settings.notification_timeout),
                        "--app-name",
                        "Server Monitor",
                        f"{icon} {title}" if icon else title,
                        body,
                    ]
                    subprocess.run(cmd, capture_output=True)
                    return

                # macOS (osascript)
                result = subprocess.run(
                    ["which", "osascript"], capture_output=True, text=True
                )
                if result.returncode == 0:
                    script = f"""
                    display notification "{body}" with title "{icon} {title}" sound name "default"
                    """
                    subprocess.run(["osascript", "-e", script], capture_output=True)
                    return

            except Exception as e:
                print(f"Error sending desktop notification: {e}")

        # Send notification in background thread
        threading.Thread(target=send_notification, daemon=True).start()

    def play_sound_alert(self, status: str):
        """Play sound alert based on status"""
        if not self.sound_available:
            return

        def play_sound():
            try:
                # Determine sound file based on status
                sound_file = None
                if status == "operational":
                    sound_file = (
                        "/usr/share/sounds/alsa/Front_Left.wav"  # Success sound
                    )
                elif status == "down":
                    sound_file = "/usr/share/sounds/alsa/Front_Right.wav"  # Error sound

                if not sound_file or not Path(sound_file).exists():
                    # Fallback to system beep
                    subprocess.run(
                        ["pactl", "upload-sample", "/dev/stdin", "beep"],
                        input=b"\x07",
                        capture_output=True,
                    )
                    return

                # Linux (paplay)
                result = subprocess.run(
                    ["which", "paplay"], capture_output=True, text=True
                )
                if result.returncode == 0:
                    subprocess.run(["paplay", sound_file], capture_output=True)
                    return

                # macOS (afplay)
                result = subprocess.run(
                    ["which", "afplay"], capture_output=True, text=True
                )
                if result.returncode == 0:
                    subprocess.run(["afplay", sound_file], capture_output=True)
                    return

            except Exception as e:
                print(f"Error playing sound alert: {e}")

        # Play sound in background thread
        threading.Thread(target=play_sound, daemon=True).start()

    def send_webhook_notification(
        self,
        server_name: str,
        old_status: str,
        new_status: str,
        response_time: int,
        message: str,
    ):
        """Send webhook notification"""
        if not self.settings.webhook_url:
            return

        def send_webhook():
            try:
                payload = {
                    "server_name": server_name,
                    "old_status": old_status,
                    "new_status": new_status,
                    "response_time": response_time,
                    "message": message,
                    "timestamp": time.time(),
                }

                # Format for Slack/Discord if URL contains those domains
                if "slack.com" in self.settings.webhook_url:
                    payload = self.format_slack_message(
                        server_name, old_status, new_status, response_time, message
                    )
                elif "discord.com" in self.settings.webhook_url:
                    payload = self.format_discord_message(
                        server_name, old_status, new_status, response_time, message
                    )

                response = requests.post(
                    self.settings.webhook_url,
                    json=payload,
                    timeout=10,
                    headers={"Content-Type": "application/json"},
                )
                response.raise_for_status()

            except Exception as e:
                print(f"Error sending webhook notification: {e}")

        # Send webhook in background thread
        threading.Thread(target=send_webhook, daemon=True).start()

    def format_slack_message(
        self,
        server_name: str,
        old_status: str,
        new_status: str,
        response_time: int,
        message: str,
    ) -> dict:
        """Format message for Slack webhook"""
        color = "good" if new_status == "operational" else "danger"

        return {
            "attachments": [
                {
                    "color": color,
                    "title": f"Server Status Change: {server_name}",
                    "fields": [
                        {
                            "title": "Status",
                            "value": f"{old_status} → {new_status}",
                            "short": True,
                        },
                        {
                            "title": "Response Time",
                            "value": (
                                f"{response_time}ms" if response_time > 0 else "N/A"
                            ),
                            "short": True,
                        },
                    ],
                    "text": message if message else "",
                    "ts": int(time.time()),
                }
            ]
        }

    def format_discord_message(
        self,
        server_name: str,
        old_status: str,
        new_status: str,
        response_time: int,
        message: str,
    ) -> dict:
        """Format message for Discord webhook"""
        color = 0x00FF00 if new_status == "operational" else 0xFF0000

        return {
            "embeds": [
                {
                    "title": f"Server Status Change: {server_name}",
                    "color": color,
                    "fields": [
                        {
                            "name": "Status",
                            "value": f"{old_status} → {new_status}",
                            "inline": True,
                        },
                        {
                            "name": "Response Time",
                            "value": (
                                f"{response_time}ms" if response_time > 0 else "N/A"
                            ),
                            "inline": True,
                        },
                    ],
                    "description": message if message else "",
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                }
            ]
        }

    def test_notifications(self):
        """Test all notification methods"""
        print("Testing notification systems...")

        if self.desktop_available:
            self.send_desktop_notification(
                "Server Monitor Test",
                "Desktop notifications are working!",
                "normal",
                "🧪",
            )
            print("✅ Desktop notification sent")
        else:
            print("❌ Desktop notifications not available")

        if self.sound_available and self.settings.sound_alerts:
            self.play_sound_alert("operational")
            print("✅ Sound alert played")
        else:
            print("❌ Sound alerts not available or disabled")

        if self.settings.webhook_url:
            self.send_webhook_notification(
                "Test Server", "unknown", "operational", 123, "Test notification"
            )
            print("✅ Webhook notification sent")
        else:
            print("❌ Webhook not configured")

    # Enhanced Notification Methods

    def _should_notify_smart(
        self, server_name: str, old_status: str, new_status: str
    ) -> bool:
        """Smart rules: only notify on meaningful changes"""

        # Rule 1: Skip if status didn't actually change
        if old_status == new_status:
            return False

        # Rule 2: Skip "checking" status changes (internal state)
        if old_status == "checking" or new_status == "checking":
            return False

        # Rule 3: Check if this is a meaningful change
        last_meaningful = self.last_meaningful_status.get(server_name)

        # If this is the same as the last meaningful status, skip
        if last_meaningful == new_status:
            return False

        # Rule 4: Flap detection - too many changes recently
        if self._is_flapping(server_name, new_status):
            print(f"🔄 Suppressing notification for flapping service: {server_name}")
            return False

        # Rule 5: Cooldown - don't spam same service
        if self._is_in_cooldown(server_name):
            return False

        # This is a meaningful change, update tracking
        self.last_meaningful_status[server_name] = new_status
        self._record_status_change(server_name, new_status)

        return True

    def _is_flapping(self, server_name: str, new_status: str) -> bool:
        """Detect if service is flapping (too many status changes)"""
        current_time = time.time()
        history = self.status_change_history[server_name]

        # Keep only last 10 minutes of history
        history = [
            change for change in history if current_time - change["timestamp"] < 600
        ]
        self.status_change_history[server_name] = history

        # If more than 3 changes in 10 minutes, consider flapping
        return len(history) > 3

    def _is_in_cooldown(self, server_name: str) -> bool:
        """Check if service is in notification cooldown"""
        last_time = self.last_notification_time.get(server_name, 0)
        return time.time() - last_time < self.cooldown_period

    def _record_status_change(self, server_name: str, new_status: str):
        """Record status change for flap detection"""
        current_time = time.time()
        self.status_change_history[server_name].append(
            {"status": new_status, "timestamp": current_time}
        )
        self.last_notification_time[server_name] = current_time

    def _send_grouped_notifications(self):
        """Send grouped notifications for batched events"""
        with self.notification_lock:
            if not self.pending_notifications:
                return

            events = self.pending_notifications.copy()
            self.pending_notifications.clear()

        # Group events by type
        failures = [e for e in events if e.new_status == "down"]
        recoveries = [e for e in events if e.new_status == "operational"]
        degraded = [e for e in events if e.new_status == "degraded"]

        # Send grouped notifications
        if failures:
            self._send_failure_group_notification(failures)

        if recoveries:
            self._send_recovery_group_notification(recoveries)

        if degraded:
            self._send_degraded_group_notification(degraded)

    def _send_failure_group_notification(self, failures: List[NotificationEvent]):
        """Send grouped notification for service failures"""
        count = len(failures)

        if count == 1:
            # Single failure
            event = failures[0]
            title = f"🚨 Service Down: {event.server_name}"
            body = f"Service is not responding"
            if event.message:
                body += f"\n{event.message}"
        else:
            # Multiple failures
            service_names = [e.server_name for e in failures]
            if count <= 3:
                names_str = ", ".join(service_names)
            else:
                names_str = f"{', '.join(service_names[:2])}, +{count-2} more"

            title = f"🚨 {count} Services Down"
            body = f"Services not responding: {names_str}"

        # Send notification
        if self.settings.desktop_notifications:
            self.send_desktop_notification(title, body, "critical", "🚨")

        # Play sound for failures
        if self.settings.sound_alerts:
            self.play_sound_alert("down")

    def _send_recovery_group_notification(self, recoveries: List[NotificationEvent]):
        """Send grouped notification for service recoveries"""
        count = len(recoveries)

        if count == 1:
            # Single recovery
            event = recoveries[0]
            title = f"✅ Service Restored: {event.server_name}"
            body = f"Service is operational"
            if event.response_time > 0:
                body += f" ({event.response_time}ms)"
        else:
            # Multiple recoveries
            service_names = [e.server_name for e in recoveries]
            if count <= 3:
                names_str = ", ".join(service_names)
            else:
                names_str = f"{', '.join(service_names[:2])}, +{count-2} more"

            title = f"✅ {count} Services Restored"
            body = f"Services operational: {names_str}"

        # Send notification
        if self.settings.desktop_notifications:
            self.send_desktop_notification(title, body, "normal", "✅")

    def _send_degraded_group_notification(self, degraded: List[NotificationEvent]):
        """Send grouped notification for degraded services"""
        count = len(degraded)

        if count == 1:
            # Single degraded service
            event = degraded[0]
            title = f"⚠️ Service Issues: {event.server_name}"
            body = f"Service experiencing issues"
            if event.message:
                body += f"\n{event.message}"
        else:
            # Multiple degraded services
            service_names = [e.server_name for e in degraded]
            if count <= 3:
                names_str = ", ".join(service_names)
            else:
                names_str = f"{', '.join(service_names[:2])}, +{count-2} more"

            title = f"⚠️ {count} Services Degraded"
            body = f"Services with issues: {names_str}"

        # Send notification
        if self.settings.desktop_notifications:
            self.send_desktop_notification(title, body, "normal", "⚠️")

    def force_send_pending(self):
        """Force send any pending notifications (for shutdown)"""
        if self.batch_timer:
            self.batch_timer.cancel()
        self._send_grouped_notifications()

    def get_notification_stats(self) -> Dict:
        """Get statistics about notification behavior"""
        return {
            "pending_count": len(self.pending_notifications),
            "tracked_services": len(self.last_meaningful_status),
            "flapping_services": [
                name
                for name, history in self.status_change_history.items()
                if len(history) > 3
            ],
            "cooldown_services": [
                name
                for name, last_time in self.last_notification_time.items()
                if time.time() - last_time < self.cooldown_period
            ],
        }
