#!/usr/bin/env python3
"""
Sato Configuration Repair Utility
Fixes common configuration errors and compatibility issues
"""

import json
import os


def fix_config_errors():
    """Fix configuration errors that prevent Sato from starting"""

    print("🔧 Fixing Sato configuration errors...")

    # Fix 1: Clean up config.json - remove unsupported fields
    config_path = "config/config.json"
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            config = json.load(f)

        fixed_count = 0
        for server in config:
            # Remove auto_restart and restart_command (not supported yet)
            if "auto_restart" in server:
                del server["auto_restart"]
                fixed_count += 1
            if "restart_command" in server:
                del server["restart_command"]
                fixed_count += 1

        if fixed_count > 0:
            with open(config_path, "w") as f:
                json.dump(config, f, indent=2)
            print(f"✅ Removed {fixed_count} unsupported config fields")

    # Fix 2: Clean up settings.json - remove unsupported fields
    settings_path = "config/settings.json"
    if os.path.exists(settings_path):
        with open(settings_path, "r") as f:
            settings = json.load(f)

        # Remove unsupported monitoring fields
        monitoring = settings.get("monitoring", {})
        removed_fields = []

        unsupported_fields = [
            "flap_detection_threshold",
            "flap_detection_window",
            "min_failure_duration",
        ]
        for field in unsupported_fields:
            if field in monitoring:
                del monitoring[field]
                removed_fields.append(field)

        # Remove unsupported notification fields
        notifications = settings.get("notifications", {})
        unsupported_notif_fields = [
            "group_similar_alerts",
            "alert_cooldown_seconds",
            "suppress_flapping_alerts",
        ]
        for field in unsupported_notif_fields:
            if field in notifications:
                del notifications[field]
                removed_fields.append(field)

        # Keep the increased check interval (this is supported)
        monitoring["global_check_interval"] = 30

        if removed_fields:
            with open(settings_path, "w") as f:
                json.dump(settings, f, indent=2)
            print(f"✅ Removed unsupported settings: {', '.join(removed_fields)}")

    print("\n🎯 Configuration cleaned up:")
    print("  • Removed unsupported auto_restart fields")
    print("  • Removed unsupported monitoring fields")
    print("  • Kept 30-second check interval")
    print("  • Sato should now start without errors")

    print("\n🚀 Next steps:")
    print("  1. Restart Sato - no more config errors")
    print("  2. External APIs will be monitored (no restart attempts)")
    print("  3. Use Ctrl+X for maintenance mode")
    print("  4. Docker services will still auto-restart")


if __name__ == "__main__":
    fix_config_errors()
