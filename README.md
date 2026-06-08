# 🤖 automas

Welcome to **automas**, my little shelf of Bash/Python-powered conveniences for the chores I got tired of doing by hand.

It is part toolbox, part command-line junk drawer, part "future me will definitely remember how this works" insurance policy. Each script lives in its own folder with its own README, because chaos is fun only when it is documented.

## 📂 Structure

The repo is organized around scripts, not vibes pretending to be scripts:

```text
automas/
├── installer.sh            # Installs scripts into ~/.local/bin
├── navigator.sh            # Menu-driven script browser/runner
├── scripts/
│   ├── aetherix/           # Development environment setup orchestrator
│   ├── dbm/                # PostgreSQL backup/reset/shell helper
│   ├── f-create/           # File and folder creator with extra horsepower
│   ├── gssw/               # Git commit signing setup wizard
│   ├── ngx/                # Local Nginx static-site setup helper
│   ├── sato/               # Infrastructure/service monitoring app
│   ├── servault/           # Secure server access manager
│   └── zsho/               # Zsh + Oh My Zsh setup wizard
├── LICENSE
└── README.md               # You are here. Try not to make eye contact.
```

## 🚀 Quick Start

Clone it, make the scripts executable, and either run what you need directly or install the script commands into `~/.local/bin`.

```bash
git clone <this-repo-url>
cd automas
chmod +x installer.sh navigator.sh scripts/*/*.sh
```

Run the menu if you want to browse before touching anything important:

```bash
./navigator.sh
```

Install one script:

```bash
./installer.sh dbm
```

Install everything that follows the `scripts/name/name.sh` pattern:

```bash
./installer.sh all
```

After that, assuming `~/.local/bin` is on your `PATH`, you can call things like `dbm`, `ngx`, `zsho`, and friends from anywhere. Very fancy. Basically infrastructure now.

## 🧭 Navigator

The **Automas Navigator** is a tiny interactive CLI for exploring the `scripts/` folders.

```bash
./navigator.sh
```

It can:

- Show available script folders
- List runnable files inside each folder
- Run Bash, Python, JS, TS, or SQL-ish scripts
- Open script files, READMEs, or folders from the menu
- Add enough color to make your terminal feel like it has ambitions

## 📦 Installer

The installer creates symlinks in `~/.local/bin`, so scripts can be run like normal commands.

```bash
./installer.sh list
./installer.sh dbm
./installer.sh all
./installer.sh -o ngx
```

Use `-o` / `--override` if an existing shell alias is standing in the doorway wearing sunglasses. The installer backs up your `.zshrc` before removing conflicting aliases, because we are chaotic, not reckless.

## 🛠️ Scripts

Here is the current lineup of small robots, each with its own personal problems:

| Script | What it does |
| --- | --- |
| [**aetherix**](scripts/aetherix) | Orchestrates Linux dev-environment setup: Docker, Nginx, PostgreSQL, shell tools, apps, and other workstation rituals. For when setting up a machine by hand starts to feel like a personality flaw. |
| [**dbm**](scripts/dbm) | Manages PostgreSQL dev databases: start `psql`, backup, reset, list configs, check connections, and handle credentials without turning your terminal into a secret-leaking confetti cannon. |
| [**f-create**](scripts/f-create) | Creates files and folders intelligently, with dry-run, undo, batch mode, permissions, and starter content. It is `mkdir` and `touch` after several cups of coffee. |
| [**gssw**](scripts/gssw) | Sets up Git commit signing with SSH or GPG, generates keys, configures Git, and helps you get those sweet "Verified" commits. |
| [**ngx**](scripts/ngx) | Creates and manages local Nginx static-site configs with custom domains, SSL, SPA routing, API proxying, dry-run mode, backups, and cleanup. |
| [**sato**](scripts/sato) | Monitors services and infrastructure with health checks, Docker/systemd awareness, maintenance mode, status UI, and self-healing features. Like a dashboard with opinions. |
| [**servault**](scripts/servault) | Connects to servers and databases using credentials from 1Password or Bitwarden. For teams that enjoy security and dislike password spreadsheets, as nature intended. |
| [**zsho**](scripts/zsho) | Installs and configures Zsh, Oh My Zsh, themes, plugins, backups, and default-shell setup. Makes your terminal less beige emotionally. |

Each script folder has its own README with examples, requirements, options, and any caveats hiding behind the curtain.

## 🧪 Tests

Some scripts include their own test runner:

```bash
./scripts/dbm/test-dbm.sh
./scripts/f-create/test-f-create.sh
./scripts/ngx/test-ngx.sh
./scripts/servault/test-servault.sh
./scripts/zsho/test-zsho.sh
```

Not every script has the same test setup yet. This is a toolbox, not a cathedral. A reasonably tidy toolbox, but still.

## ⚠️ Before You Run Things

Some scripts touch real system resources:

- `aetherix` may install packages and configure development tools.
- `ngx` may modify Nginx configs, SSL files, and `/etc/hosts`.
- `zsho` may change shell configuration and your default shell.
- `servault` opens SSH/database sessions.
- `dbm reset` can replace database contents, which is exciting in the same way a fire alarm is exciting.

Read the script README first, use dry-run modes where available, and do not aim production credentials at random commands just to see what happens. Future you has enough problems.

## 🧑‍🔧 Adding A New Script

To keep the installer and navigator happy, use this shape:

```text
scripts/
└── my-script/
    ├── my-script.sh
    ├── README.md
    └── test-my-script.sh      # optional, but appreciated by civilization
```

Then make it executable:

```bash
chmod +x scripts/my-script/my-script.sh
```

If the folder name and main `.sh` file match, `installer.sh` can discover it automatically.

## 🎉 Contributing

This repo is mostly personal automation, but useful fixes, better docs, and "hey, this script almost ate my laptop" reports are welcome.

PRs should try to:

- Keep each script self-contained
- Update the relevant script README
- Add or update tests when practical
- Preserve the mild terminal theatrics, because joy is a feature

## 📄 License

This repository is licensed under the **MIT License**.
See the [LICENSE](./LICENSE) file for details.
