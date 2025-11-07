# Server Monitor Component Tests

This directory contains individual tests for each component of the enhanced server monitor.

## Test Files

- **`test_settings.py`** - Tests the settings management system
- **`test_health_checker.py`** - Tests the enhanced health checking with different check types
- **`test_status_tracker.py`** - Tests status history and uptime tracking
- **`test_notifications.py`** - Tests desktop notifications and webhook integration
- **`test_system_tray.py`** - Tests system tray integration (requires GUI)
- **`run_all_tests.py`** - Runs all tests in sequence

## Running Tests

### Run All Tests

```bash
cd serverChecker/__tests__
python3 run_all_tests.py
```

### Run Individual Tests

```bash
# Test settings management
python3 test_settings.py

# Test health checker
python3 test_health_checker.py

# Test status tracking
python3 test_status_tracker.py

# Test notifications
python3 test_notifications.py

# Test system tray (requires GUI)
python3 test_system_tray.py
```

## Requirements

### Python Packages

- `gi` (PyGObject) - For GTK integration
- `requests` - For webhook notifications

### System Dependencies

- `notify-send` - For desktop notifications (Linux)
- `ping` - For network ping tests
- GUI environment - For system tray tests

### Installation

```bash
# Ubuntu/Debian
sudo apt install python3-gi python3-requests libnotify-bin

# Install Python packages if not available via system packages
pip3 install PyGObject requests
```

## Test Details

### Settings Test

- Tests configuration loading/saving
- Tests server grouping
- Tests settings persistence
- Creates temporary files (auto-cleaned)

### Health Checker Test

- Tests HTTP/HTTPS checks
- Tests ping functionality
- Tests TCP socket connections
- Tests custom command execution
- Tests URL building and parsing

### Status Tracker Test

- Tests event recording
- Tests uptime calculations
- Tests response time tracking
- Tests data persistence
- Tests export functionality

### Notifications Test

- Tests desktop notification availability
- Tests rate limiting
- Tests webhook formatting (Slack/Discord)
- Sends actual desktop notifications (if available)
- Tests notification system detection

### System Tray Test

- Tests tray icon creation
- Tests menu functionality
- Tests status updates
- Requires GUI environment
- Interactive test (30-second timeout)

## Expected Output

Each test will show:

- ✅ Success indicators for passing tests
- ❌ Error indicators for failing tests
- 📊 Statistics and data from tests
- 🧹 Cleanup confirmation

The test runner will provide a summary of all test results.

## Troubleshooting

### Common Issues

1. **Missing PyGObject**: Install `python3-gi` or `PyGObject`
2. **No desktop notifications**: Install `libnotify-bin` (Linux)
3. **System tray test fails**: Ensure you're in a GUI environment
4. **Network tests fail**: Check internet connectivity
5. **Permission errors**: Ensure write access to temp directories

### Debug Mode

Add debug prints or run tests individually to isolate issues.

### Manual Testing

Some tests (notifications, system tray) include manual verification steps. Follow the on-screen instructions during test execution.
