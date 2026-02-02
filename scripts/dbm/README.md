# 🧙‍♂️ DBM: The Magical PostgreSQL Whisperer 🧙‍♀️

Welcome, adventurer, to the realm of **DBM** — _Database Manager_ — a mystical Bash-powered spellbook that lets you:

- 💣 **Reset** your dev database (when you've broken everything. Again.)
- 📂 **Backup** your database (so you can break it _with confidence_)
- 🚀 **Start** a `psql` shell (like a wizard opening a portal)
- 🔐 **Flexible credentials** - env vars, config files, or .pgpass support
- 🌐 **Remote databases** - connect to any PostgreSQL server, anywhere
- 🛡️ **Security-first** - multiple authentication methods for every use case

> _"May your queries be fast and your backups frequent."_ — Ancient PostgreSQL Proverb

---

## 🛠 Requirements

To run this ancient spell, you'll need:

- 🐧 **Linux** or macOS
- 🐘 **PostgreSQL client** tools (`psql`, `pg_dump`) installed
- 🧙‍♂️ **Bash 4+** (so we can use associative arrays like pros)
- 🚨 A sense of humor (seriously, this README depends on it)

---

## 📦 Setup

DBM now supports **multiple flexible credential methods** for maximum security and convenience:

### 🔐 **Method 1: Config File (Recommended for Teams)**

Create `.dbmrc` in the DBM script folder with one of these **10 supported formats**:

> **🔒 Security Note**: The `.dbmrc` file is ignored by git to protect your credentials.
> Use the provided `.dbmrc.template` as a starting point:
>
> ```bash
> cp .dbmrc.template .dbmrc
> # Edit .dbmrc with your actual credentials
> ```

```ini
# Format 1: Password via PGPASSWORD env var (most secure)
duck=duck_user::5432:duck_db
dragon=dragon_keeper::5433:dragon_lair

# Format 2: Password in config (less secure, but convenient)
phoenix=fire_admin:secret123:5434:phoenix_nest

# Format 3: Custom host support
remote=admin:pass123:5432:mydb:db.example.com

# Format 4: SSL-enabled connection
secure_db=admin:secure_pass:5432:production_db:db.example.com:require

# Format 5: SSL with client certificate
enterprise=enterprise_user:enterprise_pass:5432:enterprise_db:enterprise.example.com:verify-full:/path/to/client.crt

# Format 6: Full PostgreSQL URI (most flexible)
cloud_db=postgres://user:password@cloud.example.com:5432/clouddb?sslmode=require&sslcert=/path/to/client.crt

# Format 7: Azure PostgreSQL with SSL
azure_db=postgres://username%40server:password@server.postgres.database.azure.com:5432/database?sslmode=require

# Format 8: Legacy 3-part format (backward compatibility)
legacy_db=username:5432:database

# Format 9: Password same as username (common pattern)
webapp=webapp:webapp:5433:webapp_db
myapp=myapp:myapp:5432:myapp_database

# Format 10: Local development
local=postgres::5432:dev_db:localhost
```

### 🌍 **Method 2: Environment Variables (Secure & Flexible)**

```bash
# Basic setup
export DUCK_USER=duck_user
export DUCK_PORT=5432
export DUCK_DB=duck_db

# With password (more secure than config file)
export DRAGON_USER=dragon_keeper
export DRAGON_PASSWORD=secret123
export DRAGON_PORT=5433
export DRAGON_DB=dragon_lair

# With custom host
export PHOENIX_USER=fire_admin
export PHOENIX_PASSWORD=phoenix_secret
export PHOENIX_PORT=5434
export PHOENIX_DB=phoenix_nest
export PHOENIX_HOST=phoenix.example.com
```

### 🔑 **Method 3: Password = Username Pattern**

For databases where the password is the same as the username (common in development):

```bash
# In .dbmrc - password same as username
myproject=myproject:myproject:5432:myproject_db
webapp=webapp:webapp:5433:webapp_database

# Legacy 3-part format (automatically uses username as password)
oldproject=oldproject:5432:oldproject_db
```

### 🔑 **Method 4: Global PGPASSWORD (Quick & Dirty)**

```bash
# Set global password for all connections
export PGPASSWORD=your_password

# Then use simple config format
echo "duck=duck_user::5432:duck_db" >> scripts/dbm/.dbmrc
```

### 🛡️ **Method 5: PostgreSQL .pgpass File (Most Secure)**

Create `~/.pgpass` with the format `hostname:port:database:username:password`:

```bash
# ~/.pgpass file format
localhost:5432:mydb:myuser:mypassword
db.example.com:5432:production:admin:secret123
```

Set proper permissions:

```bash
chmod 600 ~/.pgpass
```

### 🛡️ **Security Priority (Most to Least Secure):**

1. **PostgreSQL .pgpass file** - Native PostgreSQL credential management
2. **Environment variables** - Passwords not stored in files
3. **PGPASSWORD + simple config** - Password separate from connection details
4. **Password in config file** - Convenient but less secure
5. **Interactive prompt** - Manual entry each time

> 🪄 **Magic Fallback System:** DBM tries .pgpass first, then config file, then environment variables, then PGPASSWORD, ensuring maximum security and flexibility!

---

## 🔒 SSL & Security Features

DBM now supports **enterprise-grade security** with multiple SSL modes and authentication methods:

### 🌐 **SSL Connection Modes**

| SSL Mode      | Description                               | Use Case                |
| ------------- | ----------------------------------------- | ----------------------- |
| `disable`     | No SSL encryption                         | Local development only  |
| `allow`       | Try non-SSL first, then SSL               | Legacy compatibility    |
| `prefer`      | Try SSL first, fallback to non-SSL        | Flexible environments   |
| `require`     | SSL required, no certificate verification | Basic security          |
| `verify-ca`   | SSL + verify certificate authority        | Production environments |
| `verify-full` | SSL + verify CA + hostname                | Maximum security        |

### 🔑 **Client Certificate Authentication**

For enterprise environments requiring client certificates:

```ini
# .dbmrc format with client certificate
enterprise=user:pass:5432:db:host.example.com:verify-full:/path/to/client.crt
```

### ☁️ **Cloud Database Support**

Perfect for connecting to cloud providers:

```ini
# AWS RDS
aws_db=postgres://user:pass@rds-instance.region.rds.amazonaws.com:5432/db?sslmode=require

# Google Cloud SQL
gcp_db=postgres://user:pass@public-ip:5432/db?sslmode=require

# Azure Database
azure_db=postgres://user%40server:pass@server.postgres.database.azure.com:5432/db?sslmode=require
```

---

## 🧙 Usage

```bash
./dbm.sh <action> <project> [args] [options]
```

### Actions

| Action   | Alias | Description                           |
| -------- | ----- | ------------------------------------- |
| `start`  | `s`   | 🚀 Start interactive `psql` shell     |
| `reset`  | `r`   | 🔄 Reset database from a `.psql` file |
| `backup` | `b`   | 📂 Dump database to a `.psql` file    |
| `list`   | `l`   | 📚 Show available configs             |
| `check`  | `c`   | 🔍 Test database connection           |
| `info`   | `i`   | 📊 Show database information          |
| `config` |       | ⚙️ Manage project configurations      |

### Global Options

- `--debug` = 🪫 Enable internal debug logs (for nerds who like to peek behind the curtain)
- `--help` / `-h` = ℹ️ Show comprehensive help and usage information

### Action Options

- `-o` / `--overwrite` = ⚠️ Overwrite existing files in `backup`, in case you fat-fingered Enter and saved it as `final_v2_but_actually_final.psql` 🙃
- `--all` = 🌐 Test all configured projects (for `check` command)
- `--tables` = 📋 Show table list (for `info` command)
- `--size` = 💾 Show size details (for `info` command)

### Examples

```bash
# Basic database operations
./dbm.sh start duck
./dbm.sh reset dragon ./dragon-reset.sql
./dbm.sh backup phoenix ~/backup-phoenix.psql -o
./dbm.sh list

# Connection testing
./dbm.sh check duck
./dbm.sh check --all

# Database information
./dbm.sh info phoenix
./dbm.sh info duck --tables
./dbm.sh info dragon --size --tables

# Configuration management
./dbm.sh config add newdb user:pass:5432:database
./dbm.sh config remove olddb
./dbm.sh config edit myproject

# Debug mode
./dbm.sh --debug start duck
./dbm.sh --debug check --all
```

---

## 🎯 **New Powerful Commands**

### 🔍 **Connection Testing (`check`)**

Test database connections without opening a shell:

```bash
# Test single database
./dbm.sh check duck
./dbm.sh c dragon

# Test all configured databases
./dbm.sh check --all

# With debug output
./dbm.sh --debug check --all
```

**Perfect for:** Health checks, CI/CD pipelines, monitoring scripts, troubleshooting connectivity issues.

### 📊 **Database Information (`info`)**

Get detailed database information and statistics:

```bash
# Basic database info (version, size, connections, tables)
./dbm.sh info phoenix
./dbm.sh i duck

# Include table listing
./dbm.sh info dragon --tables

# Include size breakdown of largest tables
./dbm.sh info phoenix --size

# Everything together
./dbm.sh info duck --tables --size
```

**Perfect for:** Database monitoring, capacity planning, quick health checks, documentation.

### ⚙️ **Configuration Management (`config`)**

Manage your database projects interactively:

```bash
# Add new database project
./dbm.sh config add myproject user:password:5432:database:host

# Remove existing project
./dbm.sh config remove oldproject

# Edit existing project configuration
./dbm.sh config edit myproject
```

**Perfect for:** Team onboarding, dynamic environments, configuration updates, project management.

---

## 🤔 How It Works

1. **Loads config** from `.dbmrc` (if it exists)
2. If not found, **tries environment variables** (`PROJECT_USER`, etc.)
3. Constructs the connection string like a SQL bard
4. Runs the appropriate `psql` or `pg_dump` incantation
5. Celebrates or crashes, depending on how good your spell was 🧙‍♂️

---

## 📋 **Quick Command Reference**

| Command                          | Purpose              | Example                                 |
| -------------------------------- | -------------------- | --------------------------------------- |
| `dbm list`                       | Show all projects    | `dbm l`                                 |
| `dbm start <project>`            | Open database shell  | `dbm s duck`                            |
| `dbm check <project>`            | Test connection      | `dbm c dragon`                          |
| `dbm check --all`                | Test all connections | `dbm c --all`                           |
| `dbm info <project>`             | Show DB information  | `dbm i phoenix`                         |
| `dbm info <project> --tables`    | Show tables          | `dbm i duck --tables`                   |
| `dbm backup <project> <file>`    | Create backup        | `dbm b duck ~/backup.psql`              |
| `dbm reset <project> <file>`     | Restore from backup  | `dbm r duck ~/backup.sql`               |
| `dbm config add <name> <config>` | Add new project      | `dbm config add test user:pass:5432:db` |
| `dbm config remove <name>`       | Remove project       | `dbm config rm test`                    |
| `dbm --debug <command>`          | Debug any command    | `dbm --debug check --all`               |

---

## 🧼 Clean Console, Please!

By default, DBM keeps things tidy. Want to see the guts? Add `--debug` for juicy internals like:

```
🧪 get_project_config called with project_name: 'duck'
🧪 Values found: DUCK_USER=duck_user, DUCK_PORT=5432, DUCK_DB=duck_db
✅ Final fallback config: duck_user:5432:duck_db
```

---

## 🧙 Terminal Wizardry (For Bash/Zsh Wielders)

If you **really love magic**, and want to summon `dbm` from anywhere in your terminal, do this:

```bash
echo "alias dbm='~/path/to/automas/scripts/dbm/dbm.sh'" >> ~/.$(basename "$SHELL")rc
```

Then reload your shell to complete the ritual:

```bash
source ~/.$(basename "$SHELL")rc
```

Boom. You're now a **CLI wizard**. Drop tables, purge data, and rewrite database history like a command-line time traveler. 🧙‍♂️💾

> Just don't alias it in **fish**, **csh**, or **tcsh**.
> You'll offend **PostgreSQL**, and it will exile you to a life of storing data in `.txt` files.
> **Your next database will be called `spreadsheet_final_v9.csv`. Don't do it.**

---

## 💡 Pro Tips

- Add your exports to `~/.bashrc` or `~/.zshrc` to make them permanent ✨
- The `.dbmrc` file supports multiple formats from simple `key=user:port:db` to full URIs, simple, readable, huggable ❤️
- Use `list` to see what DBM knows about your magical database kingdoms
- Backup files automatically get `.psql` extension (because we're civilized wizards)
- The script expands `~` in file paths like a proper gentleman 🎩

---

## 🐛 Troubleshooting Spells

### When PostgreSQL Refuses Your Connection (The "Access Denied" Curse)

```bash
# Check if the database daemon is awake
sudo systemctl status postgresql

# Verify your credentials aren't cursed
./dbm.sh --debug start dragon

# Test the ancient connection ritual manually
psql -U username -d database -h localhost -p 5432
```

### When Your Backup File Vanishes (The "Where Did I Put That?" Hex)

```bash
# Summon the file location spell
ls -la ~/your-backup.psql

# Use absolute paths to break the confusion curse
./dbm.sh backup duck /full/path/to/backup.psql
```

### When Everything Goes Wrong (The Nuclear Option)

```bash
# Enable maximum debug wizardry
./dbm.sh --debug backup phoenix ~/debug-backup.psql

# This reveals:
# - Which config file DBM is reading (or trying to read)
# - What connection parameters it parsed
# - The exact pg_dump command it's running
# - Whether PostgreSQL is cooperating or being difficult
```

---

## 🧛 Known Issues

- Doesn't make coffee ☕
- Won't stop you from running `DROP DATABASE` in production 😱
- Bash doesn't support spaces in associative array keys, stick to `snake_case`, my dude 🐍
- May cause excessive confidence in database management abilities
- Side effects include: cleaner backup workflows, reduced typing, and occasional wizard-like feelings

---

## 🧪 Testing Your Spells

Run the included test grimoire to make sure your magic works:

```bash
./test-dbm.sh
```

If all spells pass, you'll see:

```
🎉 All tests passed! The DBM script is working correctly.
```

If something's broken, the test will tell you exactly which spell failed and why. No more guessing games with mysterious database errors!

---

## 🎭 Advanced Wizardry

### For Database Necromancers (Production Users):

- Always test your restore spells in a safe dungeon (staging environment) first
- Keep multiple backup scrolls for critical databases
- Use descriptive filenames with timestamps: `dragon-$(date +%Y%m%d-%H%M%S).psql`

### For Apprentice Developers:

- Set up your config file once and forget about connection strings forever
- Use short commands (`b`, `r`, `s`) to cast spells faster
- Enable debug mode when learning new database territories

### For Team Leaders:

- Share your `.dbmrc` format in team documentation
- Include DBM commands in deployment scripts
- Train your minions in the ancient arts of database backup

---

## 🫶 Contributing

Want to add features? Spells? Emojis? Fork away, wizard! PRs are welcome, especially if they:

- Add more database magic (MySQL support? MongoDB spells?)
- Improve error messages (make them funnier!)
- Add more tests (because even wizards need quality assurance)
- Fix bugs (squash those digital gremlins!)

---

## 🧙 Final Words

Use wisely. Backup often. Laugh always.

Go break your dev DB. Don't worry, you've got all-new spells to vanquish those monsters! 🪄

Remember: **A wizard is never late with their backups, nor are they early. They backup precisely when they mean to.**

_May your connections be stable, your queries be optimized, and may you never have to explain to your boss why the production database contains only the word "oops" repeated 47 times._ 🙏✨
