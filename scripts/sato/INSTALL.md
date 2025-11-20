# 🛰️ Sato Enhanced Monitoring System - Installation Guide

## 🚀 Quick Installation

### **1. Install Sato**

```bash
./install.sh install
```

### **2. Run Sato**

```bash
./install.sh run
# or directly
python3 sato.py
```

That's it! Sato will now start automatically on login.

## 📋 Installation Commands

### **Basic Commands:**

```bash
./install.sh install       # Install and enable autostart
./install.sh uninstall     # Remove from system
./install.sh status        # Check installation status
./install.sh run           # Test run Sato
```

### **Autostart Management:**

```bash
./install.sh enable        # Enable autostart
./install.sh disable       # Disable autostart
./install.sh desktop-icon  # Toggle desktop icon
```

### **System Checks:**

```bash
./install.sh check-deps    # Check dependencies
./install.sh test          # Run system tests
./install.sh help          # Show all commands
```

## 🔧 Requirements

### **Required:**

- **Python 3.7+** - `sudo apt install python3`
- **GTK3 bindings** - `sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0`

### **Optional (Recommended):**

- **Python requests** - `pip3 install requests` (for HTTP monitoring)
- **Docker** - For container monitoring
- **systemctl** - For service auto-restart

## 📁 Installation Locations

After installation, Sato will be available:

- **Applications Menu** - Search for "Sato Enhanced Monitoring"
- **Autostart** - Starts automatically on login
- **Desktop Icon** - Optional desktop shortcut

## ✨ Features Included

- ⚡ **Parallel processing** with immediate results
- 🔄 **Auto-restart** failed services
- 🧠 **Intelligent retry logic** with backoff
- 🔧 **Maintenance mode** scheduling
- 🔍 **Auto-discovery** of services
- 🏥 **Self-healing** infrastructure
- 📊 **Alert grouping** and acknowledgment
- 🎨 **Animated backgrounds**

## 🧪 Testing Installation

### **Check Dependencies:**

```bash
./install.sh check-deps
```

### **Run System Tests:**

```bash
./install.sh test
```

### **Test Run:**

```bash
./install.sh run
```

## 🔧 Troubleshooting

### **Dependencies Missing:**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0
pip3 install requests

# Fedora/RHEL
sudo dnf install python3 python3-gobject gtk3-devel
pip3 install requests
```

### **Permission Issues:**

```bash
chmod +x install.sh
chmod +x sato.py
chmod +x sato
```

### **Autostart Not Working:**

```bash
./install.sh disable
./install.sh enable
```

## 📊 Verification

After installation, verify everything works:

1. **Check Status**: `./install.sh status`
2. **Run Tests**: `./install.sh test`
3. **Test Launch**: `./install.sh run`

## 🎯 Next Steps

1. **Configure Services** - Add your services via the Settings dialog
2. **Set Up Notifications** - Configure desktop notifications and webhooks
3. **Enable Auto-restart** - Configure restart commands for your services
4. **Schedule Maintenance** - Set up maintenance windows

## 🆘 Support

If you encounter issues:

1. Run `./install.sh check-deps` to verify dependencies
2. Run `./install.sh test` to check system functionality
3. Check the logs in the terminal when running `./install.sh run`

**Enjoy monitoring with Sato Enhanced Monitoring System!** 🛰️✨
