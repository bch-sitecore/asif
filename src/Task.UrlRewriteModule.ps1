Function Invoke-URLRewriteModuleTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $url32 = "http://download.microsoft.com/download/6/8/F/68F82751-0644-49CD-934C-B52DF91765D1/rewrite_x86_en-US.msi"
    $url64 = "http://download.microsoft.com/download/D/D/E/DDE57C26-C62C-4C59-A1BB-31D58B36ADA2/rewrite_amd64_en-US.msi"

    $url = ($url32, $url64)[[System.Environment]::Is64BitOperatingSystem]
    $outFile = Join-Path $env:TEMP -ChildPath "rewrite_en-US.msi"

    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"

    If ($PSCmdlet.ShouldProcess("Install URL Rewrite Module")) {
      Write-Verbose "Installing URL Rewrite Module"
      InstallMsi $url -OutFile $outFile
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-URLRewriteModuleTask -As URLRewriteModule -Type Task