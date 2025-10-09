# 🚀 Nginx Static Site Setup Script

A powerful Bash script that automates Nginx configuration for local static websites, now with **SSL support**, **SPA routing**, **API proxying**, and a whole lot more. Works on **Linux** and **macOS** (because we believe in choices, unlike some operating systems 👀).

> **Enhanced Features:** SSL certificates, custom TLDs, SPA support, API proxying, list/remove commands, dry-run mode, and comprehensive validation. It's like the original script went to college and got a PhD in being awesome.

---

## 📋 What It Does

This script simplifies the process of hosting static websites locally by:

1. ✅ **Smart Setup**: Detects your OS and validates Nginx availability (no more "command not found" surprises)
2. 📝 **Flexible Configs**: Creates domain-specific Nginx configurations with SSL, SPA routing, and API proxying support
3. 🔒 **SSL Magic**: Auto-generates self-signed certificates for HTTPS development (because even localhost deserves encryption)
4. 🌐 **Custom Domains**: Supports any TLD (`.io`, `.dev`, `.local`, or whatever makes you happy)
5. � **SPA Ready**: Perfect routing for React, Vue, Angular apps (no more 404s on refresh!)
6. � *R*API Proxying\*_: Forward `/api/_` requests to your backend (full-stack development made easy)
7. 🎛️ **Port Freedom**: Use any port you want (because 80 is so mainstream)
8. 📋 **Site Management**: List, create, and remove sites with simple commands
9. 🧪 **Dry Run Mode**: Preview changes before applying them (for the cautious developers)
10. 🛡️ **Safety First**: Comprehensive validation, backups, and rollback mechanisms

---

## 💡 Why It's Useful

### Without this script (aka "The Dark Ages"):

- Manual Nginx setup and troubleshooting (cue the dramatic music and pulling of hair)
- Error-prone editing of `/etc/hosts` (who knew a simple text file could be so temperamental?)
- Risk of permission issues that make your site vanish into the digital void
- Forgotten syntax or missed steps that make you question your life choices

### With this script (aka "Living in 2025"):

- **Simple setup** that actually works:

```bash
./ngx.sh create myapp /path/to/dist
```

- **Advanced setup** for the power users:

```bash
./ngx.sh create myapp /path/to/dist --ssl --spa --api http://localhost:3001 --tld .dev
```

- **Site management** made easy:

```bash
./ngx.sh list              # See all your sites
./ngx.sh remove myapp      # Clean removal
```

- Fully automated config with SSL, SPA routing, and API proxying (it's like having a DevOps team in a script)
- Works across Linux distros and macOS (because we don't discriminate)
- Safe to run with dry-run mode, backups, rollback, and validation (yes, we're that responsible)
- Predictable, reproducible setup for every project (no more "but it worked on my machine!" excuses)

---

## ⚙️ How It Works

### 🧐 Smart Validation & Setup

The script now comes with a brain! It validates:

- Nginx installation and availability (no more mysterious failures)
- Folder existence and web file detection (suggests SPA mode for React apps)
- Port conflicts (warns you before things get messy)
- SSL certificate requirements (handles the crypto magic for you)

### 🔒 SSL Certificate Generation

When you use `--ssl`, the script becomes a mini certificate authority:

- Generates a private key (2048-bit RSA, because we're not amateurs)
- Creates a self-signed certificate (valid for 365 days of local development bliss)
- Configures proper SSL settings in Nginx (TLS 1.2/1.3, secure ciphers)
- Sets up HTTP to HTTPS redirect (because mixed content is the enemy)

Your certificates live in `/etc/ssl/certs/` and `/etc/ssl/private/` like proper SSL citizens.

---

### 🏷️ Flexible Domain System

No more `.io` tyranny! Choose your own adventure:

```bash
# Default .io (for the startup vibes)
myapp → myapp.io

# Custom TLD (for the rebels)
myapp --tld .dev → myapp.dev
myapp --tld .local → myapp.local

# It's smart enough not to double up
myapp.com --tld .dev → myapp.dev
```

Perfect for matching your production domains or just feeling fancy with `.dev` domains!

---

### 📝 Smart Nginx Configuration

Creates configurations that adapt to your needs:

**Basic Static Site:**

```nginx
server {
    listen 80;
    server_name myapp.io www.myapp.io;
    root /path/to/your/dist;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

**SPA with SSL and API Proxy:**

```nginx
server {
    listen 80;
    server_name myapp.io www.myapp.io;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name myapp.io www.myapp.io;

    ssl_certificate /etc/ssl/certs/myapp.io.crt;
    ssl_certificate_key /etc/ssl/private/myapp.io.key;

    root /path/to/your/dist;

    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;  # SPA routing magic
    }
}
```

The script generates exactly what you need based on your flags. No bloat, no confusion, just clean configs.

---

### 🌐 Intelligent Hosts Management

- Adds your custom domain to `/etc/hosts` (telling your computer "hey, when someone asks for myapp.dev, just look in the mirror")
- Prevents duplicates and handles updates gracefully
- Use `--force` to override existing entries (for those "I know what I'm doing" moments)
- Automatic cleanup when removing sites (no orphaned entries cluttering your hosts file)

---

### 🔐 Security & Permissions

- Sets proper permissions on your dist folder (secure but not paranoid)
- Configures Nginx to run as your user (because running as root is like wearing a tuxedo to do yard work)
- SSL certificates get proper restrictive permissions (600 for keys, 644 for certs)
- Validates folder contents and suggests improvements (like SPA mode for React apps)

---

### 🛡️ Enhanced Safety Features

- **Dry-run mode**: Preview all changes before applying them (`--dry-run`)
- **Automatic rollback**: If anything fails, everything gets restored (like a time machine for your configs)
- **Comprehensive backups**: All modified files get backed up automatically
- **Validation everywhere**: Nginx configs, SSL certificates, folder contents, port conflicts
- **Graceful error handling**: Clear error messages with suggestions for fixes
- **Quiet/Verbose modes**: Control exactly how much the script talks to you
- **Emoji logging**: Because who doesn't love a little joy in their terminal? ✨

---

## 🚀 Usage

### Commands (because the script is all grown up now)

```bash
# Create a new site
./ngx.sh create <domain> <path> [options]

# List all configured sites
./ngx.sh list

# Remove a site (clean removal)
./ngx.sh remove <domain> [options]

# Show version info
./ngx.sh version

# Get help (RTFM, but friendly)
./ngx.sh --help
```

### Basic Examples (the "I just want it to work" approach)

```bash
# Simple static site
./ngx.sh create myapp ./dist

# With SSL (because security matters)
./ngx.sh create myapp ./dist --ssl

# SPA with custom TLD (for the React/Vue crowd)
./ngx.sh create myapp ./dist --spa --tld .dev
```

### Advanced Examples (for the power users)

```bash
# Full-stack development setup
./ngx.sh create myapp ./dist --ssl --spa --api http://localhost:3001 --tld .dev

# Custom port with API proxy
./ngx.sh create api ./dist --port 8080 --api http://localhost:3000

# Preview changes first (for the cautious)
./ngx.sh create myapp ./dist --ssl --spa --dry-run

# Force update existing site
./ngx.sh create myapp ./dist --ssl --force

# Quiet mode (minimal output)
./ngx.sh create myapp ./dist --quiet

# Remove a site when you're done
./ngx.sh remove myapp
```

### Create Options (for the control freaks)

| Flag                | Description                                                |
| ------------------- | ---------------------------------------------------------- |
| `-p, --port <port>` | Custom port (default: 80, or 443 for SSL)                  |
| `-t, --tld <tld>`   | Custom TLD (default: .io)                                  |
| `-s, --ssl`         | Enable SSL/HTTPS with auto-generated certificates          |
| `--spa`             | Configure for Single Page Applications (React/Vue/Angular) |
| `--api <url>`       | Add API proxy configuration (forwards /api/\* to backend)  |
| `-f, --force`       | Force update if domain already exists                      |
| `--dry-run`         | Preview changes without applying them                      |
| `-v, --verbose`     | Enable detailed logging                                    |
| `-q, --quiet`       | Minimal output (errors only)                               |
| `-h, --help`        | Show usage instructions                                    |

### Remove Options

| Flag            | Description                   |
| --------------- | ----------------------------- |
| `--dry-run`     | Preview what would be removed |
| `-v, --verbose` | Show detailed removal process |
| `-q, --quiet`   | Minimal output                |

---

## 📋 Requirements

- **Linux/macOS** with Bash (sorry Windows users, we're still working on that relationship)
- **Sudo privileges** (to modify system files without breaking everything)
- **Static site output folder** (e.g. from React/Vue/Gatsby build processes)

You **don't need to pre-install Nginx**, the script handles it for you like a proper gentleman.

---

## 🛠️ Files Modified (aka "What We're Touching on Your System")

| Path                       | Description                                |
| -------------------------- | ------------------------------------------ |
| `/etc/nginx/conf.d/*.conf` | Your shiny new Nginx site configurations   |
| `/etc/nginx/nginx.conf`    | Set to run as your user (not the overlord) |
| `/etc/hosts`               | Maps custom domains to `127.0.0.1`         |
| `/etc/ssl/certs/*.crt`     | SSL certificates (when using --ssl)        |
| `/etc/ssl/private/*.key`   | SSL private keys (when using --ssl)        |
| `~/.ngx/config`            | Your personal configuration preferences    |

Backups are created for all modified files because we're not monsters. The script also cleans up after itself when removing sites.

---

## 🐛 Troubleshooting (aka "When Things Go Wrong")

### ❌ Permission Denied (the classic)

Make sure the script can actually run:

```bash
chmod +x ngx.sh
```

### 🔁 Nginx Not Starting (the drama queen)

Check what's going on:

```bash
sudo systemctl status nginx
sudo nginx -t  # Test configuration
```

### 🌐 Domain Not Working (the "but it should work!" moment)

Verify your hosts entry and nginx config:

```bash
grep "yourdomain.dev" /etc/hosts
./ngx.sh list  # See all configured sites
```

### 🔒 SSL Certificate Issues (the security theater)

Check certificate generation and permissions:

```bash
sudo ls -la /etc/ssl/certs/yourdomain.dev.crt
sudo ls -la /etc/ssl/private/yourdomain.dev.key
```

### ⚠️ Config Issues (when Nginx gets picky)

Test and debug configurations:

```bash
sudo nginx -t  # Test all configs
sudo tail -f /var/log/nginx/error.log  # Watch for errors
```

### 🔍 Port Conflicts (when something else is hogging your port)

Find what's using your port:

```bash
netstat -tuln | grep :8080
lsof -i :8080  # More detailed info
```

### 🧪 Use Dry-Run Mode (when you're not sure)

Preview changes before applying:

```bash
./ngx.sh create myapp ./dist --ssl --spa --dry-run
```

---

## 🧹 Site Management (for the organized developers)

### List All Sites

```bash
./ngx.sh list
```

Shows all configured sites with paths, SSL status, and config files.

### Remove Sites (the civilized way)

```bash
# Preview what will be removed
./ngx.sh remove myapp --dry-run

# Actually remove it (cleans up everything)
./ngx.sh remove myapp
```

This removes:

- Nginx configuration file
- SSL certificates (if any)
- Hosts file entries
- Reloads Nginx automatically

### Manual Cleanup (if you're feeling adventurous)

```bash
# Remove config manually
sudo rm /etc/nginx/conf.d/myapp_dev.conf

# Remove SSL certificates
sudo rm /etc/ssl/certs/myapp.dev.crt
sudo rm /etc/ssl/private/myapp.dev.key

# Remove hosts entry
sudo sed -i '/myapp.dev/d' /etc/hosts

# Reload nginx
sudo systemctl reload nginx
```

But seriously, just use `./ngx.sh remove myapp`. It's safer and handles edge cases.

---

## 🧙 Terminal Wizardry (For Bash/Zsh Wielders)

If you **really love magic**, and want to summon `ngx` from anywhere in your terminal, do this:

```bash
# Create a symlink (the professional way)
sudo ln -s $(pwd)/scripts/ngx/ngx.sh /usr/local/bin/ngx

# Or create an alias (the quick way)
echo "alias ngx='$(pwd)/scripts/ngx/ngx.sh'" >> ~/.$(basename "$SHELL")rc
```

Then reload your shell to complete the ritual:

```bash
source ~/.$(basename "$SHELL")rc
```

Now you can cast spells from anywhere:

```bash
# Create a full-stack development environment
ngx create myapp ./dist --ssl --spa --api http://localhost:3001 --tld .dev

# List all your magical creations
ngx list

# Banish a site to the shadow realm
ngx remove myapp
```

Boom. You’re now a **CLI wizard**. No more fumbling through folders, just type `ngx` and rewrite the server config like a digital warlock. 🔥

> Just don’t alias it in **fish**, **csh**, or **tcsh**.
> Even **Nginx** will get mad. It’ll refuse to reload. Your logs will cry.
> **Don’t say we didn’t warn you.**

---

## 🧠 Ideal Use Cases (aka "When This Script Shines")

### 🚀 Modern Development Workflows

- **Full-stack development**: SSL + SPA + API proxy in one command
- **Frontend app previews**: React, Vue, Angular with proper routing
- **API development**: Proxy frontend requests to your backend
- **SSL testing**: Test HTTPS locally without certificate headaches

### 🎯 Professional Scenarios

- **Client demos**: Custom domains that look professional (`myapp.dev` > `localhost:3000`)
- **Team development**: Consistent local environments across the team
- **Multi-project management**: List and switch between projects easily
- **Production simulation**: Test with real domain names and SSL

### 💡 Specific Use Cases

- **SPA development**: Perfect routing for client-side applications
- **Static site generators**: Gatsby, Next.js, Nuxt.js, etc.
- **API testing**: Frontend + backend integration testing
- **Custom TLD preferences**: Use `.dev` for development, `.local` for local testing

---

## 🆕 Enhanced Features

### 🔥 Major Features

- **SSL/HTTPS Support**: Auto-generated self-signed certificates
- **SPA Routing**: Perfect for React, Vue, Angular applications
- **API Proxying**: Forward `/api/*` requests to backend servers
- **Custom TLDs**: Use `.dev`, `.local`, or any TLD you want
- **Site Management**: List and remove sites with dedicated commands
- **Dry Run Mode**: Preview changes before applying them

### 🛠️ Developer Experience

- **Better Validation**: Checks nginx, folders, ports, and suggests improvements
- **Comprehensive Testing**: 38 test cases covering all functionality
- **Enhanced Logging**: Verbose/quiet modes with emoji indicators
- **Configuration Management**: Persistent settings in `~/.ngx/config`
- **Improved Error Handling**: Better error messages and automatic rollback

### 🔄 Backward Compatibility

The script maintains backward compatibility for basic usage:

```bash
# Simple syntax still works
./ngx.sh create myapp /path/to/dist

# But now offers so much more
./ngx.sh create myapp /path/to/dist --ssl --spa --api http://localhost:3001
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
./test-ngx.sh
```

The test suite includes 38 test cases covering argument parsing, domain normalization, SSL configuration, SPA setup, API proxying, site management, and error handling.

---

_P.S. - This script was made with ❤️ and probably too much coffee. The enhanced version was powered by TDD principles and the desire to make local development actually enjoyable. Use responsibly and may your deployments be ever in your favor._
