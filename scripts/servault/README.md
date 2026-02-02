# 🔐 SERVAULT - Secure Server Access Manager

A powerful multi-user server login manager that integrates with **1Password** and **Bitwarden** to handle team server connections across multiple environments. Because remembering passwords is for people who enjoy living dangerously, and frankly, your production servers deserve better security than "password123" written on a sticky note under your keyboard (yes, we see you, Karen from accounting).

## 🚀 **Quick Start for New Users**

**TL;DR: Just run it, and it will guide you through everything!**

```bash
# 1. Make it executable
chmod +x servault.sh

# 2. Run interactive setup (configures everything for you)
./servault.sh --setup

# 3. Try to connect (it will auto-install dependencies if needed)
./servault.sh uat

# 4. Use specific users for different access levels
./servault.sh uat --user alex
./servault.sh prod --user admin db

# 5. List available users per environment
./servault.sh uat --list-users
```

## 🎯 **Key Features:**

- � **\*Dual Password Manager Support** - Works with both 1Password and Bitwarden (your choice!)
- � **\*Multi-User Support** - Multiple users per environment with separate password manager vaults
- 🗂️ **Multi-Vault Architecture** - Each user can have their own password manager item
- 🎛️ **Stage-by-Stage Setup** - Configure environments one at a time with clear prompts
- 🤖 **Auto-install dependencies** - Script can install missing tools automatically
- ⚙️ **Interactive setup** - Configure project settings with prompts instead of editing code
- � **Ssmart guidance** - Step-by-step instructions for everything
- 📋 **User Management** - Easy user listing and configuration per environment
- ⚡ **Fast Mode** - Skip banner and verbose output for automation and quick access
- 🔄 **Auto-Detection** - Automatically detects and uses available password managers

---

## � **Passtword Manager Support**

SERVAULT works with both major password managers, giving you the flexibility to choose what works best for your team:

### **🏆 1Password (Premium Experience)**

- **Best for:** Teams with budget for premium tools
- **Pros:** Excellent UX, robust CLI, great team features
- **Setup:** Requires 1Password subscription + CLI installation

### **🆓 Bitwarden (Free & Open Source)**

- **Best for:** Budget-conscious teams, open-source advocates
- **Pros:** Free tier available, open source, great community
- **Setup:** Free account + CLI installation via npm

### **🤖 Auto-Detection Magic**

SERVAULT automatically detects which password manager you have installed:

- **Both available?** Defaults to 1Password (but you can choose Bitwarden)
- **Only one available?** Uses whatever you have
- **Neither available?** Shows helpful installation instructions

---

## 📋 What It Does

This script provides secure server access with encrypted credential management:

1. 🔐 **Password Manager Integration** - Retrieves credentials securely from 1Password or Bitwarden vaults
2. 🖥️ **Multi-Environment Support** - Connects to UAT and production servers seamlessly
3. 🗄️ **Database Access** - Direct PostgreSQL database connections through SSH tunnels
4. 👤 **Multiple User Support** - Switch between standard and main user credentials
5. 🛡️ **Security First** - No hardcoded passwords or plain text credential storage
6. 🧪 **Dry-Run Mode** - Preview connection details without actually connecting

---

## 💡 Why Use This Script?

### Without this script (aka "The Password Juggling Nightmare"):

- Keep a spreadsheet of server IPs, usernames, and passwords (your security team is having nightmares)
- Manually type long, complex passwords every time you need to connect (typos guaranteed, sanity not included)
- Remember which user to use for which environment (spoiler alert: you won't, and you'll blame it on Monday)
- Switch between terminal tabs to copy-paste credentials like you're playing password hopscotch at the Olympics
- Accidentally connect to production when you meant UAT (we've all been there, don't lie, the logs don't lie either)
- Store passwords in plain text files because "it's just temporary" (narrator: it wasn't temporary, it never is)
- Spend 20 minutes looking for that one password you wrote down "somewhere safe" (spoiler: it's in your other laptop)

### With this script (aka "The Civilized Approach to Server Access"):

- One command to rule them all: `./servault.sh prod db` and you're in (like magic, but with more security)
- Secure credential storage through 1Password (your security team will send thank-you cards and maybe cookies)
- No more "wait, what was the production password again?" moments (your memory can focus on important things, like coffee preferences)
- Automatic environment detection so you can't accidentally nuke production (probably... we're not miracle workers)
- Database connections that just work without manual SSH tunneling gymnastics (no PhD in networking required)
- Sleep better at night knowing your credentials aren't scattered across 47 different files like digital confetti

---

## ⚙️ Features

### 🌍 **Environment Support**

Connect to different environments with ease (because context switching is hard enough without adding password amnesia):

- **UAT** - Your testing playground where bugs go to party and occasionally reproduce in production
- **Production** - The scary place where real users live and everything must work perfectly (no pressure)
- **Staging** - The middle child environment that everyone forgets about until something breaks
- **Dev** - Where dreams go to become reality (or nightmares, depending on your coffee intake)

### 👥 **User Management**

Switch between different user contexts:

- **Standard User** - Your everyday server access account
- **Main User** - The special account for when you need extra privileges (use responsibly)

### 🗄️ **Database Integration**

Direct PostgreSQL access through secure SSH tunnels:

- **Automatic Connection** - SSH to server and connect to database in one command
- **Credential Management** - Database passwords handled securely through 1Password
- **Interactive Sessions** - Full psql access with all your favorite SQL commands

### 🛡️ **Security Features**

- **1Password Integration** - Credentials stored in your encrypted vault, not in plain text files
- **No Hardcoded Secrets** - Zero passwords in the script itself (as it should be)
- **Secure Authentication** - Uses sshpass and expect for automated but secure connections
- **Host Key Management** - Handles SSH host key verification automatically

---

## 🚀 Usage

### Basic Server Connections (The "I Just Want to Get In" Approach)

```bash
# Connect to UAT server
./servault.sh uat

# Connect to production server (the scary one)
./servault.sh prod
```

### Multi-User Connections (The "Team Collaboration Without the Drama" Approach)

```bash
# Connect as specific user (no more "whose password is this?" moments)
./servault.sh uat --user alex              # Alex's UAT access (Alex is responsible for any chaos)
./servault.sh prod --user sarah            # Sarah's production access (Sarah knows what she's doing)
./servault.sh staging --user admin         # Admin user for staging (with great power...)

# List available users for an environment (like a phone book, but useful)
./servault.sh uat --list-users             # Shows: default, alex, sarah
./servault.sh prod --list-users            # Shows: default, admin (production is exclusive like that)
```

### Database Connections (The "I Need to Query Things Without Crying" Approach)

```bash
# Connect to UAT server and database (default user, default chaos level)
./servault.sh uat db

# Connect to production database as specific user (because production deserves respect)
./servault.sh prod --user admin db

# Connect with main credentials and database access (for when you need the big guns)
./servault.sh uat --user alex main db
```

### Advanced Usage (For the Power Users Who Read Documentation)

```bash
# Use main user credentials for UAT (when you need the VIP treatment)
./servault.sh uat main

# Use specific user with main credentials and database (the full monty)
./servault.sh prod --user sarah main db

# Preview connection details without connecting (for the commitment-phobic)
./servault.sh uat --user alex --dry-run

# Show current configuration and available users (like a status report, but prettier)
./servault.sh --config

# Interactive setup for new environments/users (hand-holding included)
./servault.sh --setup

# Fast mode (minimal output, perfect for automation and impatient humans)
./servault.sh uat --fast
./servault.sh prod --user admin --fast db

# Password manager override (because choice is beautiful)
./servault.sh uat --password-manager bitwarden
./servault.sh prod --pm bw --user admin db  # Short form works too
```

---

## 📋 Requirements

### System Dependencies

The script requires these tools to function properly. **Don't worry** - if you're missing any, the script will detect this and show you exactly how to install them for your operating system!

**Required Tools:**

| Tool                       | Purpose                           | Why We Need It                                                        |
| -------------------------- | --------------------------------- | --------------------------------------------------------------------- |
| **Password Manager CLI**   | Secure credential retrieval       | Fetches passwords from encrypted vaults                               |
| └── **1Password CLI (op)** | Premium option                    | Excellent UX, robust features                                         |
| └── **Bitwarden CLI (bw)** | Free/open source option           | Budget-friendly, community-driven                                     |
| **sshpass**                | Password-based SSH authentication | Automates SSH login without manual password typing                    |
| **expect**                 | Interactive session automation    | Handles complex server interactions (user switching, database access) |
| **jq** _(Bitwarden only)_  | JSON processing                   | Parses Bitwarden CLI JSON responses                                   |

### 🚀 **Easy Installation**

**The script handles everything automatically!**

```bash
# Try running the script - it will check dependencies automatically
./servault.sh uat

# If dependencies are missing, you'll see:
# ❌ Missing required dependencies:
#    • sshpass
#    • expect
#
# 💡 To install missing dependencies, run:
#    sudo apt update
#    sudo apt install sshpass expect
#
# 🤖 Would you like me to automatically install the missing dependencies?
#    This will run the installation commands shown above.
#
# Install automatically? (y/N): y
```

**Just type 'y' and the script installs everything for you!** 🎉

### 🔐 **Password Manager Choice**

SERVAULT supports both major password managers - choose what works for your team:

| Password Manager | Cost      | Best For                           | Setup Complexity |
| ---------------- | --------- | ---------------------------------- | ---------------- |
| **1Password**    | Premium   | Teams with budget, excellent UX    | Medium           |
| **Bitwarden**    | Free/Paid | Budget-conscious, open source fans | Easy             |

**During setup, SERVAULT will:**

1. **Auto-detect** which password managers you have installed
2. **Recommend 1Password** if both are available (better UX)
3. **Let you choose Bitwarden** if you prefer free/open source
4. **Save your preference** for future use
5. **Allow overrides** with `--password-manager` flag

**Manual Installation (if you prefer):**

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install sshpass expect
```

**macOS:**

```bash
brew install sshpass expect
```

**1Password CLI:**

```bash
# Ubuntu/Debian
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
sudo apt update && sudo apt install 1password-cli

# macOS
brew install 1password-cli
```

### Password Manager Item Setup

Both password managers need items with configurable naming patterns. By default, the script looks for items named:

- `uat server`
- `prod server`
- `staging server`
- `dev server`

**🔧 Customization**: Use interactive setup to configure your naming convention:

```bash
./servault.sh --setup  # Guides you through the whole process!
```

#### 🏆 1Password Item Format

**Option A: Individual Fields (Recommended)**

```
Item Name: "uat server"
Fields:
- SERVER_USER: your_uat_username
- SERVER_IP: 192.168.1.100
- SERVER_PASSWORD: your_password
- DB_USER: db_username
- DB_NAME: your_database_name
- DB_PASSWORD: database_password
- DB_PORT: 5432
- DB_HOST: localhost
- MAIN_USER: main_username
- MAIN_PASSWORD: main_user_password
- DB_SYSTEM_USER: database_system_user (optional)
```

**Option B: Secure Notes**

```
Item Name: "uat server"
Notes:
SERVER_USER=your_uat_username
SERVER_IP=192.168.1.100
SERVER_PASSWORD=your_password
DB_USER=db_username
DB_NAME=your_database_name
DB_PASSWORD=database_password
DB_PORT=5432
DB_HOST=localhost
MAIN_USER=main_username
MAIN_PASSWORD=main_user_password
```

#### 🆓 Bitwarden Item Format

**Option A: Custom Fields (Recommended)**

```
Item Name: "uat server"
Type: Secure Note
Custom Fields:
- SERVER_USER: your_uat_username
- SERVER_IP: 192.168.1.100
- SERVER_PASSWORD: your_password
- DB_USER: db_username
- etc...
```

**Option B: Notes Format**

```
Item Name: "uat server"
Type: Secure Note
Notes:
SERVER_USER=your_uat_username
SERVER_IP=192.168.1.100
SERVER_PASSWORD=your_password
DB_USER=db_username
DB_NAME=your_database_name
```

#### Required Credential Fields

| Field             | Description                                        | Required    |
| ----------------- | -------------------------------------------------- | ----------- |
| `SERVER_USER`     | SSH username for server connection                 | ✅          |
| `SERVER_IP`       | Server IP address or hostname                      | ✅          |
| `SERVER_PASSWORD` | SSH password for server                            | ✅          |
| `DB_USER`         | Database username                                  | ✅          |
| `DB_NAME`         | Database name                                      | ✅          |
| `DB_PASSWORD`     | Database password                                  | ✅          |
| `DB_PORT`         | Database port (usually 5432)                       | ✅          |
| `DB_HOST`         | Database host (usually localhost)                  | ✅          |
| `MAIN_USER`       | Main/admin username for server                     | ✅          |
| `MAIN_PASSWORD`   | Main/admin password                                | ✅          |
| `DB_SYSTEM_USER`  | System user for database access (e.g., "postgres") | ⚪ Optional |

**Note**: The `DB_SYSTEM_USER` field is optional. If provided, the script will use `sudo su - <DB_SYSTEM_USER>` before connecting to the database when using main user credentials

````

---

## 🛠️ Installation

### 🎯 **The Smart Way (Recommended for Humans Who Value Their Time)**

**Just run the script - it will tell you what to install! (Revolutionary concept, we know)**

```bash
# Make it executable (because computers are picky about permissions)
chmod +x servault.sh

# Run it - dependency checking is automatic (like having a personal IT assistant)
./servault.sh uat

# Follow the installation commands it shows you (copy-paste friendly, typo-proof)
# Then run it again! (second time's the charm)
```

### 📋 **Manual Installation (If You Prefer the Hard Way)**

**Ubuntu/Debian:**
```bash
# Core dependencies
sudo apt update
sudo apt install sshpass expect jq

# 1Password CLI (Premium option)
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
sudo apt update && sudo apt install 1password-cli

# OR Bitwarden CLI (Free option)
sudo apt install nodejs npm
npm install -g @bitwarden/cli
```

**macOS:**
```bash
# Core dependencies
brew install sshpass expect jq

# 1Password CLI (Premium option)
brew install 1password-cli

# OR Bitwarden CLI (Free option)
brew install bitwarden-cli
```

### Setup Your Password Manager

**1Password Setup:**
```bash
# Sign in to your 1Password account
op account add

# Verify it's working
op vault list
```

**Bitwarden Setup:**
```bash
# Log in to your Bitwarden account
bw login

# Unlock your vault (creates session)
bw unlock

# Verify it's working
bw status
```

**Note:** SERVAULT will guide you through authentication during setup if needed!

### Make Script Executable

```bash
chmod +x servault.sh
```

---

## ⚙️ Configuration & Customization

### 🔧 Interactive Configuration Setup

**New! No more editing script files manually!**

```bash
# Interactive setup - configures everything with prompts
./servault.sh --setup

# Example interaction:
# � Passeword Manager Configuration:
# 🔍 Found multiple password managers:
#    ✅ 1Password CLI
#    ✅ Bitwarden CLI
#
# 💡 Default: Using 1Password (recommended for best experience)
# Would you like to use Bitwarden instead? (y/N): n
#
# ✅ Using 1Password for credential storage
# 💾 Configuration saved to ~/.servault/config
#
# Now let's configure your environments...
# Available stages: [1] dev  [2] uat  [3] prod  [4] staging
# Select a stage to configure (1-4): 2
#
# Project name: mycompany
# 1Password vault item name for uat: mycompany uat server
```

### �  Password Manager Override

**Need to switch password managers temporarily?**

```bash
# Override saved preference for one command
./servault.sh uat --password-manager bitwarden
./servault.sh prod --pm bw --user admin db  # Short form

# Check which password manager is configured
./servault.sh --config
```

### 📋 View Current Configuration

```bash
# Show current configuration and password manager setup
./servault.sh --config
```

This displays:
- Current password manager (1Password or Bitwarden)
- Configured environments and users
- Actual password manager item names for each environment
- Required credential fields
- Optional fields and their purposes

### 🎨 Manual Customization (Advanced)

If you prefer to edit the script directly:

```bash
# Configuration - Customize these for your setup
readonly DEFAULT_PROJECT_PREFIX="myproject"  # Your project prefix (optional)
readonly DEFAULT_ITEM_SUFFIX="server"       # Suffix for 1Password items
```

**Examples:**

| Configuration                     | Result                                |
| --------------------------------- | ------------------------------------- |
| `PREFIX=""` `SUFFIX="server"`     | `uat server`, `prod server`           |
| `PREFIX="acme"` `SUFFIX="server"` | `acme uat server`, `acme prod server` |
| `PREFIX="client"` `SUFFIX="env"`  | `client uat env`, `client prod env`   |

### 🌍 Add New Environments

To add support for new environments (e.g., `qa`, `demo`):

1. **Update the patterns array:**

```bash
declare -A OP_ITEM_PATTERNS=(
    ["uat"]="${DEFAULT_PROJECT_PREFIX:+$DEFAULT_PROJECT_PREFIX }uat $DEFAULT_ITEM_SUFFIX"
    ["prod"]="${DEFAULT_PROJECT_PREFIX:+$DEFAULT_PROJECT_PREFIX }prod $DEFAULT_ITEM_SUFFIX"
    ["qa"]="${DEFAULT_PROJECT_PREFIX:+$DEFAULT_PROJECT_PREFIX }qa $DEFAULT_ITEM_SUFFIX"
    ["demo"]="${DEFAULT_PROJECT_PREFIX:+$DEFAULT_PROJECT_PREFIX }demo $DEFAULT_ITEM_SUFFIX"
)
```

2. **Update the argument parsing:**

```bash
uat|prod|staging|dev|qa|demo)
    environment="$1"
    shift
    ;;
```

3. **Create the corresponding 1Password items** with the same credential fields

---

## 🐛 Troubleshooting (aka "When the Magic Stops Working")

### ❌ 1Password Authentication Failed (The "Did You Turn It Off and On Again?" Moment)

```bash
# Check if you're signed in
op account list

# Sign in manually if needed
op signin

# Verify your vault access
op vault list
```

### 🔑 Missing Credentials (The "I Swear I Put It Somewhere" Dilemma)

```bash
# Check current configuration to see expected item names
./servault.sh --config

# Check if your 1Password items exist (adjust names based on your config)
op item list | grep "uat server"
op item list | grep "prod server"

# View item contents (be careful, this shows passwords)
op item get "uat server" --field notesPlain

# List all fields in an item
op item get "uat server" --format json | jq '.fields[].label'
```

### 🌐 SSH Connection Failed (The "Network Gremlins Strike Again" Crisis)

```bash
# Test manual SSH connection
ssh username@server_ip

# Check if sshpass is working
sshpass -p "password" ssh username@server_ip

# Verify server is reachable
ping server_ip
```

### 🗄️ Database Connection Issues (The "PostgreSQL is Having a Moment" Syndrome)

```bash
# Test database connection manually
PGPASSWORD=db_password psql -h db_host -p db_port -U db_user -d db_name

# Check if PostgreSQL is running on the server
ssh username@server_ip "sudo systemctl status postgresql"
```

### 🔧 Missing Dependencies (The "I Thought I Had Everything Installed" Surprise)

```bash
# Check what's missing
which op sshpass expect

# Install missing packages (Ubuntu/Debian)
sudo apt install sshpass expect

# Install 1Password CLI if missing
# Follow the installation guide above
```

---

## 🧪 Testing

Run the comprehensive test suite to make sure everything is working:

```bash
./test-servault.sh
```

The test suite covers:

- Argument validation and error handling
- Dependency checking
- 1Password integration verification
- Security feature validation
- Script structure and best practices

---

## 🔒 Security Considerations

### What This Script Does Right

- **No Hardcoded Credentials** - All sensitive data comes from 1Password
- **Encrypted Storage** - 1Password handles encryption and secure storage
- **Minimal Exposure** - Credentials are only in memory during execution
- **Audit Trail** - 1Password logs access to credential items

### What You Should Know

- **SSH Host Keys** - Script disables strict host key checking for automation (consider the security implications)
- **Password Authentication** - Uses password-based SSH (key-based auth is more secure when possible)
- **Terminal History** - Passwords don't appear in bash history, but be aware of terminal logging
- **Process List** - Passwords may be visible in process lists briefly during execution

### Best Practices

- **Regular Rotation** - Rotate server passwords regularly
- **Principle of Least Privilege** - Only give users the minimum access they need
- **Monitor Access** - Keep an eye on who's accessing what servers
- **Backup Credentials** - Make sure multiple people can access critical systems

---

## 🧠 Ideal Use Cases (aka "When This Script Becomes Your Best Friend")

- 🚀 **DevOps Workflows** - Quick server access during deployments and troubleshooting (because downtime waits for no one)
- 🔍 **Database Debugging** - Fast database connections for investigating production issues (CSI: Database Edition)
- 👥 **Team Environments** - Standardized server access across development teams (no more "it works on my machine" excuses)
- 🆘 **Emergency Response** - Rapid access to servers during incidents (when every second counts and your boss is breathing down your neck)
- 📊 **Data Analysis** - Quick database queries without complex connection setup (because data scientists have better things to do than fight with SSH)
- 🧪 **Testing Workflows** - Easy switching between UAT and production environments (context switching made painless)
- 😴 **Late Night Debugging** - When you're too tired to remember which password goes where (and coffee isn't helping anymore)
- 🎯 **Automation Scripts** - Building blocks for larger deployment and maintenance scripts (the foundation of your DevOps empire)

---



_Made with ❤️ and a healthy paranoia about password security for developers who believe that server access should be both secure and convenient. May your connections be swift, your credentials be encrypted, and may you never again have to explain to your boss why you accidentally ran `rm -rf /` on production because you thought you were on UAT! 🙏_
````
