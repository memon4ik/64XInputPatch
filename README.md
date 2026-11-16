# 64XInputPatch

**[🇬🇧 English](README.md) | [🇷🇺 Русский](README_RU.md)**

> **⚠️ Experimental / Research Project — Contributions Welcome!**
> **64XInputPatch** *(formerly XFlydigiPatch)* is an open-source DashLaunch kernel plugin for **Xbox 360 (RGH/JTAG)** designed to bypass XSM3 hardware security checks and expand USB `OHCI` / `Wgc` (`Wired Game Controller`) packet buffer limits from **32 bytes (`0x20`)** to **64 bytes (`0x40`)** to support non-standard third-party XInput controllers.
>
> **Status:** Tested on **Kernel 16537** with the Flydigi Dune Fox, which enumerates and holds `Slot 0`. Detailed technical findings, memory offsets, and build instructions can be found in the repository documentation.

---

## 🤖 AI-Assisted Development Note
This project was built in collaboration with an **AI assistant** to analyze low-level USB/OHCI mechanics, inspect memory dumps, locate instruction offsets, and write C++ kernel patching code for the Xbox 360 PowerPC architecture.

---

## 🧠 How It Works Under the Hood
1. **Bypassing XSM3 Security (`UsbdIsDeviceAuthenticated`):** Patches kernel export **Ordinal `745`** to return `1` (`TRUE`), bypassing hardware authentication.
2. **Expanding USB Limits (`0x20` → `0x40`):** Modifies `OHCI` and `Wgc` driver size checks and `URB` read buffers to support 64-byte interrupt packets.
3. **Unlocking Input Polling:** Patches conditional checks in `Wgc` to immediately poll controllers and parse input reports ($\ge 20$ bytes / `0x14`).
4. **Live PowerPC Cache Flushing:** Uses `dcbst`, `sync`, and `isync` instructions to force the CPU to load modified code.

---

## 📂 Repository Structure & Technical Findings
* **Source & Build Files:** Includes `main.cpp` (with Kernel 16537 hardcoded offsets and Kernel 17559 pattern scanning), standalone batch/XML build scripts, Visual Studio project files, and raw kernel heap/disassembly dumps.
* **Flydigi Dune Fox Analysis:** Wireshark/USBPcap captures revealed that while the plugin bypasses XSM3 and passes rumble commands, Flydigi controllers require a specific 3-step host initialization handshake (`bRequest = 0x01` control transfers and an interrupt wakeup command) before sending button reports. Full packet details and patch maps for `UsbdIsDeviceAuthenticated`, `OHCI_OpenEndpoint`, and `Wgc` functions are documented in the main repository files.

---

## 🚀 Building & Installation
1. **Build:** Set up the **Xbox 360 SDK (XEDK)** and run `builder.bat` or compile via Visual Studio to generate `64XInputPatch.xex`.
2. **Install:** Copy `64XInputPatch.xex` to `Hdd1:\` or `Usb0:\` and load it via DashLaunch in `launch.ini`:
   ```ini
   [Plugins]
   plugin1 = Hdd1:\64XInputPatch.xex
   ```
3. Reboot your console.

## 🤝 Contributing & Credits
Contributions, pull requests, and research on alternative third-party controllers are welcome. Special thanks to the open-source **UsbdSecPatch** project by InvoxiPlayGames, which inspired the `UsbdIsDeviceAuthenticated` (Ordinal `745`) kernel patching approach.
