# XFlydigiPatch
Xbox 360 RGH/JTAG DashLaunch kernel plugin to bypass XSM3 authentication and expand USB OHCI/Wgc packet limits from 32 to 64 bytes (Kernel 16537 &amp; 17559).

# XFlydigiPatch

A lightweight **Xbox 360 (RGH/JTAG)** DashLaunch kernel plugin that disables XSM3 hardware security checks and expands USB `OHCI` / `Wgc` (`Wired Game Controller`) packet buffer limits from **32 bytes (`0x20`)** to **64 bytes (`0x40`)** to support third-party XInput peripherals.

## Key Features
- **XSM3 Authentication Bypass:** Patches `UsbdIsDeviceAuthenticated` (Ordinal `745`) in `xboxkrnl.exe` to return `TRUE`, allowing unlicensed third-party XInput devices without a hardware security chip.
- **64-Byte USB Endpoint & Buffer Support:** Expands `wMaxPacketSize` validation in `OHCI_OpenEndpoint` and internal `URB` transfer buffers in `Wgc` from `0x20` to `0x40` bytes.
- **Report Parser & Polling Unlock:** Removes security handshake stalls and permits input reports `>= 20` bytes (`0x14`).
- **Multi-Kernel Support:** Includes exact hardcoded offsets for **Kernel 16537** and automatic PowerPC instruction pattern scanning for **Kernel 17559** and other builds.

## Technical Findings: Flydigi Dune Fox
During reverse engineering on an **Xbox 360 Slim (Kernel 16537)**, the **Flydigi Dune Fox** (both via 2.4G wireless dongle and wired USB-C) was analyzed at the kernel heap and OHCI descriptor levels:
- **USB Enumeration:** Reports `VID_045E&PID_028E` with 8 composite interfaces and 64-byte interrupt endpoints (`EP 0x81` IN / `EP 0x02` OUT).
- **Result with Plugin:** The console successfully enumerates the device, bypasses XSM3 rejection, and keeps `Slot 0` active (`ERROR_SUCCESS` / `0x00000000`).
- **Firmware Limitation:** The Flydigi controller/dongle firmware requires a proprietary Windows host initialization sequence before transmitting XInput state reports over `EP 0x81`. Because of this hardware-level handshake requirement, standard third-party 64-byte XInput controllers that do not rely on proprietary Windows driver init work out of the box, while Flydigi controllers require an active hardware translator (e.g., *Brook Wingman XB 2* or *Mayflash Magic-X*).

## Kernel 16537 Patch Map

| Target | Address | Patch | Purpose |
| :--- | :--- | :--- | :--- |
| `UsbdIsDeviceAuthenticated` | Ordinal `745` | `li r3, 1` / `blr` | Bypass XSM3 security check |
| `OHCI_OpenEndpoint` | `0x800DD300` | `cmplwi r26, 0x40` | Raise max packet size limit to 64B |
| `WgcAddDevice` | `0x800F87C4`, `0x800F87E0` | `nop` | Allow non-standard endpoint descriptors |
| `Wgc` URB Buffers | `0x800F9040`, `0x800F94C0`, `0x800F95E0` | `li rX, 0x40` | Expand read buffers from 32B to 64B |
| `XUsb` Wireless Buffer | `0x800F3548` | `li r5, 0x40` | Expand wireless read buffer to 64B |
| `Wgc` Input Polling | `0x800F70D4`, `0x800F70F8` | `nop` | Unlock polling without XSM3 reply |
| `Wgc` Report Parser | `0x800F6154` | `blt +0x4C` | Accept input packets `>= 0x14` bytes |

## Building from Source
1. Install the **Xbox 360 SDK (XEDK)** and ensure the `XEDK` environment variable is configured.
2. Run `build.bat` to compile `main.cpp`, link the DLL, and pack `XFlydigiPatch.xex` using `imagexex`.
3. Press `A` in the builder console to rebuild at any time, or `Q` to exit.

## Installation
1. Download `XFlydigiPatch.xex` from the [Releases](../../releases) page (or build it from source).
2. Copy `XFlydigiPatch.xex` to the root of your internal HDD (`Hdd1:\`) or USB drive (`Usb0:\`).
3. Register the plugin in your DashLaunch `launch.ini`:
   ```ini
   [Plugins]
   plugin1 = Hdd1:\XFlydigiPatch.xex
   ```
4. Reboot your console.
