# Run as Administrator.
# Removes the scheduled task and the installed self heal script.
# Leaves the Fast Startup / USB selective suspend settings as they are, those are safe to keep.

#Requires -RunAsAdministrator

Write-Output "Removing scheduled task..."
Unregister-ScheduledTask -TaskName "BluetoothSelfHeal" -Confirm:$false -ErrorAction SilentlyContinue

Write-Output "Removing installed files..."
Remove-Item -Path "C:\ProgramData\BluetoothSelfHeal" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "Done."
