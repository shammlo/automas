# 🔐 GSSW: Git Signing Setup Wizard 🪄

**Welcome, code conjurer**, to the **Git Signing Setup Wizard (GSSW)**
your magical one-stop spellbook for turning those boring, unverified commits into **officially enchanted artifacts**.

No more “⚠️ Unverified” warnings haunting your Git history like cursed ghosts!
**GSSW will hold your hand (metaphorically, of course) while you:**

- ✍️ **Sign every commit** with mystical **GPG** or **SSH seals**.
- 🔑 **Generate new cryptographic keys** (because nothing screams power like fresh keys 🔐).
- 🧙 **Auto-enable signed commits**, so you don’t have to chant `-S` every single time.
- 🚪 **Configure `ssh-agent`** to remember your secrets (so you don’t cry typing passphrases 47 times a day).

> _“A commit unsigned is like a spell without a wand, useless and easily forged.”_ ~ Ancient Git Sorcerer

---

## 🛠 Requirements

Before summoning GSSW, ensure you have:

- 🐧 **Linux (Ubuntu/Debian)**, **macOS**, or 🪟 **Windows (Git Bash/WSL)**.
- 🧙 **Bash 4+** (our spellbook language of choice).
- 🕵️ **Git** (obviously).
- **OpenSSH** (for SSH signing).
- **GPG** (only needed if you choose the GPG path).

---

## 🚀 Installation

Clone this enchanted repository:

```bash
git clone https://github.com/yourusername/RIGT-scripts.git
cd utilities/gssw
chmod +x gssw.sh
```

Run the wizard:

```bash
./gssw.sh
```

If you forget what it does (or just want to admire its purpose):

```bash
./gssw.sh -h
```

---

## ✨ Features

- **Detects your existing Git username and email** and sets defaults for you.
- **Generates new SSH or GPG keys** with a strong passphrase (no excuses 🔐).
- **Configures Git** to sign every commit by default.
- **Prints your public key** and guides you to add it to GitHub.
- **Auto-starts ssh-agent** on Linux, macOS, or Windows Git Bash.
- Works on **multiple platforms** without requiring black magic.

---

## 🧙 Usage

Just run:

```bash
./gssw.sh
```

Then follow the prompts. GSSW will:

1. Ask if you want to use **SSH** or **GPG** for signing.
2. Confirm your **Git username** and **email** (or use your defaults).
3. Generate and configure your key.
4. Tell you exactly what to add to GitHub.
5. Celebrate with you when your commits are officially **“Verified”** 🎉.

---

## 🕵️ Examples

### 1. **SSH Commit Signing**

```bash
./gssw.sh
🤔 Do you want to set up SSH or GPG for signing commits? [ssh/gpg] (default: ssh): ssh
```

Boom — SSH signing ready.

### 2. **GPG Commit Signing**

```bash
./gssw.sh
🤔 Do you want to set up SSH or GPG for signing commits? [ssh/gpg] (default: ssh): gpg
```

It will summon a powerful GPG key and link it to your Git.

---

## 🐞 Found a Bug?

Did GSSW misbehave? Maybe it refused to summon keys or exploded with cryptic errors?

- **Open a GitHub Issue** – Describe what went wrong, share logs, and maybe add a meme so we can debug with style.
- **Submit a Pull Request** – If you’re a brave wizard who’s already fixed the bug, send us your spell (code). We’ll review it faster than `git commit -S`.

> _“A bug ignored today becomes tomorrow’s feature request.”_ ~ Git Wizards Anonymous

---

## 🤔 FAQ

**Q:** _Does it work on Windows?_
**A:** Yes! GSSW detects if you're on Windows (Git Bash or WSL) and sets up your environment like a good little wizard.

**Q:** _Can I use my existing keys?_
**A:** Sure, GSSW will detect existing keys and suggest alternate filenames if needed.

**Q:** _What if I mess up?_
**A:** Relax — GSSW never destroys your keys. It only generates **new ones** with unique names if the defaults already exist.

**Q:** _Does it install GPG for me?_
**A:** Not currently. We respect your system's package management rituals. If you need GPG, just install it:

```bash
sudo apt install gnupg
```

---

## 🧛 Known Issues

- Doesn't make coffee ☕.
- Won't stop you from signing a commit like `fix: made it worse`.
- If you forget to add your key to GitHub, your commits may still scream **“Unverified”**. That's on you.

---

## 🎩 Final Words

Go forth and sign your commits, oh wizard of Git.
Your history shall now shine bright with **Verified seals**, and fewer “who the heck made this change?” moments.

**Run GSSW, rule your repos, and may your `git log` be ever clean.**
