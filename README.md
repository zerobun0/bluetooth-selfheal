# bluetooth-selfheal

Fixes a Windows 11 bug where an Intel wireless Bluetooth radio randomly drops into a Code 10 error ("This device cannot start"), which kills the Bluetooth toggle in Action Center until you manually disable and re-enable the device in Device Manager.

## What it does

`install.ps1` (run as Administrator, once):

- Disables Fast Startup, a common trigger for Bluetooth radios losing their USB enumeration after sleep or shutdown on Intel AX210 / AX211 combo cards.
- Disables USB selective suspend on the active power plan.
- Installs `selfheal.ps1` to `C:\ProgramData\BluetoothSelfHeal`.
- Registers a scheduled task that runs with the highest available privileges under your account and checks the radio at logon, at startup, and right after resuming from sleep. If it is stuck in an error state, it removes and rescans the device automatically. No more clicking through Device Manager. (It does not run as SYSTEM, some antivirus/EDR software blocks scheduled tasks created with a SYSTEM principal as a precaution against persistence malware, so this uses your own account with highest privileges instead, which Task Scheduler still runs without a UAC prompt.)

## Usage

1. Find your Bluetooth radio's device instance path: Device Manager, Bluetooth category, right click your adapter, Properties, Details tab, Device instance path.
2. Open `selfheal.ps1` and `install.ps1`, set `$DeviceInstanceId` to that value if it is not an Intel AX210/AX211 (the default already matches that card).
3. Run `install.ps1`. It asks for admin rights itself with a normal UAC prompt, you do not need to open an elevated terminal by hand.
4. Done. It runs itself from then on, no further action needed.

Run `uninstall.ps1` as Administrator to remove the scheduled task and the installed files. It does not revert the Fast Startup or USB selective suspend settings, those are safe to leave on.

## Why this happens

Windows keeps retrying a failed Bluetooth radio driver instead of resetting it cleanly after the USB re-enumeration gets corrupted on sleep, resume, or shutdown. Disabling Fast Startup and USB selective suspend removes the two most common triggers on Intel combo cards, and the scheduled task is a safety net for when it happens anyway.

## Requirements

Windows 11 (should also work on Windows 10 1809+). Administrator rights for the one time setup only.
