Function Invoke-WebDeployModuleTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $url32 = "http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_x86_en-US.msi"
    $url64 = "http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"

    $url = ($url32, $url64)[[System.Environment]::Is64BitOperatingSystem]
    $outFile = Join-Path $env:TEMP -ChildPath "WebDeploy_en-US.msi"

    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"

    If ($PSCmdlet.ShouldProcess("Install WebDeploy Module")) {
      Write-Verbose "Installing WebDeploy Module"
      InstallMsi $url -OutFile $outFile
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-WebDeployModuleTask -As WebDeployModule -Type Task