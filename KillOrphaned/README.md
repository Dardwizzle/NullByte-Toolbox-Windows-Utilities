<p align="center">
  <img src="NullByte.png" alt="NullByte Logo" width="200">
</p>

[![Version](https://img.shields.io/badge/version-v1.2.0-blue)](https://github.com/Dardwizzle/NullByte-Toolbox-Windows-Utilities/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# NullByte Toolbox – Windows Utilities Collection

[![Download](https://img.shields.io/github/v/release/Dardwizzle/NullByte-Toolbox-Windows-Utilities?label=Download%20Latest&style=for-the-badge)](https://github.com/Dardwizzle/NullByte-Toolbox-Windows-Utilities/releases/latest)

A growing collection of Windows utilities designed to improve daily workflow, automate repetitive tasks, and provide fast access to common system functions.

This toolbox is built and maintained by **John (DarDwizzle)** and is intended as a personal utility suite that will expand over time.

---

## 🚀 Current Tools

### **KillOrphaned**
A utility that terminates orphaned browser processes (Chrome, Edge, etc.) that remain running after the browser is closed.

- Frees RAM and CPU
- Helps prevent system slowdowns
- Useful for gaming or heavy multitasking

Executable and PowerShell versions included.

---

## 📁 Project Structure
I:\NullByte-KillOrphaned\
	|- KillOrphaned.exe
	|- KillOrphaned.ps1
	|- NullByte.png
	|- NullByteOrphans1.ico
	|- LICENSE

---

Finished tools can deployed to in order to be sure this folder 
is added to the system PATH for easy access:

  C:\Program Files (x86)\Scripts\

.
NOTE: Where ever you decide to unpack this zip file, 
KillOrphaned.exe requires NullByte.png and NullByteOrphans1.ico to be in the same folder. 
These files are included in the ZIP. If you receive an error about missing assets, ensure 
all files remain together in the scripts folder.
---

## 🔧 How to Use

1. Download the latest release from the **Releases** section.
2. Place the executable in your Scripts directory (or where ever you feel comfortable:
  C:\Program Files (x86)\Scripts\
3. Run from Start Menu, Run dialog, or PowerShell:
   KillOrphaned


## 📜 License

This project is licensed under the **MIT License**, allowing free use, modification, and distribution.

---

## 🤝 Contributions

This is a personal project, but suggestions and ideas are welcome.  
Feel free to open an issue or submit a pull request.

---

## 🧑‍💻 Author

Built by **John (DarDwizzle)**  
Powered by curiosity, caffeine, and the desire to make Windows behave.

-----------------------------------------------------------------------

## Planned Features (v1.1.0)

### **Verbose Mode (`-Verbose`)**
Provides detailed output for transparency and debugging.

**Verbose output will include:**
- Which orphaned handles were detected  
- Which processes were terminated  
- Which processes were skipped  
- Which processes were protected  
- Any errors or access-denied events  

---

Added Features:

- CSV Export - a CSV files will be copied to your paste button upon running
this allows exporting the full verbose report to a `.csv` file for analysis.

**CSV fields will include:**
- Process name  
- PID  
- Memory used per process in MB
- The amount of CPU used per process in seconds
- Start date and time of process killed
- Path to process and process name (Chrome, Edge, WebView2)  
- Parent PID if it's achild process

---
Potential Future Upgrades

### **Advanced Process Group Selection (Hidden Feature)**
This is an **advanced** and **dangerous** feature intended only for power users.

It will be hidden behind an **“Advanced Options”** toggle with a warning:

> “These options are intended for advanced users.  
> Killing WebView2 processes may cause Chrome or Edge to lose active sessions.”

**Selectable process groups:**
- Chrome  
- Edge  
- WebView2  

**Example use case:**
- System is sluggish  
- Chrome has sleeping tabs the user wants to keep  
- User wants to kill only Edge + WebView2 orphaned processes  

**Example CLI:**
```KillOrphaned.exe -Advanced -Kill Edge,WebView2```

**Example GUI behavior:**
[ ] Chrome
[x] Edge
[x] WebView2

Default behavior remains unchanged unless Advanced Options is explicitly enabled.

---------------------------------------------------------------------------
For long‑term plans and upcoming utilities, see the full [NullByte Toolbox Roadmap](ROADMAP.md).

