Function Invoke-NssmTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $version = "2.24"
    $url = "https://nssm.cc/release/nssm-$($version).zip"
    $outFile = Join-Path $env:TEMP -ChildPath "nssm-$($version).zip"
    $installPathPattern = Join-Path $env:ProgramData -ChildPath "nssm-*"
    $isInstalled = $null -ne (Get-Command "nssm" -ErrorAction SilentlyContinue)

    Write-TaskInfo -Message $version -Tag "version"
    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"
    Write-TaskInfo -Message $isInstalled -Tag "isInstalled"
    Write-TaskInfo -Message $installPathPattern -Tag "installPathPattern"
    
    If (!($isInstalled)) {
      Write-Verbose "Installing NSSM"

      ExpandArchive $url -OutFile $outFile -DestinationPath $env:ProgramData

      If ($PSCmdlet.ShouldProcess("`$env:PATH", "Update")) {
        $installPath = Convert-Path $installPathPattern
        Write-TaskInfo -Message $installPath -Tag "installPath"

        $nssmBin = Join-Path $installPath -ChildPath ("win32","win64")[[Environment]::Is64BitOperatingSystem]
        Write-TaskInfo -Message $nssmBin -Tag "nssmBin"

        Write-Verbose "Adding '$($nssmBin)' to `$env:PATH"
        AddPath $nssmBin
      }
    } Else {
      Write-Verbose "NSSM already exists"
      Write-TaskInfo -Message "NSSM" -Tag "Exists"
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-NssmTask -As Nssm -Type Task