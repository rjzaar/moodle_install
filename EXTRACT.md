# 📦 Moodle Installation Suite - Extraction Guide

## Download and Extract

### Option 1: Extract on Server

```bash
# Upload the tar.gz file to your server, then:
tar -xzf moodle-installation-suite.tar.gz

# Make scripts executable
bash setup.sh

# Run installer
sudo ./install-moodle.sh
```

### Option 2: Extract on Local Machine

```bash
# Extract locally
tar -xzf moodle-installation-suite.tar.gz

# View contents
ls -lh

# Read documentation
cat QUICKSTART.md

# Then upload files to your server
```

---

## 📋 What's Inside (9 files)

### Scripts (4 files)
- `setup.sh` - Makes other scripts executable
- `install-moodle.sh` - Main installer (35KB)
- `troubleshoot-moodle.sh` - Diagnostic tool (31KB)
- `moodle-status.sh` - Status checker (5.6KB)

### Documentation (5 files)
- `QUICKSTART.md` - Quick start guide
- `README.md` - Complete documentation
- `INSTALL_README.md` - Installer details
- `FILE_MANIFEST.md` - File descriptions
- `moodle-ubuntu-nginx-installation-guide.md` - Manual guide

---

## 🚀 Quick Installation

```bash
# 1. Extract
tar -xzf moodle-installation-suite.tar.gz

# 2. Enter directory
cd moodle-installation-suite  # or wherever you extracted

# 3. Setup
bash setup.sh

# 4. Install
sudo ./install-moodle.sh
```

That's it! The script handles everything automatically.

---

## 📝 Verification

After extraction, verify all files:

```bash
# Check files exist
ls -lh

# Expected output:
# - 4 .sh files (scripts)
# - 5 .md files (documentation)
```

---

## 🔒 Security Note

These scripts require root access. Please:
1. Review the scripts before running
2. Understand what they do
3. Run on a test system first if possible
4. Backup any existing data

---

## 📚 Next Steps

1. Read `QUICKSTART.md` first (3 min read)
2. Run `bash setup.sh` to make scripts executable
3. Run `sudo ./install-moodle.sh` to install
4. Complete web installation at http://your-domain

For detailed documentation, see `README.md`

---

**Archive**: moodle-installation-suite.tar.gz  
**Size**: 34KB compressed (147KB uncompressed)  
**Version**: 1.0  
**Date**: November 8, 2025
