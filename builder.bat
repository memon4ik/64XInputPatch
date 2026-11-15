@echo off
cd /d "%~dp0"
if exist "XFlydigiPatch\main.cpp" cd /d "XFlydigiPatch"
setlocal enabledelayedexpansion

title XFlydigiPatch Builder (Kernel 16537)
color 0B

set "OUTNAME=XFlydigiPatch"
set "SOURCEFILE=main"
set "BUILD_DIR=build"
set "INCLUDE=%XEDK%\include\xbox"
set "LIB=%XEDK%\lib\xbox"
set "BINARYPATH=%XEDK%\bin\win32"

:BUILD_LOOP
cls
color 0B
echo XFlydigiPatch Builder ^| Xbox 360 Kernel 16537
echo Source: %SOURCEFILE%.cpp -^> Output: %OUTNAME%.xex
echo ------------------------------------------------------------

if not exist "%BINARYPATH%\cl.exe" (
    color 0C
    echo [ERROR] XEDK not found at: %BINARYPATH%
    goto :PROMPT_RETRY
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if exist "%BUILD_DIR%\%SOURCEFILE%.obj" del /F /Q "%BUILD_DIR%\%SOURCEFILE%.obj"
if exist "%BUILD_DIR%\%OUTNAME%.exe" del /F /Q "%BUILD_DIR%\%OUTNAME%.exe"
if exist "%OUTNAME%.xex" del /F /Q "%OUTNAME%.xex"

echo [1/4] Compiling %SOURCEFILE%.cpp...
"%BINARYPATH%\cl.exe" /c /Zi /nologo /W3 /WX- /Ox /Os /D NDEBUG /D _XBOX /GF /Gm- /MT /GS- /Gy /fp:fast /fp:except- /Zc:wchar_t /Zc:forScope /GR- /openmp- /Fo"%BUILD_DIR%/" /Fd"%BUILD_DIR%/" /FI"%XEDK%/include/xbox/xbox_intellisense_platform.h" /TP %SOURCEFILE%.cpp
if errorlevel 1 (
    color 0C
    echo [FAIL] Compilation failed.
    goto :PROMPT_RETRY
)

echo [2/4] Linking %OUTNAME%.exe...
"%BINARYPATH%\link.exe" /ERRORREPORT:PROMPT /OUT:"%BUILD_DIR%/%OUTNAME%.exe" /INCREMENTAL:NO /NOLOGO xapilib.lib xboxkrnl.lib /MANIFESTUAC:"level='asInvoker' uiAccess='false'" /DEBUG /PDB:"%BUILD_DIR%/%OUTNAME%.pdb" /STACK:"262144","262144" /OPT:REF /OPT:ICF /TLBID:1 /RELEASE /IMPLIB:"%BUILD_DIR%/%OUTNAME%.lib" %BUILD_DIR%/%SOURCEFILE%.obj /ignore:4089 /dll /entry:"_DllMainCRTStartup" /ALIGN:128,4096 /XEX:NO
if errorlevel 1 (
    color 0C
    echo [FAIL] Linking failed.
    goto :PROMPT_RETRY
)

echo [3/4] Packing %OUTNAME%.xex...
"%BINARYPATH%\imagexex.exe" /nologo /config:"xex.xml" /out:"%OUTNAME%.xex" "%BUILD_DIR%/%OUTNAME%.exe"
if errorlevel 1 (
    color 0C
    echo [FAIL] ImageXex failed.
    goto :PROMPT_RETRY
)

if not exist "%OUTNAME%.xex" (
    color 0C
    echo [FAIL] %OUTNAME%.xex was not created.
    goto :PROMPT_RETRY
)

for %%F in ("%OUTNAME%.xex") do set "XEX_SIZE=%%~zF"
set /a "XEX_KB=!XEX_SIZE! / 1024"
echo       Packed: !XEX_SIZE! bytes ^(~!XEX_KB! KB^)

echo [4/4] Deploying to USB ^(F: / E:^)...
set "TARGET_DRIVE="
for %%D in (F E) do (
    if exist "%%D:\launch.ini" (
        set "TARGET_DRIVE=%%D:"
        goto :DEPLOY
    )
)
for %%D in (F E) do (
    if exist "%%D:\" (
        set "TARGET_DRIVE=%%D:"
        goto :DEPLOY
    )
)

:DEPLOY
if defined TARGET_DRIVE (
    copy /Y "%OUTNAME%.xex" "%TARGET_DRIVE%\%OUTNAME%.xex" >nul
    if errorlevel 1 (
        color 0E
        echo [WARN] Copy failed to %TARGET_DRIVE%\
    ) else (
        color 0A
        echo [DONE] Deployed to %TARGET_DRIVE%\%OUTNAME%.xex ^(%TIME:~0,8%^)
    )
) else (
    color 0E
    echo [WARN] USB drive ^(F: or E:^) not found. Saved locally.
)

:PROMPT_RETRY
echo ------------------------------------------------------------
choice /C AQ /N /M "Press [A] to rebuild again, or [Q] to quit: "
if errorlevel 2 exit /b 0
if errorlevel 1 goto :BUILD_LOOP
