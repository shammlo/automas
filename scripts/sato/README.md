# 🛰️ Sato Enhanced Monitoring System

**Advanced infrastructure monitoring with self-healing capabilities.**

_Like having a digital doctor for your servers - but one that actually knows what it's doing and doesn't charge by the hour._

## 🚀 Quick Start

```bash
./sato
# or
python3 sato.py
```

## ✨ Advanced Features

### 🔄 **Auto-Restart Failed Services**

- Automatically attempts to restart failed services (because turning it off and on again really does work)
- Intelligent exponential backoff (30s, 1m, 2m, 5m) - gets progressively more patient, unlike your users
- Maximum 3 restart attempts per service (after that, it's time to call a human)
- Supports Docker containers and systemd services (the good, the bad, and the systemd)

### 🧠 **Intelligent Retry Logic**

- Tracks failure patterns and frequencies (like a detective, but for broken services)
- Prevents restart storms (max 5 failures/hour) - because nobody likes a service that's having an existential crisis
- Service-specific restart strategies (each service gets its own therapy approach)
- Custom restart commands support (for those special snowflake services)

### 🔧 **Maintenance Mode Scheduling**

- Toggle maintenance mode to disable auto-restart (for when you need to break things intentionally)
- Schedule maintenance windows (plan your chaos like a professional)
- Pause notifications during maintenance (because nobody needs 47 alerts while you're fixing stuff)
- Keyboard shortcut: `Ctrl+X` (the universal "please stop helping" button)

### 🔍 **Auto-Discovery of Services**

- Discovers Docker containers automatically (like a bloodhound, but for microservices)
- Groups services by Docker Compose projects (organizing your chaos since 2024)
- Detects systemd services (even the ones you forgot you installed)
- Smart service dependency mapping (finally, someone who understands your spaghetti architecture)

### 🏥 **Self-Healing Infrastructure**

- Cascading failure detection (spots the domino effect before it ruins your weekend)
- Dependency-aware monitoring (knows that when the database dies, everything else follows)
- Increased monitoring frequency for at-risk services (helicopter parenting for servers)
- Healing action tracking and reporting (keeps receipts of all the times it saved your bacon)

### 📊 **Alert Grouping & Acknowledgment**

- Groups related alerts to reduce noise (because 50 alerts saying the same thing is just spam)
- Tracks acknowledgment status (knows when you've seen the problem and chosen to ignore it)
- Historical failure analysis (your server's autobiography of bad decisions)
- Response time trending (charts your descent into madness, one slow query at a time)

### 🎨 **Enhanced UI Features**

- Animated status transitions (because watching servers fail should at least look pretty)
- Real-time sparklines (tiny graphs that make you feel like a data scientist)
- Maintenance mode indicators (the digital equivalent of "Do Not Disturb")
- Advanced keyboard shortcuts (for when clicking is too mainstream)

## 🎯 Usage

### Basic Operations

- **Start**: `./sato`
- **Refresh**: `Ctrl+R`
- **Settings**: `Ctrl+S`
- **Toggle Theme**: `Ctrl+T`
- **Maintenance Mode**: `Ctrl+X`

### Advanced Operations

- **Discover Dependencies**: `Ctrl+D`
- **Service Details**: Double-click any service
- **Hide/Show**: `Ctrl+H`
- **Compact Mode**: `Ctrl+C`

### Auto-Restart Configuration

Add restart commands to your service configuration:

```json
{
  "name": "My API Server",
  "host": "localhost:8080",
  "restart_command": "systemctl restart my-api",
  "type": "server"
}
```

### Maintenance Windows

```python
# Schedule 30-minute maintenance starting at specific time
sato.schedule_maintenance_window(start_timestamp, 30)
```

## 💡 Requirements

- Python 3.7+ (because life's too short for Python 2)
- GTK3 development libraries (the GUI toolkit that actually works)
- Docker (optional, for container monitoring) - but let's be honest, you're probably using it

```bash
# Ubuntu/Debian (the reliable choice)
sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0

# Fedora/RHEL (for the adventurous)
sudo dnf install python3-gobject gtk3-devel

# Python packages (the easy part)
pip install requests
```

## 🔧 Configuration

### Service Types Supported

- **HTTP/HTTPS endpoints**
- **Docker containers**
- **TCP ports**
- **Custom health checks**
- **Systemd services**

### Auto-Restart Support

- ✅ Docker containers (`docker restart`)
- ✅ Systemd services (`systemctl restart`)
- ✅ Custom commands
- ✅ Docker Compose services

### Dependency Detection

Sato automatically discovers:

- Database → API dependencies
- Load balancer → backend dependencies
- Cache → application dependencies

## 📈 Monitoring Features

### Status Types

- 🟢 **Operational** - Service running normally (the unicorn state)
- 🟡 **Degraded** - Partial functionality (limping along like Monday morning)
- 🔴 **Down** - Service unavailable (the dreaded red dot of doom)
- ⚪ **Checking** - Status being verified (Schrödinger's service - simultaneously up and down)

### Response Time Tracking

- Real-time response time monitoring (watches your API get slower in real-time)
- Historical trending (the graph of your server's midlife crisis)
- Performance degradation alerts (early warning system for impending doom)
- Sparkline visualizations (tiny charts that make big problems look manageable)

### Failure Analysis

- Failure frequency tracking (counts how many times you've disappointed your users)
- Cascade failure detection (spots when one failure becomes everyone's problem)
- Recovery time measurement (times how long it takes to fix your mistakes)
- Healing action effectiveness (grades its own homework, and it's a straight-A student)

## 🛠️ Advanced Configuration

### Custom Restart Commands

```json
{
  "servers": [
    {
      "name": "Web Server",
      "host": "localhost:80",
      "restart_command": "sudo systemctl restart nginx",
      "max_restart_attempts": 3,
      "restart_delay": 30
    }
  ]
}
```

### Service Dependencies

```json
{
  "dependencies": {
    "Database": ["API Server", "Web App"],
    "Redis Cache": ["API Server"],
    "Load Balancer": ["Web Server 1", "Web Server 2"]
  }
}
```

### Maintenance Schedules

```json
{
  "maintenance_windows": [
    {
      "name": "Weekly Maintenance",
      "start": "Sunday 02:00",
      "duration": 60,
      "services": ["all"]
    }
  ]
}
```

## 🎨 Themes & Customization

- **Dark Theme** (default)
- **Light Theme**
- **Auto Theme** (follows system)
- **Custom CSS** support
- **Opacity control**
- **Compact mode**

## 🔔 Notifications

- Desktop notifications
- System tray alerts
- Email notifications (configurable)
- Webhook integrations
- Slack/Discord support

## 📊 Monitoring Dashboard

Access detailed monitoring data:

- Service uptime statistics
- Response time graphs
- Failure pattern analysis
- Healing action reports
- Dependency maps

## 🚨 Troubleshooting

### Common Issues

**Auto-restart not working:**

- Check service has restart command configured (did you forget to tell it how to restart?)
- Verify permissions for restart commands (sudo is your friend, permission denied is not)
- Ensure maintenance mode is disabled (you might have accidentally put it in "do nothing" mode)

**Docker services not detected:**

- Verify Docker is running (have you tried turning Docker off and on again?)
- Check Docker permissions (Docker doesn't like being bossed around by peasants)
- Ensure containers have proper labels (unlabeled containers are like unnamed variables - confusing)

**High CPU usage:**

- Reduce check intervals (maybe don't check every millisecond?)
- Enable compact mode (less eye candy, more performance)
- Limit number of monitored services (quality over quantity, even for monitoring)

### Debug Mode

```bash
python3 sato.py --debug
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details.

---

**🛰️ Sato - Advanced monitoring that heals itself.** ✨

_Because your infrastructure deserves better than crossing your fingers and hoping for the best._

## 🎭 Fun Facts

- Sato has never asked you to "have you tried restarting it?" - it just does it
- It's been known to fix problems before you even know they exist
- Side effects may include: reduced stress, fewer 3 AM phone calls, and the strange feeling that your servers actually work
- No servers were harmed in the making of this monitoring system (though several bugs were ruthlessly eliminated)

_P.S. - If Sato doesn't work, it will probably restart itself and send you a report about why it failed. Meta-monitoring at its finest._
