# 🚀 ZSHO - Zsh Setup Wizard

An interactive script that automates the installation and configuration of Zsh with Oh My Zsh framework and popular plugins. Because life's too short to manually configure your shell like it's 1995, and frankly, your terminal deserves better than the default bash prompt that looks like it was designed by someone who thinks "user experience" is a fancy coffee drink.

---

## 📋 What It Does

This script provides a complete Zsh setup experience:

1. ✅ **Automatic Zsh Installation** - Detects your package manager and installs Zsh
2. 🎨 **Oh My Zsh Framework** - Installs the popular Zsh framework with themes
3. 🧩 **Essential Plugins** - Adds productivity-boosting plugins automatically
4. ⚙️ **Shell Configuration** - Optionally sets Zsh as your default shell
5. 🔄 **Backup & Safety** - Creates backups before making changes
6. 🎯 **Interactive Setup** - Guides you through all configuration options

---

## 💡 Why Use This Script?

### Without this script (aka "The Stone Age Approach"):

- Spend 3 hours researching "how to install zsh" and end up with 47 browser tabs open
- Navigate the Oh My Zsh installation docs while questioning your life choices
- Hunt down plugins on GitHub like you're collecting Pokémon cards, but less fun
- Manually edit `.zshrc` and accidentally break everything (classic move)
- Deal with permission errors that make you want to throw your laptop out the window
- Realize you forgot to backup your shell config after it's too late (we've all been there)

### With this script (aka "Living in 2025 Like a Civilized Human"):

- One command setup that actually works (revolutionary concept, I know)
- Interactive prompts that hold your hand through the process (no judgment here)
- Automatic plugin installation because ain't nobody got time for manual git clones
- Safe backup and rollback mechanisms (we learned from your mistakes)
- Consistent setup across machines so you don't have to remember what you did last time
- No need to bookmark 15 different Stack Overflow answers about zsh configuration

---

## ⚙️ Features

### 🎨 **Theme Selection**

Choose from popular Oh My Zsh themes (because your prompt should have more personality than a corporate email signature):

- **robbyrussell** - Clean and simple (for the minimalists who think less is more)
- **agnoster** - Powerline-style with Git info (for when you want your terminal to look like a spaceship dashboard)
- **avit** - Colorful with timestamp (because sometimes you need to know what time you broke everything)
- **bira** - Two-line prompt with user info (for those who like their prompts with extra real estate)

### 🧩 **Plugin Collection**

Essential plugins for productivity (or as we like to call them, "terminal superpowers"):

- **zsh-autosuggestions** - Fish-like command suggestions based on history (it's like having a psychic terminal that knows what you want to type)
- **zsh-syntax-highlighting** - Real-time syntax highlighting for commands (turns your terminal into a fancy code editor, minus the bloat)
- **fast-syntax-highlighting** - Faster alternative to syntax highlighting (because waiting is for people who don't have deadlines)
- **zsh-autocomplete** - Real-time autocomplete as you type (like autocorrect, but actually helpful)

### 🛡️ **Safety Features**

- Automatic backup of existing `.zshrc` (because we're not monsters who delete your configs)
- Checks for existing installations to avoid conflicts (no more "why do I have 3 different zsh setups?")
- Validates dependencies before installation (we check if you have git and curl, revolutionary stuff)
- Cross-platform package manager detection (works on Linux and macOS, sorry Windows users, we're still working on that relationship)
- Graceful error handling and rollback (when things go wrong, we fix it, unlike your ex)

---

## 🚀 Usage

### Basic Interactive Setup (The "I Trust You, Just Do It" Approach)

```bash
./zsho.sh
```

### Command Options (For The Control Freaks)

```bash
# Show help (RTFM, but make it friendly)
./zsho.sh --help

# Show version (because version numbers matter to someone)
./zsho.sh --version

# Preview changes without installing (for the commitment-phobic)
./zsho.sh --dry-run

# Minimal output (for the strong, silent types)
./zsho.sh --quiet
```

---

## 📋 Requirements

### System Requirements

- **Linux** (Ubuntu, Debian, CentOS, RHEL, Arch) or **macOS**
- **Git** (for cloning Oh My Zsh and plugins)
- **curl** (for downloading Oh My Zsh installer)
- **sudo** access (for package installation and shell changes)

### Package Manager Support

The script automatically detects and uses:

- `apt` (Ubuntu/Debian)
- `yum` (CentOS/RHEL 7)
- `dnf` (Fedora/RHEL 8+)
- `pacman` (Arch Linux)
- `brew` (macOS)

---

## 🎯 Interactive Setup Flow

### 1. **Zsh Installation**

```
✅ Zsh will be installed
📦 Installing Zsh...
✅ Zsh installed successfully
```

### 2. **Oh My Zsh Configuration**

```
✨ Install Oh My Zsh? (y/N)
   📜 Select the desired theme:
   └── • Theme: agnoster
```

### 3. **Shell Configuration**

```
⚙️ Set Zsh as default shell? (y/N)
   └── • Default shell: Yes
```

### 4. **Plugin Selection**

```
🧩 Install Zsh plugins? (y/N)
   📜 Select the desired plugins - default is all:
   └── • Plugins: Auto-Suggestions zsh-syntax-highlighting
```

### 5. **Installation Summary**

```
📋 Configuration Summary:
   • Install Zsh: Yes
   • Install Oh My Zsh: Yes (agnoster theme)
   • Set as default shell: Yes
   • Install plugins: Yes (Auto-Suggestions zsh-syntax-highlighting)

🚀 Proceed with installation? (y/N)
```

---

## 🛠️ What Gets Modified

| File/Directory                 | Description                          |
| ------------------------------ | ------------------------------------ |
| `~/.zshrc`                     | Main Zsh configuration file          |
| `~/.zshrc.bak`                 | Backup of original configuration     |
| `~/.oh-my-zsh/`                | Oh My Zsh framework directory        |
| `~/.oh-my-zsh/custom/plugins/` | Custom plugin installations          |
| `/etc/passwd`                  | Default shell setting (if requested) |

---

## 🧩 Plugin Details

### zsh-autosuggestions

- **What it does**: Suggests commands as you type based on history
- **Usage**: Start typing and see grayed-out suggestions, press → to accept
- **Repository**: [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

### zsh-syntax-highlighting

- **What it does**: Highlights command syntax in real-time
- **Usage**: Commands turn green when valid, red when invalid
- **Repository**: [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

### fast-syntax-highlighting

- **What it does**: Faster alternative to zsh-syntax-highlighting
- **Usage**: Same as syntax-highlighting but with better performance
- **Repository**: [zdharma-continuum/fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)

### zsh-autocomplete

- **What it does**: Real-time autocomplete menu as you type
- **Usage**: Shows completion menu automatically, use Tab to navigate
- **Repository**: [marlonrichert/zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete)

---

## 🐛 Troubleshooting (aka "When Things Go Sideways")

### ❌ Permission Denied (The Classic)

Make sure the script can actually run (shocking concept, we know):

```bash
chmod +x zsho.sh
```

### 🔄 Zsh Not Starting (The "But It Worked Yesterday" Syndrome)

If Zsh doesn't start automatically (because computers love to be difficult):

```bash
# Start Zsh manually (the gentle approach)
exec zsh

# Or restart your terminal (the "turn it off and on again" method)
```

### 🌐 Plugin Not Working (The "I Followed The Instructions" Dilemma)

If plugins aren't working after installation (they're probably just being shy):

```bash
# Reload Zsh configuration (like refreshing a webpage, but for your shell)
source ~/.zshrc

# Or restart terminal (because sometimes you need a fresh start in life)
```

### ⚠️ Theme Not Applied (The "My Terminal Looks Boring" Crisis)

If the theme doesn't appear correctly (your terminal is having an identity crisis):

```bash
# Check if theme is set (detective work time)
grep ZSH_THEME ~/.zshrc

# Some themes require powerline fonts (because they're fancy like that)
# Install powerline fonts for full theme support
```

### 🔍 Check Installation

Verify your setup:

```bash
# Check Zsh version
zsh --version

# Check current shell
echo $SHELL

# Check Oh My Zsh
ls ~/.oh-my-zsh

# Check plugins
ls ~/.oh-my-zsh/custom/plugins
```

---

## 🧹 Uninstallation

### Remove Oh My Zsh

```bash
uninstall_oh_my_zsh
```

### Restore Original Shell

```bash
# Change back to bash
chsh -s /bin/bash

# Restore backup configuration
cp ~/.zshrc.bak ~/.zshrc
```

### Remove Zsh (Optional)

```bash
# Ubuntu/Debian
sudo apt remove zsh

# CentOS/RHEL
sudo yum remove zsh

# macOS
brew uninstall zsh
```

---

## 🎨 Customization

### Adding More Themes

Edit `~/.zshrc` and change the theme:

```bash
ZSH_THEME="powerlevel10k/powerlevel10k"
```

### Adding More Plugins

Edit the plugins line in `~/.zshrc`:

```bash
plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker kubectl)
```

### Custom Aliases

Add to `~/.zshrc`:

```bash
alias ll='ls -la'
alias gs='git status'
alias gp='git push'
```

---

## 🔗 Useful Resources

- [Oh My Zsh Documentation](https://ohmyz.sh/)
- [Zsh Manual](http://zsh.sourceforge.net/Doc/)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [Powerline Fonts](https://github.com/powerline/fonts)

---

## 🧠 Ideal Use Cases (aka "When This Script Shines")

- 🖥️ **New System Setup** - Quick shell environment setup on fresh installations (because configuring shells manually is so 2010)
- 👥 **Team Standardization** - Consistent shell setup across development teams (no more "works on my machine" excuses)
- 🔄 **Dotfiles Management** - Part of automated dotfiles installation (for the automation enthusiasts who script everything)
- 🎓 **Learning Environment** - Safe way to try Zsh without manual configuration (training wheels for your terminal)
- 🚀 **Productivity Boost** - Get powerful shell features without the research (because you have actual work to do)
- 😴 **Lazy Sunday Projects** - When you want to upgrade your terminal but don't want to think too hard
- 🆘 **Emergency Shell Rescue** - When you broke your shell config and need a quick fix (we don't judge)

---

_Made with ❤️ and probably too much caffeine for developers who want a powerful shell without the existential crisis of manual configuration. May your commands be swift and your autocomplete be accurate!_
