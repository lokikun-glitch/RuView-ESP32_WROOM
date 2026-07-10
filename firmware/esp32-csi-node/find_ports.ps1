Add-Type -AssemblyName System.Management

$searcher = New-Object System.Management.ManagementObjectSearcher(
    "SELECT * FROM Win32_PnPEntity WHERE Name LIKE '%(COM%'"
)

$ports = $searcher.Get()

if ($ports.Count -eq 0) {
    Write-Host "No COM devices found via WMI." -ForegroundColor Yellow
} else {
    foreach ($p in $ports) {
        Write-Host $p.Name
    }
}
