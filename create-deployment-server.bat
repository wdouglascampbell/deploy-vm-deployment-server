::::::::::::::::::::::::::::::::::::::::::::
:: Elevate.cmd - Version 4
:: Automatically check & get admin rights
:: see "https://stackoverflow.com/a/12264592/1016343" for description
::::::::::::::::::::::::::::::::::::::::::::
 @echo off
 CLS
 ECHO.
 ECHO =============================
 ECHO Running Admin shell
 ECHO =============================

:init
 setlocal DisableDelayedExpansion
 set cmdInvoke=1
 set winSysFolder=System32
 set "batchPath=%~0"
 for %%k in (%0) do set batchName=%%~nk
 set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
 setlocal EnableDelayedExpansion

:checkPrivileges
  NET FILE 1>NUL 2>NUL
  if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
  if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
  ECHO.
  ECHO **************************************
  ECHO Invoking UAC for Privilege Escalation
  ECHO **************************************

  ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
  ECHO args = "ELEV " >> "%vbsGetPrivileges%"
  ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
  ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
  ECHO Next >> "%vbsGetPrivileges%"

  if '%cmdInvoke%'=='1' goto InvokeCmd 

  ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
  goto ExecElevation

:InvokeCmd
  ECHO args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
  ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
 "%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
 exit /B

:gotPrivileges
 setlocal & cd /d %~dp0
 if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

 ::::::::::::::::::::::::::::
 ::START
 ::::::::::::::::::::::::::::

REM --- Configuration ---
set "VM_NAME=Deployment Server"
set "ISO_PATH=%USERPROFILE%\Downloads\ISO Images\ISO-Fedora\Fedora-Server-netinst-x86_64-41-1.4.iso" 
set "SSH_PORT=22"
set "BASE_FOLDER=%USERPROFILE%\VirtualBox VMs"
set "WORKING_DIR=%~dp0"
set "VDI_FILENAME=%BASE_FOLDER%\%VM_NAME%\%VM_NAME%.vdi" 
set "VDI_SIZE_MB=20480"
set "VBOX_INSTALL_DIR=%ProgramFiles%\Oracle\VirtualBox"
set "VBOX_MANAGE_EXE=%VBOX_INSTALL_DIR%\VBoxManage.exe"
set "KS_CFG=%WORKING_DIR%ks.cfg"
set "KS_VHD=%WORKING_DIR%ks.vhd"
set "KS_VDI=%WORKING_DIR%ks.vdi"
set "DISKPART_SCRIPT=%WORKING_DIR%script.txt"

REM --- Add VirtualBox to PATH (Temporarily) ---
set PATH=%VBOX_INSTALL_DIR%;%PATH%

REM --- Create the Virtual Machine ---
echo Creating Virtual Machine...
"%VBOX_MANAGE_EXE%" createvm --name "%VM_NAME%" --ostype "RedHat_64" --register --basefolder "%BASE_FOLDER%"

REM --- Configure Virtual Machine Settings ---
echo Configuring VM settings...
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --memory 4096 --vram 16
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --rtcuseutc on
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --graphicscontroller vmsvga
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --audioout on
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --nic1 nat --natpf1 "SSH",tcp,127.0.0.1,%SSH_PORT%,,%SSH_PORT%
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --usb on --usbehci on

REM --- Create a Virtual Hard Disk ---
echo Creating Virtual Hard Disk...
"%VBOX_MANAGE_EXE%" createhd --filename "%VDI_FILENAME%" --size %VDI_SIZE_MB% --format VDI

REM --- Attach Fedora Server NetInstall ISO ---
echo Attaching ISO...
"%VBOX_MANAGE_EXE%" storagectl "%VM_NAME%" --name "IDE" --add ide --controller PIIX4
"%VBOX_MANAGE_EXE%" storageattach "%VM_NAME%" --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium "%ISO_PATH%"

REM --- Attach the Hard Disk to the VM ---
echo Attaching Hard Disk...
"%VBOX_MANAGE_EXE%" storagectl "%VM_NAME%" --name "SATA" --add sata --controller IntelAHCI
"%VBOX_MANAGE_EXE%" storageattach "%VM_NAME%" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "%VDI_FILENAME%"

REM --- Create Kickstart Image and Mount to Drive Letter X ---
echo Creating Kickstart Image...
echo create vdisk file="%KS_VHD%" maximum=3 type=fixed > "%DISKPART_SCRIPT%"
echo select vdisk file="%KS_VHD%" >> "%DISKPART_SCRIPT%"
echo attach vdisk >> "%DISKPART_SCRIPT%"
echo create partition primary >> "%DISKPART_SCRIPT%"
echo format fs=fat quick >> "%DISKPART_SCRIPT%"
echo assign letter=X >> "%DISKPART_SCRIPT%"
echo exit >> "%DISKPART_SCRIPT%"

diskpart /s "%DISKPART_SCRIPT%"

REM --- Copy Kickstart File to Kickstart Image ---
copy "%KS_CFG%" x:\

REM -- Unmount Kickstart Image from Drive Letter X ---
echo select vdisk file="%KS_VHD%" > "%DISKPART_SCRIPT%"
echo select part 1 >> "%DISKPART_SCRIPT%"
echo remove letter=X >> "%DISKPART_SCRIPT%"
echo detach vdisk >> "%DISKPART_SCRIPT%"
echo exit >> "%DISKPART_SCRIPT%"

diskpart /s "%DISKPART_SCRIPT%"

REM --- Convert Kickstart Image to VDI Format ---
echo Converting Kickstart Image to VDI Format...
"%VBOX_MANAGE_EXE%" clonehd "%KS_VHD%" "%KS_VDI%" --format VDI

REM -- Clean Up Files ---
echo Cleaning up Kickstart Image Intermediary Files...
"%VBOX_MANAGE_EXE%" closemedium disk "%KS_VHD%" --delete
del "%DISKPART_SCRIPT%"

REM --- Attach Kickstart Image ---
echo Attaching Kickstart Image...
"%VBOX_MANAGE_EXE%" storageattach "%VM_NAME%" --storagectl "SATA" --port 1 --device 0 --type hdd --medium "%KS_VDI%"

REM --- Configure Boot Order ---
echo Configuring boot order...
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --boot1 floppy --boot2 dvd --boot3 disk --boot4 disk

REM --- Start VM ---
echo Starting Virtual Machine...
"%VBOX_MANAGE_EXE%" startvm "%VM_NAME%"

echo.
echo Switch to Virtual Machine window and move cursor to "Install Fedora" option
echo You will need to edit the boot parameters.
echo 1. Press 'e' to enter edit mode.
echo 2. Locate line with inst.status.
echo 3. Enter the text inside the quotes before inst.stage2: "text inst.ks=hd:/dev/sdb1:/ks.cfg "
echo 4. Hold CTRL key and press 'x' to continue booting.
pause
echo.
echo The installation may take a while but you can watch its progress. The VM will shutdown once
echo the initial installation is complete.
echo.

REM Loop until the VM is not running
:WAIT_LOOP
"%VBOX_MANAGE_EXE%" list runningvms | findstr "%VM_NAME%" >nul
if %ERRORLEVEL% equ 0 (
    REM VM is still running, so wait for 5 seconds and check again
    timeout /t 5 >nul
    goto WAIT_LOOP
) else (
    REM VM is no longer running, exit the loop
    echo VM "%VM_NAME%" has shut down.
)

REM --- Ejecting Installation DVD ---
echo Ejecting installer DVD...
"%VBOX_MANAGE_EXE%" storageattach "%VM_NAME%" --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium emptydrive

REM --- Remove Kickstart Image File ---
echo Removing Kickstart image file...
"%VBOX_MANAGE_EXE%" storageattach "%VM_NAME%" --storagectl "SATA" --port 1 --device 0 --type hdd --medium none
"%VBOX_MANAGE_EXE%" closemedium disk "%KS_VDI%" --delete

REM --- Reconfigure Boot Order ---
echo Reconfiguring boot order...
timeout /t 5 >nul
"%VBOX_MANAGE_EXE%" modifyvm "%VM_NAME%" --boot1 floppy --boot2 dvd --boot3 disk --boot4 none

echo.
echo "Installation is now complete!"
echo.
pause
