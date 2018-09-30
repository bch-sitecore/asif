Function Invoke-DacFxTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $is64 = [System.Environment]::Is64BitOperatingSystem

    # DacFx requires BOTH be installed if x64
    #$url32 = "https://download.microsoft.com/download/5/E/4/5E4FCC45-4D26-4CBE-8E2D-79DB86A85F09/EN/x86/DacFramework.msi"
    #$url64 = ("", "https://download.microsoft.com/download/5/E/4/5E4FCC45-4D26-4CBE-8E2D-79DB86A85F09/EN/x64/DacFramework.msi")[$is64]
    $url32 = "https://download.microsoft.com/download/D/5/C/D5CFC940-DA21-44D3-84FF-A0FD147F1681/EN/x86/DacFramework.msi"
    $url64 = ("", "https://download.microsoft.com/download/D/5/C/D5CFC940-DA21-44D3-84FF-A0FD147F1681/EN/x64/DacFramework.msi")[$is64]

    $outFile32 = Join-Path $env:Temp -ChildPath "DacFramework.x86.msi"
    $outFile64 = Join-Path $env:Temp -ChildPath "DacFramework.x64.msi"

    If ($PSCmdlet.ShouldProcess("SQLSysClrTypes (x86)", "Install")) {
      Write-TaskInfo -Message "Installing SQLSysClrTypes" -Tag "x86"
      InstallMsi $url32 -OutFile $outFile32
    }
    If ($is64) {
      If ($PSCmdlet.ShouldProcess("SQLSysClrTypes (x64)", "Install")) {
        Write-TaskInfo -Message "Installing SQLSysClrTypes" -Tag "x64"
        InstallMsi $url64 -OutFile $outFile64
      }
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-DacFxTask -As DacFx -Type Task