# Run this once, then forget about it. It asks for admin rights itself (a UAC prompt pops up),
# you do not need to open an elevated terminal by hand.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$DeviceInstanceId = "USB\VID_8087&PID_0032\8&F2CB6FA&0&13"
$installDir = "C:\ProgramData\BluetoothSelfHeal"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Output "Disabling Fast Startup..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0

Write-Output "Disabling USB selective suspend on the active power plan..."
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setactive SCHEME_CURRENT

Write-Output "Installing selfheal.ps1 to $installDir..."
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Copy-Item (Join-Path $scriptRoot "selfheal.ps1") -Destination (Join-Path $installDir "selfheal.ps1") -Force

Write-Output "Clearing any current Code 10 state on the target device..."
pnputil /remove-device $DeviceInstanceId 2>$null | Out-Null
Start-Sleep -Seconds 2
pnputil /scan-devices | Out-Null

Write-Output "Registering the scheduled task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installDir\selfheal.ps1`""

$triggerLogon = New-ScheduledTaskTrigger -AtLogOn
$triggerStartup = New-ScheduledTaskTrigger -AtStartup

$eventTriggerClass = Get-CimClass -Namespace ROOT\Microsoft\Windows\TaskScheduler -ClassName MSFT_TaskEventTrigger
$triggerResume = New-CimInstance -CimClass $eventTriggerClass -ClientOnly
$triggerResume.Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Microsoft-Windows-Power-Troubleshooter''] and EventID=1]]</Select></Query></QueryList>'
$triggerResume.Enabled = $true

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 2)

Unregister-ScheduledTask -TaskName "BluetoothSelfHeal" -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask -TaskName "BluetoothSelfHeal" `
    -Action $action `
    -Trigger @($triggerLogon, $triggerStartup, $triggerResume) `
    -Principal $principal `
    -Settings $settings `
    -Description "Auto-recovers the Bluetooth radio if it enters a Code 10 error state after sleep or logon." `
    -Force -ErrorAction Stop | Out-Null

Write-Output "Running it once to confirm it works..."
Start-ScheduledTask -TaskName "BluetoothSelfHeal" -ErrorAction Stop
Start-Sleep -Seconds 3
$status = (Get-PnpDevice -InstanceId $DeviceInstanceId -ErrorAction SilentlyContinue).Status

Write-Output ""
Write-Output "Done. Device status: $status"
Write-Output "Log file: $installDir\selfheal.log"
Read-Host "Press Enter to close"
