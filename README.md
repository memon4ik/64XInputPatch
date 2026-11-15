# XFlydigiPatch *(Soon to be renamed — Universal XInput Patcher)*

**[🇬🇧 English](README.md) | [🇷🇺 Русский](README_RU.md)**

> **⚠️ Experimental / Research Project — Contributions Welcome!**
> This project was originally started for personal use to get a **Flydigi Dune Fox** controller working on an RGH console, which is why it currently carries this name. However, its core patches are universal, and **the repository will soon be renamed** to reflect its broader goal: enabling unsupported third-party USB controllers on Xbox 360.
>
> **Status:** Currently tested on **Kernel 16537** with a Flydigi Dune Fox (which successfully enumerates and holds `Slot 0`, though button inputs remain blocked by Flydigi's proprietary Windows host handshake). **Developers and RGH enthusiasts are encouraged to inspect the code, study the included memory dumps, adapt the patches for other gamepads, and share their improvements via Pull Requests or Issues!**

---

## 🤖 AI-Assisted Development Note
This project was built in collaboration with an **AI assistant**. Because Xbox 360 kernel internals, PowerPC assembly, and undocumented `xboxkrnl.exe` structures have scarce documentation, AI was used to help explain low-level USB/OHCI mechanics, analyze raw memory dumps, locate instruction offsets, and write the C++ kernel patching code. If you are learning Xbox 360 reverse engineering, feel free to use this codebase and the comments inside `main.cpp` as a learning reference!

---

## 🧠 How It Works Under the Hood (Beginner-Friendly Breakdown)

When you plug a modern third-party PC controller into an Xbox 360, the console's kernel blocks it at three different stages. Here is what this plugin actually does in memory to bypass those roadblocks:

1. **Bypassing the XSM3 Security Chip (`UsbdIsDeviceAuthenticated`):**
   Official Xbox 360 controllers contain a proprietary hardware security chip (XSM3). When any USB device connects, the kernel asks the USB driver if the device passed cryptographic authentication. This plugin patches kernel export **Ordinal `745`** so that it immediately returns `1` (`TRUE`), tricking the console into trusting unauthenticated third-party controllers.
2. **Expanding USB Packet Limits from 32 Bytes to 64 Bytes (`0x20` → `0x40`):**
   Back in 2005, standard wired Xbox 360 controllers used **32-byte (`0x20`)** USB interrupt packets. Many modern controllers (like Flydigi, GameSir, etc.) use **64-byte (`0x40`)** endpoints. By default, the Xbox 360 USB host driver (`OHCI`) and gamepad driver (`Wgc`) reject any endpoint larger than `0x20` bytes. This plugin patches the size checks and internal `URB` (USB Request Block) read buffers to accept `0x40` bytes.
3. **Unlocking Input Polling & Report Parsing:**
   Even after a controller is accepted, the `Wgc` (`Wired Game Controller`) driver waits for a security handshake reply before it starts polling buttons, and strictly checks that incoming data packets match legacy lengths. We patch those conditional branches (`nop` / `blt`) so the driver immediately polls the controller and accepts standard input reports (`>= 20` bytes / `0x14`).
4. **Live PowerPC Cache Flushing:**
   Because the Xbox 360 runs on a **PowerPC** CPU with separate instruction and data caches, simply overwriting bytes in RAM isn't enough—the CPU would keep executing old cached code. Every patch uses `dcbst`, `sync`, and `isync` instructions to force the processor to load our modified code immediately.

---

## 📂 Repository Structure
- `main.cpp` — Clean release source code with hardcoded offsets for **Kernel 16537** and PowerPC pattern scanning for **Kernel 17559**.
- `build.bat` & `xex.xml` — Standalone command-line auto-builder and `imagexex` packaging config (no Visual Studio GUI required).
- `*.sln` / `*.vcxproj` — Visual Studio project files for editing and debugging with the Xbox 360 SDK (XEDK).
- `dumps/` — Raw kernel heap dumps, OHCI endpoint descriptors, and PowerPC disassembly logs captured from **Kernel 16537** during testing.

---

## 🔍 Technical Findings: Flydigi Dune Fox
During reverse engineering on an **Xbox 360 Slim (Kernel 16537)**, the **Flydigi Dune Fox** (tested via both its 2.4G wireless dongle and wired USB-C) revealed the following behavior:
- **USB Descriptors:** Enumerates as `VID_045E&PID_028E` with 8 composite interfaces and 64-byte endpoints (`EP 0x81` IN / `EP 0x02` OUT).
- **What Works:** With this plugin active, the console accepts the adapter, bypasses XSM3 rejection, and keeps `Slot 0` registered (`ERROR_SUCCESS` / `0x00000000`) without disconnecting.
- **Why Buttons Don't Register Yet:** The Flydigi firmware stays in an idle state until it receives a proprietary initialization packet from the Windows PC driver (`xusb22.sys` / Flydigi Space Station). Standard third-party 64-byte XInput controllers that do not require proprietary Windows driver initialization should work out of the box, whereas Flydigi devices need that startup handshake replicated (or an external USB adapter like *Brook Wingman XB 2* or *Mayflash Magic-X*).

---

## 🛠️ Kernel 16537 Patch Map

| Target Function / Module | Address | Patch | Purpose |
| :--- | :--- | :--- | :--- |
| `UsbdIsDeviceAuthenticated` | Ordinal `745` | `li r3, 1` / `blr` | Bypass XSM3 hardware security check |
| `OHCI_OpenEndpoint` | `0x800DD300` | `cmplwi r26, 0x40` | Raise max USB packet size limit from 32B to 64B |
| `WgcAddDevice` | `0x800F87C4`, `0x800F87E0` | `nop` | Allow non-standard endpoint descriptors |
| `Wgc` URB Buffers | `0x800F9040`, `0x800F94C0`, `0x800F95E0` | `li rX, 0x40` | Expand read buffers from 32B to 64B |
| `XUsb` Wireless Buffer | `0x800F3548` | `li r5, 0x40` | Expand wireless read buffer to 64B |
| `Wgc` Input Polling | `0x800F70D4`, `0x800F70F8` | `nop` | Unlock button polling without XSM3 reply |
| `Wgc` Report Parser | `0x800F6154` | `blt +0x4C` | Accept input reports `>= 0x14` (20) bytes |

*(Note: On **Kernel 17559** and other dashboard builds, the plugin automatically falls back to PowerPC instruction pattern scanning to locate and patch key functions safely.)*

---

## 🚀 Building & Installation

### Building from Source
1. Install the **Xbox 360 SDK (XEDK)** and verify that the `XEDK` environment variable is set.
2. Run `build.bat` (or open the `.sln` in Visual Studio) to compile `main.cpp` and pack `XFlydigiPatch.xex`.
3. In `build.bat`, press `A` to rebuild at any time, or `Q` to quit.

### Installing on Xbox 360 (DashLaunch)
1. Copy `XFlydigiPatch.xex` to the root of your internal hard drive (`Hdd1:\`) or USB flash drive (`Usb0:\`).
2. Add it to your `launch.ini`:
   ```ini
   [Plugins]
   plugin1 = Hdd1:\XFlydigiPatch.xex
   ```
3. Reboot your console.

## 🤝 Contributing
Have a different third-party controller, or captured the USB initialization sequence for Flydigi on PC? **Open an Issue or submit a Pull Request**—every bit of research helps keep the Xbox 360 scene alive!
