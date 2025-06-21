# BrewFlow 🚀

**BrewFlow** automates routine processes such as updating, upgrading, and cleaning Homebrew. Normally, running these commands manually can be time consuming and cumbersome. With **BrewFlow**, you can quickly and easily execute all of them with a single command.

![GitHub Repo stars](https://img.shields.io/github/stars/yunusemreaydinli/brewflow)

## ✨ Features

- Real-time timing for each operation
- Intelligent error handling with `brew doctor`
- Deep cleanup options
- Sound notifications on macOS
- Cross-platform support: macOS, Linux, and WSL

## 🚀 Usage

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yunusemreaydinli/brewflow/main/brewflow.sh)
```

## 🛠️ What It Does

1. **`brew update`** - Updates Homebrew and fetches latest formulae
2. **`brew outdated`** - Shows packages that need updating
3. **`brew upgrade`** - Upgrades all outdated packages
   - Uses `--greedy` flag on macOS for comprehensive updates
4. **`brew cleanup --prune=1`** - Optional deep cleanup (removes old downloads)
5. **`brew doctor`** - Runs diagnostics when errors occur

## Notice

This script runs brew update, upgrade, and may upgrade packages you didn't explicitly choose. Proceed only if you accept this behavior.
