Function Invoke-VC15RedistTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $version = "2015"
    $url32 = "https://download.microsoft.com/download/6/D/F/6DF3FF94-F7F9-4F0B-838C-A328D1A7D0EE/vc_redist.x86.exe"
    $url64 = "https://download.microsoft.com/download/6/D/F/6DF3FF94-F7F9-4F0B-838C-A328D1A7D0EE/vc_redist.x64.exe"

    $url = ($url32, $url64)[[System.Environment]::Is64BitOperatingSystem]
    $outFile = Join-Path $env:Temp -ChildPath "vc_redist.exe"

    Write-TaskInfo -Message $version -Tag "version"
    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"
  
    If ($PSCmdlet.ShouldProcess("VC++ $($version) Redist.", "Install")) {
      Write-Verbose "Installing VC++ $($version) Redist."
      InstallExe $url -OutFile $outFile -ArgumentList "/quiet", "/passive", "/norestart"
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-VC15RedistTask -As VC15Redist -Type Task

Function Invoke-VC17RedistTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $version = "2017"
    $url32 = "https://aka.ms/vs/15/release/VC_redist.x86.exe"
    $url64 = "https://aka.ms/vs/15/release/VC_redist.x64.exe"

    $url = ($url32, $url64)[[System.Environment]::Is64BitOperatingSystem]
    $outFile = Join-Path $env:Temp -ChildPath "vc_redist.exe"

    Write-TaskInfo -Message $version -Tag "version"
    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"
  
    If ($PSCmdlet.ShouldProcess("VC++ $($version) Redist.", "Install")) {
      Write-Verbose "Installing VC++ $($version) Redist."
      InstallExe $url -OutFile $outFile -ArgumentList "/quiet", "/passive", "/norestart"
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-VC17RedistTask -As VC17Redist -Type Task