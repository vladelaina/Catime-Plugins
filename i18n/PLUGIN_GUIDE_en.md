# Catime Plugin Guide

## What is a Plugin?

A plugin is a script file that displays custom content in the Catime window. For example:

- 📺 Your Bilibili/YouTube video statistics
- 📈 Real-time NASDAQ and S&P 500 indices
- 🌤️ Local weather forecast
- 🌐 Your website traffic stats
- 💻 Server status
- ……

**Core concept: Any data your script can fetch can be displayed in the Catime window!**

Plus, this data can be placed anywhere on your screen and scaled to any size, just like Catime's time display — always visible without blocking other windows.

**How it works:** Your script writes to `output.txt` → Catime reads it → Displays in window. That simple!

> **Tip:** Make sure you have the required runtime environment installed (e.g., Python, Node.js, etc.)

---

## 30-Second Quick Start

Don't want to write code? Try it manually first:

### Step 1: Open Plugin Folder

Right-click Catime tray icon → `Plugins` → `Open Plugin Folder`

### Step 2: Edit output.txt

Find (or create) `output.txt` in the folder and write something:

```
Hello, Catime!
This is my first message 🎉
```

### Step 3: Display File Content

Right-click Catime tray icon → `Plugins` → `Show Plugin File`

**Done!** The Catime window now shows your content.

> This is the essence of plugins: **Whatever you write to output.txt appears in the window**.
> Plugin scripts just automate this process.

---

## Create Your First Plugin in 3 Steps

### Step 1: Open Plugin Folder

Right-click Catime tray icon → `Plugins` → `Open Plugin Folder`

### Step 2: Create Script File

Create a new file in this folder, e.g., `hello.py`:

```python
with open('output.txt', 'w', encoding='utf-8') as f:
    f.write('Hello, Catime!')
```

**Just a few lines!**

### Step 3: Run Plugin

1. Right-click Catime tray icon
2. `Plugins` → Click `hello.py`
3. First time it will ask if you trust it, click "Trust and Run"

**Done!** The window now shows "Hello, Catime!"

---

## Key Point

Whatever your script writes to `output.txt`, Catime displays it. The display auto-refreshes when the file updates.

---

## Special Tags (Optional)

Use these tags if needed:

| Tag | Function | Example |
|-----|----------|---------|
| `<md></md>` | Enable Markdown formatting | `<md>**bold** *italic*</md>` |
| `<catime></catime>` | Show timer time | `Running <catime></catime>` → `Running 00:05:30` |
| `<exit>N</exit>` | Auto-close plugin after N seconds | `<exit>5</exit>` → closes after 5 seconds |
| `<fps:N>` | Refresh N times per second (default 2, range 1-100) | `<fps:10>` → 10 refreshes per second |
| `<color:value></color>` | Set text color (supports gradients) | `<color:#FF0000>red</color>` |
| `<font:path></font>` | Set font (font file path) | `<font:C:\Windows\Fonts\comic.ttf>fun</font>` |
| `![](path)` | Display image (local path or URL) | `![](weather.png)` or `![](https://example.com/img.png)` |
| `![WxH](path)` | Display image with specific size | `![100x50](logo.png)` or `![200](logo.png)` (width only) |

> **About `<fps:N>`:** Default refresh is every 500ms (2 times per second). For fast-updating data, increase the rate up to `<fps:100>` (100 times per second).

> **About color and font:** These tags work standalone (no `<md>` needed) and can be nested. Font paths support absolute paths (e.g., `C:\Windows\Fonts\arial.ttf`), environment variables (e.g., `%WINDIR%\Fonts\arial.ttf`), or paths relative to the plugin directory.

---

## Supported Languages

Python, PowerShell, Batch, JavaScript... even Shell, Ruby, PHP, Lua and **90+ languages** are supported! As long as you have the interpreter installed, any language works.

> **Recommended:** Use **PowerShell (.ps1)** or **Batch (.bat)** — built into Windows, no installation needed, lower resource usage.

---

## Is it Safe?

When running a plugin for the first time, Catime will ask:

- **Cancel** = Don't run
- **Run Once** = Run this time only, will ask again next time
- **Trust and Run** = Always run automatically

If you modify a plugin file, Catime will ask again to prevent tampering.

---

## FAQ

### Plugin not showing content?

Check:
- File path is correct (script should write to `output.txt` in the same directory)
- Interpreter is installed (e.g., Python scripts need Python installed)

### How to stop a plugin?

Right-click tray icon → Plugins → Click the running plugin again (marked with ✓)

### Need to restart after editing?

No! Catime auto-detects changes and reruns the plugin (hot reload).

### Can I run multiple plugins?

No, only one at a time. Click another plugin to switch; the current one stops automatically.

### Do plugins keep running after closing Catime?

No. Catime stops all plugin processes when it closes.

---

## Notes

⚠️ **Avoid nested subprocesses**

Use a single process to complete tasks. If your script spawns subprocesses (e.g., using `start` in `.bat`), they may not be cleaned up properly.

---

**That's it! Now go create your first plugin!** 🚀
