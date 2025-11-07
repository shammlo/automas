#!/usr/bin/env python3
"""
Run All Component Tests
"""

import sys
import os
import subprocess
from pathlib import Path
import time


def run_test(test_file: Path, description: str) -> bool:
    """Run a single test file and return success status"""
    print(f"\n{'='*60}")
    print(f"🧪 Running {description}")
    print(f"{'='*60}")

    try:
        # Run the test
        result = subprocess.run(
            [sys.executable, str(test_file)],
            capture_output=False,
            text=True,
            timeout=60,
        )

        if result.returncode == 0:
            print(f"✅ {description} - PASSED")
            return True
        else:
            print(f"❌ {description} - FAILED (exit code: {result.returncode})")
            return False

    except subprocess.TimeoutExpired:
        print(f"⏰ {description} - TIMEOUT (60s)")
        return False
    except Exception as e:
        print(f"❌ {description} - ERROR: {e}")
        return False


def check_dependencies():
    """Check if required dependencies are available"""
    print("🔍 Checking dependencies...")

    dependencies = {
        "gi": "PyGObject (for GTK)",
        "requests": "Requests (for webhooks)",
    }

    missing = []

    for module, description in dependencies.items():
        try:
            __import__(module)
            print(f"   ✅ {description}")
        except ImportError:
            print(f"   ❌ {description} - MISSING")
            missing.append(description)

    # Check system commands
    system_commands = {
        "notify-send": "Desktop notifications (Linux)",
        "ping": "Network ping",
    }

    for command, description in system_commands.items():
        result = subprocess.run(["which", command], capture_output=True)
        if result.returncode == 0:
            print(f"   ✅ {description}")
        else:
            print(f"   ⚠️  {description} - Not available (some tests may be limited)")

    if missing:
        print(f"\n⚠️  Missing dependencies: {', '.join(missing)}")
        print("   Some tests may fail. Install missing packages if needed.")
        return False

    return True


def main():
    """Run all component tests"""
    print("🚀 Server Monitor Component Test Suite")
    print("=" * 60)

    # Check dependencies first
    deps_ok = check_dependencies()

    if not deps_ok:
        print("\n❓ Continue with missing dependencies? (y/N): ", end="")
        if input().lower() != "y":
            print("Exiting...")
            return

    # Define tests to run
    test_dir = Path(__file__).parent
    tests = [
        (test_dir / "test_settings.py", "Settings Manager"),
        (test_dir / "test_health_checker.py", "Health Checker"),
        (test_dir / "test_status_tracker.py", "Status Tracker"),
        (test_dir / "test_notifications.py", "Notification System"),
    ]

    # Check if GUI is available for system tray test
    if os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"):
        tests.append((test_dir / "test_system_tray.py", "System Tray Integration"))
    else:
        print("\n⚠️  No GUI environment detected. Skipping system tray test.")

    # Run tests
    results = []
    start_time = time.time()

    for test_file, description in tests:
        if not test_file.exists():
            print(f"❌ Test file not found: {test_file}")
            results.append((description, False))
            continue

        success = run_test(test_file, description)
        results.append((description, success))

        # Small delay between tests
        time.sleep(1)

    # Summary
    total_time = time.time() - start_time
    passed = sum(1 for _, success in results if success)
    total = len(results)

    print(f"\n{'='*60}")
    print(f"📊 TEST SUMMARY")
    print(f"{'='*60}")

    for description, success in results:
        status = "✅ PASSED" if success else "❌ FAILED"
        print(f"   {description:<30} {status}")

    print(f"\n📈 Results: {passed}/{total} tests passed")
    print(f"⏱️  Total time: {total_time:.1f} seconds")

    if passed == total:
        print(f"\n🎉 All tests passed! Components are ready for integration.")
        return 0
    else:
        print(f"\n⚠️  Some tests failed. Review the output above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
