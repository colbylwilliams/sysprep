# Syspreps an Azure VM

# docs: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-troubleshoot#sysprep-timing
Write-Host '>>> Waiting for GA Service (RdAgent) to start ...'
while ((Get-Service RdAgent -ErrorAction SilentlyContinue) -and ((Get-Service RdAgent).Status -ne 'Running')) { Start-Sleep -s 5 }

Write-Host '>>> Waiting for GA Service (WindowsAzureTelemetryService) to start ...'
while ((Get-Service WindowsAzureTelemetryService -ErrorAction SilentlyContinue) -and ((Get-Service WindowsAzureTelemetryService).Status -ne 'Running')) { Start-Sleep -s 5 }

Write-Host '>>> Waiting for GA Service (WindowsAzureGuestAgent) to start ...'
while ((Get-Service WindowsAzureGuestAgent -ErrorAction SilentlyContinue) -and ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running')) { Start-Sleep -s 5 }


Write-Host '>>> Sysprepping VM ...'
Remove-Item $Env:Windir\Panther -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $Env:SystemRoot\system32\Sysprep\unattend.xml -Force -ErrorAction SilentlyContinue

# docs: https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-command-line-options?view=windows-11
& $Env:SystemRoot\System32\Sysprep\Sysprep.exe /oobe /mode:vm /generalize /quiet /quit

# while ($true) { $imageState = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State).ImageState; Write-Output $imageState; if ($imageState -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { break }; Start-Sleep -s 5 }

$imageStateCompleteCount = 0

while ($true) {

     if ($imageStateCompleteCount -gt 12)
     {
          Write-Host '===> SYSPREP ACTLOG'
          Get-Content -Path 'C:\windows\system32\sysprep\panther\setupact.log' -ErrorAction SilentlyContinue
          
          Write-Host '===> SYSPREP ERRLOG'
          Get-Content -Path 'C:\windows\system32\sysprep\panther\setuperr.log' -ErrorAction SilentlyContinue
          
          exit 1
     }

     $imageState = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State).ImageState
     Write-Output $imageState
     
     if ($imageState -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE')
     {
          break
     }
     
     if ($imageState -eq 'IMAGE_STATE_COMPLETE') {
          $imageStateCompleteCount += 1
     }

     Start-Sleep -s 5
}

Write-Host '>>> Sysprep complete ...'
Write-Host '>>> Shutting down VM ...'
