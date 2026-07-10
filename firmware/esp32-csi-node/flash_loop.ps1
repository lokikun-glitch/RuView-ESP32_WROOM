while ($true) {
    Write-Host "`n>>> WAITING FOR BOOT+EN SEQUENCE <<<" -ForegroundColor Yellow
    C:\Espressif\python_env\idf5.5_py3.13_env\Scripts\python.exe -m esptool --chip esp32 --port COM19 --baud 115200 write_flash --flash_mode dout --flash_freq 40m --flash_size 4MB 0x1000 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0xf000 build\ota_data_initial.bin 0x20000 build\esp32-csi-node.bin
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Flash SUCCESS!" -ForegroundColor Green
        break
    }
    Write-Host "Flash failed, retrying in 2 seconds..." -ForegroundColor Red
    Start-Sleep -Seconds 2
}
