# 64XInputPatch

**[🇬🇧 English](README.md) | [🇷🇺 Русский](README_RU.md)**

> **⚠️ Experimental / Research Project — Contributions Welcome!**
> **64XInputPatch** *(formerly XFlydigiPatch)* is an open-source DashLaunch kernel plugin for **Xbox 360 (RGH/JTAG)** designed to bypass XSM3 cryptographic security checks and expand USB packet buffer limits in `OHCI` / `Wgc` (`Wired Game Controller`) from **32 bytes (`0x20`)** to **64 bytes (`0x40`)** to support non-standard third-party XInput controllers.
>
> **Current Status:** The plugin has been tested on **Kernel 16537** with the Flydigi Dune Fox controller (the console successfully detects the adapter, bypasses XSM3, and holds `Slot 0`, but button reports are not yet received because the controller waits for a closed initialization command that the Windows driver sends). **RGH developers and enthusiasts: study the source code and kernel memory dumps, adapt the patches for your controllers, and be sure to share your findings here via Pull Requests or Issues!**

---

## 🤖 AI-Assisted Development Note
This project was built in close collaboration with an **AI assistant**. Because documentation on the Xbox 360 kernel internals, PowerPC architecture, and undocumented `xboxkrnl.exe` functions is extremely scarce, the AI helped analyze PowerPC machine code, inspect raw memory dumps, explain OHCI bus controller behavior, and write the C++ patcher code. If you are just starting to learn Xbox 360 reverse engineering, feel free to use this code and the detailed comments in `main.cpp` as a learning guide!

---

## 🧠 How It Works Under the Hood (in Plain Terms)

When you connect a modern third-party PC gamepad to an Xbox 360, the console blocks it at several levels. Here is exactly what this plugin does in memory to remove those restrictions:

1. **Bypassing XSM3 Cryptographic Security (`UsbdIsDeviceAuthenticated`):**
   Original Xbox 360 controllers contain a dedicated XSM3 security chip. When any USB device is connected, the kernel verifies whether it has passed cryptographic authentication. The plugin patches kernel function **Ordinal `745`** to always return `1` (`TRUE`), so the console trusts a third-party device without the chip.
2. **Expanding USB Packet Limit from 32 to 64 Bytes (`0x20` → `0x40`):**
   In 2005, standard wired Xbox 360 controllers transmitted data in **32-byte (`0x20`)** packets. Modern gamepads (Flydigi, GameSir, etc.) use **64-byte (`0x40`)** endpoints. The stock USB host controller driver (`OHCI`) and the gamepad driver (`Wgc`) reject any endpoint longer than `0x20` bytes. The plugin fixes these checks and increases the internal `URB` read buffers to `0x40` bytes.
3. **Unlocking Input Polling and Report Parsing:**
   Even after the device is detected, the `Wgc` (`Wired Game Controller`) driver waits for a response from the security chip before polling buttons, and strictly validates incoming packet length. We remove these conditional branches (`nop` / `blt`) so the driver starts polling immediately and accepts packets of at least 20 bytes (`>= 0x14`).
4. **PowerPC Instruction Cache Flushing:**
   The Xbox 360 uses a **PowerPC** CPU with separate data and instruction caches. Simply overwriting bytes in RAM is not enough — the CPU will continue executing the old code from cache. Therefore, after each patch, the `dcbst`, `sync`, and `isync` instructions are invoked to force the CPU pipeline to reload the modified code.

---

## 📂 Repository Structure
- `main.cpp` — clean release source code with exact offsets for **Kernel 16537** and automatic signature scanning for **Kernel 17559**.
- `builder.bat` and `xex.xml` — standalone console auto-builder and `.xex` build config via `imagexex` (no need to launch Visual Studio).
- `*.sln` / `*.vcxproj` — Visual Studio project files for convenient editing and debugging with the Xbox 360 SDK (XEDK).
- `dumps/` — raw kernel heap dumps, OHCI descriptors, and disassembled PowerPC code sections captured from **Kernel 16537** during research.

---

## 🔍 Research Findings: Flydigi Dune Fox and Wireshark Traffic Analysis
During reverse engineering on an **Xbox 360 Slim (Kernel 16537)** and USB traffic capture on a PC via **Wireshark / USBPcap**, the **Flydigi Dune Fox** controller (both via 2.4G dongle and wired USB-C) showed the following:
- **USB Descriptors:** Enumerates as `VID_045E&PID_028E` with 8 composite interfaces and 64-byte endpoints (`EP 0x81` IN / `EP 0x02` OUT).
- **What Already Works:** With the **64XInputPatch** plugin active, the console successfully accepts the adapter, bypasses the XSM3 rejection, keeps `Slot 0` in an active state (`ERROR_SUCCESS` / `0x00000000`), and even forwards rumble commands to the gamepad.
- **Captured Initialization Handshake (Wireshark):** Windows traffic analysis revealed that before the controller starts sending button presses on `EP 0x81`, it waits for a 3-step initialization sequence from the host:
  1. `EP 0x00` Control IN (`Setup: C1 01 00 01 00 00 14 00`) — vendor request `bRequest = 0x01`, `wValue = 0x0100` (20 bytes).
  2. `EP 0x00` Control IN (`Setup: C1 01 00 00 00 00 08 00`) — vendor request `bRequest = 0x01`, `wValue = 0x0000` (8 bytes).
  3. `EP 0x02` Interrupt OUT (`Data: 02 08 03`) — radio module wake-up command.
- **Conclusion:** Ordinary third-party 64-byte XInput gamepads that do not require proprietary vendor requests `bRequest = 0x01` from the Windows driver should work immediately. Flydigi controllers require a separate driver that sends these control requests (or a hardware translator such as the *Brook Wingman XB 2* or *Mayflash Magic-X*).

---

## 🛠️ Patch Map for Kernel 16537

| Module / Function | Address | Instruction | Purpose |
| :--- | :--- | :--- | :--- |
| `UsbdIsDeviceAuthenticated` | Ordinal `745` | `li r3, 1` / `blr` | Disables XSM3 security chip verification |
| `OHCI_OpenEndpoint` | `0x800DD300` | `cmplwi r26, 0x40` | Expands USB packet limit from 32 to 64 bytes |
| `WgcAddDevice` | `0x800F87C4`, `0x800F87E0` | `nop` | Allows non-standard endpoint descriptors |
| URB buffers in `Wgc` | `0x800F9040`, `0x800F94C0`, `0x800F95E0` | `li rX, 0x40` | Increases read buffers from 32 to 64 bytes |
| Wireless `XUsb` buffer | `0x800F3548` | `li r5, 0x40` | Increases read buffer to 64 bytes |
| Button polling in `Wgc` | `0x800F70D4`, `0x800F70F8` | `nop` | Starts button polling without XSM3 response |
| Report parser `Wgc` | `0x800F6154` | `blt +0x4C` | Accepts data packets of at least `0x14` (20) bytes |

*(Note: on **Kernel 17559** and other dashboard versions, the plugin automatically switches to PowerPC instruction signature scanning.)*

---

## 🚀 Building & Installation

### Building from Source
1. Install the **Xbox 360 SDK (XEDK)** and make sure the `XEDK` environment variable is set in your system.
2. Run `builder.bat` (or open the `.sln` in Visual Studio) to compile `main.cpp` and package `64XInputPatch.xex`.
3. In the `builder.bat` window, press **`A`** to rebuild instantly or **`Q`** to quit.

### Installing on Xbox 360 (DashLaunch)
1. Copy `64XInputPatch.xex` to the root of the internal hard drive (`Hdd1:\`) or a USB flash drive (`Usb0:\`).
2. Add the plugin to your `launch.ini` file:
   ```ini
   [Plugins]
   plugin1 = Hdd1:\64XInputPatch.xex
3. Reboot your console

## 🤝 Contributing
If you have another third-party gamepad or want to add vendor `Control IN` request sending to the driver — **create an Issue or submit a Pull Request**! Any contribution will help make the plugin truly universal for the entire Xbox 360 community.

## 🙏 Credits & Acknowledgments
- **UsbdSecPatch:** The initial concept of patching `UsbdIsDeviceAuthenticated` (Ordinal `745`) in `xboxkrnl.exe` and the DashLaunch XEX plugin structure are based on the open-source [UsbdSecPatch](https://github.com/InvoxiPlayGames/UsbdSecPatch) project. This repository builds upon that foundation by adding **Kernel 16537** support and expanding the `OHCI` / `Wgc` USB buffer limits to **64 bytes (`0x40`)**.
