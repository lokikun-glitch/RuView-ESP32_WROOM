$desktop = [Environment]::GetFolderPath('Desktop')
Write-Host "True Desktop Path: $desktop" -ForegroundColor Cyan

$dest = "$desktop\RuView_Binaries"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$src = "C:\Projects\RuView\RuView\firmware\esp32-csi-node\build"

Copy-Item "$src\esp32-csi-node.bin" -Destination $dest
Copy-Item "$src\bootloader\bootloader.bin" -Destination $dest
Copy-Item "$src\partition_table\partition-table.bin" -Destination $dest
Copy-Item "$src\ota_data_initial.bin" -Destination $dest

Write-Host "Success! The 4 bin files are now inside: $dest" -ForegroundColor Green
