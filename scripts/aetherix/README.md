# ✨ Aetherix - Divine Development Environment Orchestrator

> _"From the ethereal realm, Aetherix descends to forge the perfect development cosmos"_

Aetherix is a powerful, modular system setup script that transforms bare Linux systems into fully-configured development environments through divine automation and cosmic precision. Think of it as Marie Kondo for your dev environment, but with more mystical powers and fewer folding tutorials.

## 🌌 What is Aetherix?

Aetherix operates from the higher planes of automation, orchestrating the installation and configuration of essential development tools with mystical efficiency. Like a deus ex machina for developers, it resolves the complex narrative of environment setup with elegant, automated solutions.

Tired of spending 3 hours setting up Docker only to realize you forgot to install PostgreSQL? Fed up with manually configuring Nginx while your coffee gets cold and your motivation evaporates? Aetherix swoops in like a caffeinated superhero to save the day (and your sanity).

### 🛠️ Components Aetherix Can Manifest

- **🐳 Docker** - Container orchestration with version control (because who doesn't love containerizing their problems?)
- **🌐 Nginx** - Web server with automatic project configuration (faster than your ex's excuses)
- **🐘 PostgreSQL** - Database systems (native or containerized) - the elephant that never forgets your data
- **🐚 Zsh + Oh My Zsh** - Enhanced shell with cosmic themes (make your terminal prettier than your dating profile)
- **⚡ Vim** - Supercharged text editor configurations (exit strategies included)
- **📱 Development Apps** - VS Code, Postman, and essential tools (the Avengers of development)
- **📊 System Monitoring** - Performance and health monitoring suite (like a fitness tracker, but for your server)
- **🔧 Dev Environments** - Node.js, Python with virtual environments (virtual like your social life during crunch time)
- **📜 Utility Scripts** - Custom development automation tools (because manual work is so last millennium)

## 🚀 Quick Start

```bash
# Clone and enter the ethereal realm (or just cd into the folder like a normal person)
cd scripts/aetherix

# Invoke Aetherix (summon the digital gods)
./aetherix.sh

# Or with cosmic options (for when you want to feel fancy)
./aetherix.sh --debug     # Enable mystical debugging (aka "why is this broken?")
./aetherix.sh --dry-run   # Preview the divine plan (commitment issues? we got you)
./aetherix.sh --help      # Seek guidance from the cosmos (RTFM, but prettier)
```

## ✨ Key Features

### 🎯 **Intelligent Configuration**

- Interactive component selection with cosmic UI (no more decision paralysis!)
- Preset configurations for rapid deployment (for the impatient among us)
- Smart dependency resolution and ordering (smarter than your average bear)
- Configuration persistence across invocations (because nobody likes repeating themselves)

### 🛡️ **Ethereal Reliability**

- Comprehensive error handling and recovery (when things go sideways, we've got your back)
- System compatibility validation (no more "works on my machine" syndrome)
- Health checks and post-installation verification (trust, but verify)
- Rollback capabilities for failed operations (ctrl+z for your entire system)

### 🔮 **Mystical User Experience**

- Beautiful CLI interfaces powered by `gum` (eye candy that actually works)
- Real-time progress tracking with cosmic themes (watch the magic happen)
- Detailed installation previews and summaries (spoiler alerts, but useful)
- Post-installation dashboard and guidance (your personal IT consultant)

### 🧪 **Developer-Friendly**

- Dry-run mode for safe testing (for the commitment-phobic)
- Debug mode with verbose cosmic logging (when you need ALL the details)
- Modular architecture for easy extension (LEGO blocks for grown-ups)
- Individual component testing capabilities (unit tests for your setup script)

## 🏗️ Architecture

Aetherix follows a modular, ethereal architecture:

```
aetherix/
├── aetherix.sh              # Divine entry point
├── lib/                     # Cosmic libraries
│   ├── utils.sh            # Universal utilities
│   ├── ui.sh               # Ethereal user interface
│   ├── progress.sh         # Cosmic progress tracking
│   ├── config.sh           # Configuration management
│   ├── installer.sh        # Installation orchestration
│   └── components/         # Individual component realms
│       ├── docker.sh       # Container cosmos
│       ├── nginx.sh        # Web server realm
│       ├── postgresql.sh   # Database dimension
│       ├── zsh.sh          # Shell enhancement
│       ├── vim.sh          # Editor empowerment
│       ├── apps.sh         # Application suite
│       ├── monitoring.sh   # System observation
│       ├── dev_env.sh      # Development environments
│       └── scripts.sh      # Utility automation
└── README.md               # This cosmic guide
```

## 🎮 Usage Examples

### Basic Invocation

```bash
./aetherix.sh
```

### Advanced Cosmic Commands

```bash
# Preview installation without changes
./aetherix.sh --dry-run

# Enable detailed cosmic logging
./aetherix.sh --debug

# Show component help and guidance
./aetherix.sh --components-help
```

## 🔧 Configuration

Aetherix stores its cosmic configurations in:

- **Config**: `~/.config/nicronian-setup/last_config.conf`
- **Logs**: `~/.config/nicronian-setup/setup.log`

## 🌟 Adding New Components

Extend Aetherix's cosmic reach by adding new components:

1. **Create Component Module**: `lib/components/newservice.sh`
2. **Implement Functions**: `configure_newservice()` and `install_newservice()`
3. **Register Component**: Add to configuration and installer mappings
4. **Test Thoroughly**: Use dry-run and debug modes

See the existing README for detailed component development guidelines.

## 🧪 Testing & Validation

```bash
# Test without making changes
./aetherix.sh --dry-run

# Validate individual components
source lib/components/docker.sh
DRY_RUN=true
install_docker

# Check system compatibility
./aetherix.sh --components-help
```

## 🔍 Troubleshooting

### Common Issues

- **Missing Dependencies**: Aetherix will guide you to install required tools (like a GPS for lost packages)
- **Permission Errors**: Ensure sudo access for system modifications (yes, you need to be the admin of your own computer)
- **Network Issues**: Check internet connectivity for package downloads (have you tried turning your router off and on again?)

### Debug Mode

```bash
./aetherix.sh --debug
```

### Log Analysis

```bash
tail -f ~/.config/nicronian-setup/setup.log
```

## 🤝 Contributing

1. Follow the ethereal coding patterns
2. Add comprehensive error handling
3. Include dry-run support for all operations
4. Update documentation and help systems
5. Test thoroughly across different systems

## 📊 System Requirements

- **OS**: Ubuntu/Debian-based Linux distributions
- **Shell**: Bash 4.0+
- **Tools**: `gum` (installed automatically if missing)
- **Access**: Sudo privileges for system modifications
- **Network**: Internet connection for package downloads

## 🌌 Philosophy

Aetherix embodies the principle that development environment setup should be:

- **Effortless** - Like divine intervention (but with better documentation)
- **Reliable** - Consistent across cosmic realms (and your coworker's weird Ubuntu setup)
- **Extensible** - Adaptable to new dimensions (future-proof, unlike your JavaScript framework choices)
- **Beautiful** - Aesthetically pleasing interactions (because life's too short for ugly CLIs)

## 🎭 Fun Facts

- Aetherix has never asked you to update Adobe Flash Player
- It's been known to make developers actually enjoy system administration
- Side effects may include: increased productivity, reduced caffeine dependency, and spontaneous high-fives
- No developers were harmed in the making of this script (though several keyboards were sacrificed)

---

_"In the beginning was the Command Line, and the Command Line was with Aetherix, and Aetherix was the Command Line."_

**May your development environment be ever cosmic! ✨**

_P.S. - If Aetherix doesn't work, have you tried sacrificing a rubber duck to the coding gods?_
