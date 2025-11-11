#!/usr/bin/env python3
"""
Sato Flap Detection Optimizer
Optimizes monitoring intervals and reduces alert spam from flapping services
"""

import json
import os


def apply_final_fixes():
    """Apply all fixes to stop flapping and alert spam"""

    print("🔧 Applying final fixes for flapping services...")

    # Fix 1: Update config with proper service-specific intervals
    config_path = "config/config.json"
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            config = json.load(f)

        for server in config:
            # Set longer intervals for external APIs
            if any(
                domain in server.get("host", "")
                for domain in ["nass.iq", "cardhouzz.online"]
            ):
                server["check_interval"] = 120  # 2 minutes for external APIs
                server["timeout"] = 10  # Longer timeout
                print(f"  ✅ Set 2-minute interval for external API: {server['name']}")
            else:
                # Default interval for other services
                if "check_interval" not in server:
                    server["check_interval"] = 30

        with open(config_path, "w") as f:
            json.dump(config, f, indent=2)

    # Fix 2: Optimize settings for stability
    settings_path = "config/settings.json"
    if os.path.exists(settings_path):
        with open(settings_path, "r") as f:
            settings = json.load(f)

        # Monitoring optimizations
        settings["monitoring"]["global_check_interval"] = 60  # 1 minute default
        settings["monitoring"]["max_response_time_warning"] = 3000  # 3 seconds
        settings["monitoring"]["max_response_time_critical"] = 8000  # 8 seconds

        # Notification optimizations
        settings["notifications"][
            "notify_on_status_change"
        ] = True  # Re-enable but with flap detection
        settings["notifications"]["desktop_notifications"] = True
        settings["notifications"]["notification_timeout"] = 8000  # Longer timeout

        with open(settings_path, "w") as f:
            json.dump(settings, f, indent=2)

        print("✅ Optimized monitoring and notification settings")

    print("\n🎯 Final fixes applied:")
    print("  • External APIs: 2-minute check intervals")
    print("  • Local services: 30-second intervals")
    print("  • Global default: 1-minute intervals")
    print("  • Increased timeout thresholds")
    print("  • Re-enabled notifications with flap detection")

    print("\n🚀 Next steps:")
    print("  1. Restart Sato to apply all changes")
    print("  2. Monitor for 10 minutes to verify stability")
    print("  3. Flap detection will suppress rapid changes")
    print("  4. Use Ctrl+X for maintenance mode if needed")


def show_current_config():
    """Show current configuration for verification"""
    print("📋 Current Configuration:")

    config_path = "config/config.json"
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            config = json.load(f)

        for server in config:
            interval = server.get("check_interval", "default")
            timeout = server.get("timeout", "default")
            print(f"  • {server['name']}: {interval}s interval, {timeout}s timeout")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "show":
        show_current_config()
    else:
        apply_final_fixes()
