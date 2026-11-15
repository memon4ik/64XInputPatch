#include <xtl.h>

typedef struct _XBOX_KRNL_VERSION {
    WORD Major, Minor, Build, Qfe;
} XBOX_KRNL_VERSION, *PXBOX_KRNL_VERSION;

extern "C" {
    DWORD XexGetModuleHandle(PCSTR moduleName, PHANDLE hand);
    DWORD XexGetProcedureAddress(HANDLE hand, DWORD dwOrdinal, PVOID Address);
    BOOLEAN MmIsAddressValid(PVOID VirtualAddress);
    extern PXBOX_KRNL_VERSION XboxKrnlVersion;
}

// Запись 32-битной инструкции в память ядра со сбросом кэша CPU PowerPC
void PatchInstruction(DWORD addr, DWORD inst) {
    *(DWORD*)addr = inst;
    __dcbst(0, (PVOID)addr);
    __sync();
    __emit(0x4C00012C); // isync
}

// Поиск последовательности до 3 инструкций PowerPC в заданном диапазоне памяти ядра
DWORD FindPattern3(DWORD start, DWORD end, DWORD w0, DWORD w1, DWORD w2, int count) {
    for (DWORD addr = start; addr <= end - (count * 4); addr += 4) {
        if (!MmIsAddressValid((PVOID)addr)) continue;
        if (*(DWORD*)addr != w0) continue;
        if (count >= 2 && *(DWORD*)(addr + 4) != w1) continue;
        if (count >= 3 && *(DWORD*)(addr + 8) != w2) continue;
        return addr;
    }
    return 0;
}

// Применение патчей безопасности XSM3 и расширения буферов USB (32 -> 64 байта)
void ApplyReleasePatches() {
    if (XboxKrnlVersion == NULL) return;

    // 1. Отключение криптографической проверки XSM3 (UsbdIsDeviceAuthenticated, Ordinal 745 -> return 1)
    HANDLE hKernel = NULL;
    PDWORD pdwUsbdAuth = NULL;
    if (XexGetModuleHandle("xboxkrnl.exe", &hKernel) == 0 && hKernel != NULL) {
        XexGetProcedureAddress(hKernel, 745, &pdwUsbdAuth);
    }
    if (pdwUsbdAuth != NULL && MmIsAddressValid(pdwUsbdAuth)) {
        PatchInstruction((DWORD)pdwUsbdAuth, 0x38600001);       // li r3, 1
        PatchInstruction((DWORD)(pdwUsbdAuth + 1), 0x4E800020); // blr
    }

    // 2. Расширение лимита wMaxPacketSize в контроллере OHCI с 32 (0x20) до 64 (0x40) байт
    DWORD addrOhci = FindPattern3(0x800D8000, 0x800E5000, 0x2B1A0020, 0, 0, 1);
    if (addrOhci != 0) {
        PatchInstruction(addrOhci, 0x2B1A0040); // cmplwi r26, 0x40
    }

    // 3. Обход отбраковки нестандартных дескрипторов и длинных пакетов в Wgc
    if (XboxKrnlVersion->Build == 16537) {
        if (*(DWORD*)0x800F87C4 == 0x4182006C) PatchInstruction(0x800F87C4, 0x60000000);
        if (*(DWORD*)0x800F87E0 == 0x41990050) PatchInstruction(0x800F87E0, 0x60000000);
        if (*(DWORD*)0x800F9040 == 0x39000020) PatchInstruction(0x800F9040, 0x39000040);
        if (*(DWORD*)0x800F94C0 == 0x38A00020) PatchInstruction(0x800F94C0, 0x38A00040);
        if (*(DWORD*)0x800F95E0 == 0x39600020) PatchInstruction(0x800F95E0, 0x39600040);
        if (*(DWORD*)0x800F3548 == 0x38A00020) PatchInstruction(0x800F3548, 0x38A00040);
        if (*(DWORD*)0x800F70D4 == 0x409A0018) {
            PatchInstruction(0x800F70D4, 0x60000000);
            PatchInstruction(0x800F70F8, 0x60000000);
        }
        if (*(DWORD*)0x800F6154 == 0x409A004C) PatchInstruction(0x800F6154, 0x4198004C);
    } else {
        // Универсальный поиск по сигнатурам для ядра 17559 и других версий в секции Wgc
        DWORD addrParse = FindPattern3(0x800F0000, 0x80105000, 0x80810050, 0x2B040014, 0x409A004C, 3);
        if (addrParse != 0) {
            PatchInstruction(addrParse + 8, 0x4198004C); // bne +0x4C -> blt +0x4C
        }
    }
}

BOOL APIENTRY DllMain(HANDLE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    if (ul_reason_for_call == DLL_PROCESS_ATTACH) {
        ApplyReleasePatches();
    }
    return TRUE;
}
