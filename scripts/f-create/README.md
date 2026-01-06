# 🚀 f-create.sh – "The Rocket" File & Folder Creator

Tired of manually creating nested directories and files like some kind of digital caveman using basic `mkdir` and `touch` commands? Meet **f-create.sh "The Rocket"**! 🦕➡️🚀

This isn't just any ordinary Bash script, it's a **SUPERCHARGED** evolution from our simple "Zen Master" (`f-create-simplified.sh`)! It's a file creation wizard that's smarter than your average bear! 🐻🧠 It magically detects whether you're creating a **file** or a **folder**, gives you colorful feedback with more emojis than a teenager's text messages, and comes with enough features to make even the most demanding developers weep tears of joy! 😭✨

**Evolution Timeline:**

- 🦕 **Stone Age**: `mkdir folder && touch folder/file.txt` (manual labor)
- 🧘‍♂️ **The Zen Master**: `f-create-simplified.sh` (simple & focused)
- 🚀 **The Rocket**: `f-create.sh` (full-featured powerhouse!)

**What makes The Rocket so special?** Oh boy, where do we even start... 🎪

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

#### Single Operation Undo

```bash
# Oops, made a mistake!
./f-create.sh --undo
```

```
ℹ️ Found last batch: batch_20251215_103402_46816
ℹ️ Batch contains 1 operations (originally 1 paths)
ℹ️ Operations to undo:
  - CREATE_FILE: oops.txt
Do you want to undo this entire batch? (y/N): y
⏳ Undoing: CREATE_FILE oops.txt
✅ Removed file: oops.txt
✅ Batch undo completed: 1/1 operations successful! 🎯
```

#### Batch Undo (The Real Magic!)

When you create multiple files/directories in one command, they're treated as a **batch**. Undo removes the **entire batch** at once!

```bash
# Create a batch of files and directories
./f-create.sh file1.txt file2.js dir1/ dir2/nested.py

# Undo the ENTIRE batch with one command
./f-create.sh --undo
```

```
ℹ️ Found last batch: batch_20251215_103402_46816
ℹ️ Batch contains 5 operations (originally 4 paths)
ℹ️ Operations to undo:
  - CREATE_FILE: dir2/nested.py
  - CREATE_DIR: dir2
  - CREATE_DIR: dir1
  - CREATE_FILE: file2.js
  - CREATE_FILE: file1.txt
Do you want to undo this entire batch? (y/N): y
⏳ Undoing: CREATE_FILE dir2/nested.py
✅ Removed file: dir2/nested.py
⏳ Undoing: CREATE_DIR dir2
✅ Removed directory: dir2
⏳ Undoing: CREATE_DIR dir1
✅ Removed directory: dir1
⏳ Undoing: CREATE_FILE file2.js
✅ Removed file: file2.js
⏳ Undoing: CREATE_FILE file1.txt
✅ Removed file: file1.txt
✅ Batch undo completed: 5/5 operations successful! 🎯
```

#### Multiple Batches (Smart Undo)

If you run multiple separate commands, each gets its own batch ID. Undo only affects the **last batch**:

```bash
# First batch
./f-create.sh batch1_file.txt batch1_dir/

# Second batch
./f-create.sh batch2_file.txt batch2_dir/

# Undo only removes the second batch!
./f-create.sh --undo  # Only batch2_* items are removed
```

### Preview Undo (Paranoid Mode)

```bash
./f-create.sh --undo --dry-run
```

```
ℹ️ Found last batch: batch_20251215_103402_46816
ℹ️ Batch contains 3 operations (originally 2 paths)
ℹ️ Operations to undo:
  - CREATE_FILE: test-dir/file.txt
  - CREATE_DIR: test-dir
  - CREATE_FILE: simple.txt
ℹ️ [DRY RUN] Would undo entire batch batch_20251215_103402_46816
```

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

2. **Batch Undo**: Operations from the same command are grouped into batches with unique IDs. Undo removes the entire last batch at once! 🔄

3. **Safety First**: Files are backed up before being removed during undo operations (check `[script-dir]/.f-create-backups/`) 🛡️

4. **History Tracking**: All operations are logged in `[script-dir]/.f-create-history` for undo functionality 📚

5. **Path Validation**: The script prevents dangerous operations (like `../../../etc/passwd`) 🚨

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

## 📚 Understanding the History File (The Magic Behind Undo)

Ever wondered how the undo functionality works? Meet the `.f-create-history` file – the unsung hero of time travel! 🕰️✨

### 🎯 What Is It?

The `.f-create-history` file is a **log file** that tracks every single operation performed by f-create. Think of it as your script's diary! 📖

**Location**: `[script-directory]/.f-create-history`

### 📝 Format (Enhanced with Batch Tracking)

Each line follows this pattern:

```
TIMESTAMP|BATCH_ID|OPERATION_TYPE|PATH
```

**Real example:**

```
2025-12-15 10:34:02|batch_20251215_103402_46816|BATCH_START|4
2025-12-15 10:34:02|batch_20251215_103402_46816|CREATE_FILE|demo/awesome.txt
2025-12-15 10:34:02|batch_20251215_103402_46816|CREATE_DIR|projects/new-idea
2025-12-15 10:34:02|batch_20251215_103402_46816|CREATE_FILE|scripts/deploy.sh
2025-12-15 10:34:02|batch_20251215_103402_46816|BATCH_END|3/4
```

### 🔍 Operation Types

- **`BATCH_START`** - Marks the beginning of a batch (with path count)
- **`CREATE_FILE`** - When a file is created
- **`CREATE_DIR`** - When a directory is created
- **`BATCH_END`** - Marks the end of a batch (with success/total count)

### 🔄 How Batch Undo Uses It

1. **Finds the last completed batch** by looking for the most recent `BATCH_END`
2. **Collects all operations** from that batch ID
3. **Shows you the entire batch** that will be undone
4. **Performs reverse operations in reverse order**:
   - `CREATE_FILE` → Delete the file (with backup)
   - `CREATE_DIR` → Remove the directory (if empty)
5. **Removes the entire batch** from history (all lines with that batch ID)

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
- 🆔 Each command gets a unique batch ID (timestamp + process ID)
- 🔄 The file grows with each operation but stays lightweight
- 🧹 No automatic cleanup – it's your permanent record!
- 🚀 Works across different terminal sessions and directories
- 🎯 Only tracks successful operations (failed attempts aren't logged)
- 🎪 Batch markers help organize operations into logical groups

**Pro Tip**: If you're curious about what you've been creating, just peek at the history file – it's like a timeline of your productivity! 📈

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

## 📄 License

This script is licensed under the **MIT License**.
See the [LICENSE](../../LICENSE) file for details.

**TL;DR**: Do whatever you want with it, just don't blame us if your computer gains sentience and starts creating files on its own! 🤖👻

## 🎭 Final Words

Remember: Life's too short for manual file creation! Let the wizard handle it while you focus on more important things... like arguing about tabs vs spaces! 🥊

**May your directories be nested and your files be blessed!** 🙏✨

_P.S. If this script doesn't make you smile at least once, you might need to check if you still have a soul. We accept no responsibility for existential crises caused by excessive automation._ 😈💀
