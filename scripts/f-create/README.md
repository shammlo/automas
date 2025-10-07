# 🚀 f-create.sh – "The Rocket" File & Folder Creator

Tired of manually creating nested directories and files like some kind of digital caveman using basic `mkdir` and `touch` commands? Meet **f-create.sh "The Rocket"**! 🦕➡️🚀

This isn't just any ordinary Bash script – it's a **SUPERCHARGED** evolution from our simple "Zen Master" (`f-create-simplified.sh`)! It's a file creation wizard that's smarter than your average bear! 🐻🧠 It magically detects whether you're creating a **file** or a **folder**, gives you colorful feedback with more emojis than a teenager's text messages, and comes with enough features to make even the most demanding developers weep tears of joy! 😭✨

**Evolution Timeline:**

- 🦕 **Stone Age**: `mkdir folder && touch folder/file.txt` (manual labor)
- 🧘‍♂️ **The Zen Master**: `f-create-simplified.sh` (simple & focused)
- 🚀 **The Rocket**: `f-create.sh` (full-featured powerhouse!)

**What makes The Rocket so special?** Oh boy, where do we even start... 🎪

---

## 🚀 Features (The Full Monty)

- 📁 Creates nested directories step by step (like building LEGO, but faster)
- 📝 Creates files safely, with overwrite warnings (no accidental file murder)
- 📂 Auto-detects folders vs files (it's basically psychic)
- 🔧 Supports extensionless files (README, Dockerfile, etc.)
- ⚠️ Warns before overwriting (consent is important, even for files)
- 🔒 Validates paths to prevent digital disasters
- 🎯 Dry-run mode (commitment-phobic? We got you!)
- 🔄 Undo functionality (time travel for your filesystem)
- 📊 Batch processing (efficiency level: MAXIMUM)
- 🎨 Auto-content for common file types
- 🔧 Permission setting (chmod on steroids)
- 🎉 Colorful output + emojis (terminal happiness guaranteed)
- 🧪 Comprehensive test suite (27 tests and counting!)

---

## 💻 Installation

### The Easy Way (For Cool Kids)

Just clone your `automas` repo or copy the scripts somewhere handy:

```bash
chmod +x f-create.sh
chmod +x f-create-simplified.sh  # Optional: simpler version
chmod +x test-f-create.sh
```

### The Alias Way (For Efficiency Addicts)

Add to `~/.zshrc` or `~/.bashrc`:

```bash
alias create='~/path/to/f-create.sh'
alias create-zen='~/path/to/f-create-simplified.sh'  # For the Zen Master
alias test-create='~/path/to/test-f-create.sh'
```

Then reload your shell:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

Now you can simply type:

```bash
create demo/test --verbose --chmod 755
```

### The Smart Way (Auto-Detect Your Shell Like a Boss) 🤖

Want to set up aliases automatically without guessing your shell? Use this one-liner magic:

```bash
# Navigate to the script directory first
cd ~/path/to/your/scripts/f-create

# Auto-detect shell and add aliases (works with bash, zsh, fish, etc.)
echo "alias create='$(pwd)/f-create.sh'" >> ~/.$(basename "$SHELL")rc
echo "alias create-zen='$(pwd)/f-create-simplified.sh'" >> ~/.$(basename "$SHELL")rc
echo "alias test-create='$(pwd)/test-f-create.sh'" >> ~/.$(basename "$SHELL")rc

# Reload your shell config
source ~/.$(basename "$SHELL")rc
```

**What this does:**

- 🔍 **Auto-detects** your shell (bash → `.bashrc`, zsh → `.zshrc`, etc.)
- 📍 **Uses absolute paths** so it works from anywhere
- 🎯 **Sets up all three aliases** in one go
- 🔄 **Reloads immediately** so you can use them right away

### Verify It Worked 🎯

Test your new aliases:

```bash
create --help                    # Should show the full-featured help
create-zen --help                # Should show the Zen Master help
test-create                      # Should run the test suite
```

**Pro Tip:** If you want different alias names, just change `create` to whatever you prefer:

- `mk` for the minimalists
- `touch++` for the nostalgic
- `magic` for the dramatic
- `duck` for the... ducks? 🦆

---

## 🛠️ Usage Examples (Prepare to Be Amazed)

### Basic File Creation (The Classics Never Die)

```bash
./f-create.sh demo/demo.txt
```

Output (with extra sass):

```
ℹ️ Starting creation process for: 'demo/demo.txt' 🚀
ℹ️ Processing directory structure... 🏗️
✅ Created directory 'demo' 📂
ℹ️ Creating file... ✨
✅ Created empty file 'demo/demo.txt' 📝
✅ All done! Your file structure is ready! 🎉
✅ Operation completed successfully! 🎯
```

### Smart Folder Detection (Mind = Blown)

```bash
./f-create.sh demo/test/first
```

```
ℹ️ No extension detected, treating 'first' as a directory 📁
✅ Created directory 'demo/test/first' 📂
🎉 All done! Directory structure is ready! 🎉
```

### Force File Creation (When You're the Boss)

```bash
./f-create.sh README --file
```

```
🔍 Detected known extensionless file: README
ℹ️ Treating 'README' as a file (known extensionless file or forced)
✅ Created empty file 'README' 📝
```

### Content Magic (Auto-Fill FTW!)

```bash
./f-create.sh script.sh --chmod 755
```

```
✅ Created file 'script.sh' with content 📝
ℹ️ Set permissions to 755
```

Check the file:

```bash
cat script.sh
#!/bin/bash
```

### Custom Content (Your Wish is My Command)

```bash
./f-create.sh config.txt --content "# My awesome config"
```

### Batch Mode (Efficiency Level: OVER 9000!)

```bash
./f-create.sh file1.txt file2.js folder1/ folder2/subdir
```

```
ℹ️ Batch mode: Processing 4 paths...

ℹ️ [1/4] Processing: file1.txt
✅ Created empty file 'file1.txt' 📝

ℹ️ [2/4] Processing: file2.js
✅ Created file 'file2.js' with content 📝

ℹ️ [3/4] Processing: folder1/
✅ Created directory 'folder1' 📂

ℹ️ [4/4] Processing: folder2/subdir
✅ Created directory 'folder2/subdir' 📂

ℹ️ Batch completed: 4/4 successful
✅ Operation completed successfully! 🎯
```

### Dry Run (Commitment Issues? No Problem!)

```bash
./f-create.sh complex/structure/file.txt --dry-run
```

```
🔍 DRY RUN MODE - No actual changes will be made
ℹ️ [DRY RUN] Would create directory 'complex' 📂
ℹ️ [DRY RUN] Would create directory 'complex/structure' 📂
ℹ️ [DRY RUN] Would create empty file 'complex/structure/file.txt' 📝
```

### Undo Magic (Time Travel for Files!)

```bash
# Oops, made a mistake!
./f-create.sh --undo
```

```
ℹ️ Last operation: CREATE_FILE on 'oops.txt' at 2025-10-02 10:30:15
Do you want to undo this operation? (y/N): y
✅ Removed file: oops.txt
✅ Undo completed successfully! 🎯
```

### Preview Undo (Paranoid Mode)

```bash
./f-create.sh --undo --dry-run
```

```
ℹ️ Last operation: CREATE_DIR on 'test-dir' at 2025-10-02 10:25:30
ℹ️ [DRY RUN] Would undo: CREATE_DIR test-dir
```

---

## 🧘‍♂️ Want Something Simpler? (The Zen Master for Minimalists)

If all these Rocket features make your head spin and you just want the basics, we've got you covered! 🧘‍♂️

### f-create-simplified.sh ("The Zen Master")

For those who believe "less is more" and just want to create files and folders without the bells and whistles:

```bash
./f-create-simplified.sh demo/simple.txt
```

**What it does:**

- ✅ Creates files and nested directories
- ✅ Auto-detects folders (no extension = folder)
- ✅ Warns before overwriting files
- ✅ Colorful output with emojis
- ✅ Path validation for safety

**What it doesn't do:**

- ❌ No batch mode
- ❌ No undo functionality
- ❌ No auto-content
- ❌ No custom permissions
- ❌ No dry-run mode
- ❌ No verbose/quiet modes

**Perfect for:**

- 🎯 Quick file/folder creation
- 🚀 Learning the basics
- 🧘‍♂️ When you want simplicity
- 📚 Educational purposes

### 📊 The Rocket vs The Zen Master

| Feature              | 🧘‍♂️ Zen Master | 🚀 The Rocket |
| -------------------- | ------------- | ------------- |
| File/Folder Creation | ✅            | ✅            |
| Smart Detection      | ✅            | ✅            |
| Colorful Output      | ✅            | ✅            |
| Overwrite Protection | ✅            | ✅            |
| Batch Mode           | ❌            | ✅            |
| Undo Functionality   | ❌            | ✅            |
| Auto-Content         | ❌            | ✅            |
| Custom Permissions   | ❌            | ✅            |
| Dry-Run Mode         | ❌            | ✅            |
| Verbose/Quiet Modes  | ❌            | ✅            |
| Force Type Options   | ❌            | ✅            |
| History Tracking     | ❌            | ✅            |
| Backup System        | ❌            | ✅            |
| Test Suite           | ❌            | ✅            |

Choose your fighter: **🚀 The Rocket** (the Swiss Army knife) or **🧘‍♂️ The Zen Master** (the elegant katana)! ⚔️

---

## 🧪 Testing (Because We're Not Savages)

We've included a **comprehensive test suite** that's more thorough than a TSA security check! 🛂

### Run All Tests

```bash
./test-f-create.sh
```

Sample output (prepare for emoji overload):

```
🚀 Starting Comprehensive Test Suite for f-create-updated.sh
========================================================

🧪 Help Option Test
----------------------------------------
✅ PASS: Help option displays usage

🧪 Basic Functionality Tests
----------------------------------------
✅ PASS: Simple file creation
✅ PASS: Nested file creation
✅ PASS: Directory creation
✅ PASS: Directory creation with trailing slash

🧪 File Type Detection Tests
----------------------------------------
✅ PASS: Extensionless file: README
✅ PASS: Extensionless file: LICENSE
✅ PASS: Extensionless file: Dockerfile
✅ PASS: Extensionless file: Makefile
✅ PASS: Extensionless file: Gemfile

🧪 Undo Functionality Tests
----------------------------------------
✅ PASS: Undo with no history
✅ PASS: Undo file creation
✅ PASS: Undo directory creation
✅ PASS: Undo cancellation (file preserved)
✅ PASS: Undo dry-run mode
✅ PASS: Undo order (last operation first)

========================================================
📊 Test Summary
========================================================
Total Tests: 27
Passed: 32
Failed: 0

🎉 All tests passed! The script is working correctly.
```

### What Gets Tested (Everything!)

- ✅ Basic file/folder creation
- ✅ Nested path handling
- ✅ Extensionless file detection
- ✅ Force type options (`--file`, `--dir`)
- ✅ Content options (custom & auto-content)
- ✅ Permission setting (`--chmod`)
- ✅ Batch mode processing
- ✅ Dry-run functionality
- ✅ Quiet/verbose modes
- ✅ Undo functionality (all scenarios)
- ✅ Error handling & edge cases
- ✅ Help system

---

## 🎯 Command Reference (Your Cheat Sheet)

| Command           | Description                   | Example                               |
| ----------------- | ----------------------------- | ------------------------------------- |
| `--help`, `-h`    | Show help (obviously)         | `./script --help`                     |
| `--file`, `-f`    | Force treat as file           | `./script README --file`              |
| `--dir`, `-d`     | Force treat as directory      | `./script script.js --dir`            |
| `--content`, `-c` | Add custom content            | `./script file.txt --content "Hello"` |
| `--chmod`         | Set permissions               | `./script script.sh --chmod 755`      |
| `--edit`, `-e`    | Open in editor after creation | `./script file.txt --edit`            |
| `--dry-run`, `-n` | Preview without creating      | `./script file.txt --dry-run`         |
| `--quiet`, `-q`   | Minimal output                | `./script file.txt --quiet`           |
| `--verbose`, `-v` | Detailed output               | `./script file.txt --verbose`         |
| `--undo`, `-u`    | Undo last operation           | `./script --undo`                     |

---

## 🎪 Advanced Wizardry

### Combining Options (Mix & Match!)

```bash
# Create executable script with custom content in verbose mode
./f-create.sh deploy.sh --content "#!/bin/bash\necho 'Deploying...'" --chmod 755 --verbose

# Batch create with dry-run
./f-create.sh file1.txt file2.js folder/ --dry-run --verbose

# Undo with preview
./f-create.sh --undo --dry-run

# Or keep it simple with the Zen Master
./f-create-simplified.sh just/a/simple/file.txt
```

### Pro Tips (From the Trenches)

1. **Extensionless Files**: The script knows about `README`, `LICENSE`, `Dockerfile`, `Makefile`, `Gemfile`, `Procfile`, `Vagrantfile` – they're automatically treated as files! 🤓

2. **Batch Undo**: Each operation is logged separately, so you can undo them one by one in reverse order! 🔄

3. **Safety First**: Files are backed up before being removed during undo operations (check `[script-dir]/.f-create-backups/`) 🛡️

4. **History Tracking**: All operations are logged in `[script-dir]/.f-create-history` for undo functionality 📚

5. **Path Validation**: The script prevents dangerous operations (like `../../../etc/passwd`) 🚨

---

## 🐛 Troubleshooting (When Things Go Sideways)

### "No history file found"

- You haven't created anything yet, or the history file was deleted
- Solution: Create something first! 🤷‍♂️

### "Directory not empty" during undo

- The directory has files that weren't created by this script
- Solution: Use `rm -rf directory` if you're sure, or clean it manually 🧹

### Permission denied

- You don't have write permissions in the target directory
- Solution: Check your permissions or use `sudo` (carefully!) 👮‍♂️

### Script hangs during undo

- You're in interactive mode and need to answer y/N
- Solution: Use `--dry-run` to preview, or pipe input: `echo "y" | ./script --undo` 🤖

---

## 📚 Understanding the History File (The Magic Behind Undo)

Ever wondered how the undo functionality works? Meet the `.f-create-history` file – the unsung hero of time travel! 🕰️✨

### 🎯 What Is It?

The `.f-create-history` file is a **log file** that tracks every single operation performed by f-create. Think of it as your script's diary! 📖

**Location**: `[script-directory]/.f-create-history`

### 📝 Format (Simple but Powerful)

Each line follows this pattern:

```
TIMESTAMP|OPERATION_TYPE|PATH
```

**Real example:**

```
2025-10-02 10:30:15|CREATE_FILE|demo/awesome.txt
2025-10-02 10:30:22|CREATE_DIR|projects/new-idea
2025-10-02 10:30:35|CREATE_FILE|scripts/deploy.sh
```

### 🔍 Operation Types

- **`CREATE_FILE`** - When a file is created
- **`CREATE_DIR`** - When a directory is created

### 🔄 How Undo Uses It

1. **Reads the last line** to find the most recent operation
2. **Shows you what will be undone** (timestamp, type, path)
3. **Performs the reverse operation**:
   - `CREATE_FILE` → Delete the file (with backup)
   - `CREATE_DIR` → Remove the directory (if empty)
4. **Removes that line** from history (so you can undo multiple operations)

### 🛡️ Safety Features

- **Automatic Backups**: Files are backed up before deletion during undo
- **Directory Safety**: Only removes empty directories
- **Persistent History**: Survives script restarts and system reboots
- **Multiple Undos**: Can undo operations one by one in reverse order

### 🔧 Manual Management (For Power Users)

**View your history:**

```bash
cat scripts/f-create/.f-create-history
```

**Clear history (careful!):**

```bash
rm scripts/f-create/.f-create-history
```

**Backup your history:**

```bash
cp scripts/f-create/.f-create-history my-f-create-backup.txt
```

### 🎭 Fun Facts

- 📊 Each operation gets a precise timestamp (down to the second)
- 🔄 The file grows with each operation but stays lightweight
- 🧹 No automatic cleanup – it's your permanent record!
- 🚀 Works across different terminal sessions and directories
- 🎯 Only tracks successful operations (failed attempts aren't logged)

**Pro Tip**: If you're curious about what you've been creating, just peek at the history file – it's like a timeline of your productivity! 📈

---

## 🤝 Contributing (Join the Fun!)

Have an idea? Found a bug? Want to add more emojis?

1. Fork the repo 🍴
2. Create a feature branch 🌿
3. Add tests (we're serious about this!) 🧪
4. Submit a PR with a humorous description 📝
5. Keep emojis intact – happiness is mandatory! 😄

### Contribution Guidelines

- **Tests are mandatory** – if it's not tested, it doesn't exist! 🧪
- **Emojis are encouraged** – the more, the merrier! 🎉
- **Humor is appreciated** – make us laugh! 😂
- **Documentation updates** – if you add features, document them! 📚

---

## 📄 License

This script is licensed under the **MIT License**.
See the [LICENSE](../../LICENSE) file for details.

**TL;DR**: Do whatever you want with it, just don't blame us if your computer gains sentience and starts creating files on its own! 🤖👻

---

## 🎭 Final Words

Remember: Life's too short for manual file creation! Let the wizard handle it while you focus on more important things... like arguing about tabs vs spaces! 🥊

**May your directories be nested and your files be blessed!** 🙏✨

---

_P.S. If this script doesn't make you smile at least once, you might need to check if you still have a soul. We accept no responsibility for existential crises caused by excessive automation._ 😈💀
