# Checks the Bluetooth radio and fixes it if it is stuck in an error state (e.g. Code 10).
# Meant to be run by the scheduled task that install.ps1 registers, but can be run manually too.

$DeviceInstanceId = "USB\VID_8087&PID_0032\8&F2CB6FA&0&13"

$logDir = "C:\ProgramData\BluetoothSelfHeal"
$log = Join-Path $logDir "selfheal.log"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$dev = Get-PnpDevice -InstanceId $DeviceInstanceId -ErrorAction SilentlyContinue
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if (-not $dev -or $dev.Status -ne 'OK') {
    "$stamp - device status '$($dev.Status)', attempting fix" | Out-File $log -Append
    try {
        pnputil /remove-device $DeviceInstanceId | Out-Null
        Start-Sleep -Seconds 2
        pnputil /scan-devices | Out-Null
        Start-Sleep -Seconds 3
        $after = Get-PnpDevice -InstanceId $DeviceInstanceId -ErrorAction SilentlyContinue
        "$stamp - fix attempted, resulting status: $($after.Status)" | Out-File $log -Append
    } catch {
        "$stamp - fix FAILED: $($_.Exception.Message)" | Out-File $log -Append
    }
} else {
    "$stamp - device status OK, no action needed" | Out-File $log -Append
}
