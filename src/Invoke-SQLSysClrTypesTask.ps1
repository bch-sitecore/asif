Function Invoke-SQLSysClrTypesTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $is64 = [System.Environment]::Is64BitOperatingSystem

    #$url32 = "https://download.microsoft.com/download/C/1/9/C1917410-8976-4AE0-98BF-1104349EA1E6/x86/SQLSysClrTypes.msi"
    #$url64 = ("", "https://download.microsoft.com/download/C/1/9/C1917410-8976-4AE0-98BF-1104349EA1E6/x64/SQLSysClrTypes.msi")[$is64]
    $url32 = "http://go.microsoft.com/fwlink/?LinkID=858678" # https://download.microsoft.com/download/C/0/2/C02DBE78-3265-4779-9AE1-634A4BF1CD6E/EN/SQL140/x86/SQLSysClrTypes.msi
    $url64 = "http://go.microsoft.com/fwlink/?LinkID=858692" #"https://download.microsoft.com/download/C/0/2/C02DBE78-3265-4779-9AE1-634A4BF1CD6E/EN/SQL140/amd64/SQLSysClrTypes.msi"
    $outFile32 = Join-Path $env:Temp -ChildPath "SQLSysClrTypes.x86.msi"
    $outFile64 = Join-Path $env:Temp -ChildPath "SQLSysClrTypes.x64.msi"

    If ($PSCmdlet.ShouldProcess("SQLSysClrTypes (x86)", "Install")) {
      Write-Verbose "Installing SQLSysClrTypes (x86)"
      InstallMsi $url32 -OutFile $outFile32
    }
    If ($is64) {
      If ($PSCmdlet.ShouldProcess("SQLSysClrTypes (x64)", "Install")) {
        Write-Verbose "Installing SQLSysClrTypes (x64)"
        InstallMsi $url64 -OutFile $outFile64
      }
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-SQLSysClrTypesTask -As SQLSysClrTypes -Type Task