---
name: Bug Report
about: Report a problem with 64XInputPatch (controller not detected, buttons not working, etc.)
title: '[BUG] '
labels: bug
assignees: ''
---

## 🐛 Bug Description
A clear and concise description of what the problem is.

## 🎮 Controller Information
- **Controller model:** (e.g., Flydigi Dune Fox, GameSir T4, 8BitDo Ultimate, etc.)
- **Connection type:** (USB-C wired / 2.4G dongle / Bluetooth adapter)
- **USB VID/PID:** (if known, e.g., `VID_045E&PID_028E`)

## 🖥️ Console Information
- **Console model:** (e.g., Xbox 360 Slim, Fat, Corona, Trinity, etc.)
- **Kernel version:** (e.g., 16537, 17559, other)
- **Mod type:** (RGH / JTAG / other)
- **DashLaunch version:** (if known)

## 🔧 Plugin Information
- **64XInputPatch version:** (e.g., v0.2.0, v0.3.0, built from source)
- **Installation path:** (e.g., `Hdd1:\64XInputPatch.xex`, `Usb0:\64XInputPatch.xex`)
- **Other plugins in `launch.ini`:** (list them, especially UsbdSecPatch or similar)

## 📋 Steps to Reproduce
1. 
2. 
3. 

## ✅ Expected Behavior
What you expected to happen.

## ❌ Actual Behavior
What actually happened instead.

## 📎 Logs & Dumps
If possible, attach:
- A screenshot of the DashLaunch plugin list or any error message
- A kernel log (if you can capture one)
- A USB traffic dump (Wireshark/USBPcap) if relevant
- Any relevant files from the `dumps/` folder

## 📝 Additional Context
Add any other context about the problem here. For example:
- Does the controller work on a PC with the same cable/dongle?
- Does it work with other plugins disabled?
- Have you tried a different USB port on the console?

---

**⚠️ Note:** This is an experimental research project. Not all controllers are supported yet. Please check the README and existing Issues before submitting a new report.
