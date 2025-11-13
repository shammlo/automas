#!/usr/bin/env python3
"""
Fix corrupted history.json file
"""

import json
import os
from pathlib import Path


def fix_history_file():
    """Fix or recreate corrupted history.json file"""
    history_file = Path(__file__).parent / "history.json"

    try:
        # Try to load existing file
        if history_file.exists():
            with open(history_file, "r") as f:
                data = json.load(f)
                print("✅ history.json is valid")
                return True
    except json.JSONDecodeError as e:
        print(f"❌ JSON error in history.json: {e}")
        print("🔧 Recreating history.json with clean structure...")
    except Exception as e:
        print(f"❌ Error reading history.json: {e}")
        print("🔧 Recreating history.json...")

    # Create clean history structure
    clean_history = {"events": [], "uptime_stats": {}, "response_times": {}}

    # Backup corrupted file if it exists
    if history_file.exists():
        backup_file = history_file.with_suffix(".json.backup")
        try:
            history_file.rename(backup_file)
            print(f"📁 Backed up corrupted file to {backup_file}")
        except Exception as e:
            print(f"⚠️ Could not backup file: {e}")

    # Write clean file
    try:
        with open(history_file, "w") as f:
            json.dump(clean_history, f, indent=2)
        print("✅ Created clean history.json file")
        return True
    except Exception as e:
        print(f"❌ Error creating history.json: {e}")
        return False


if __name__ == "__main__":
    print("🔧 Checking and fixing history.json...")
    success = fix_history_file()
    if success:
        print("🎉 history.json is ready!")
    else:
        print("❌ Failed to fix history.json")
