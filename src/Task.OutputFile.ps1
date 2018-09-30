Function Invoke-OutputFileTask {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$Path
  )
  Process {
    Write-TaskInfo -Message $Path -Tag "Path"
    Get-Content $Path | ForEach-Object -Begin { $line = 1 } { Write-TaskInfo -Message $_ -Tag $line++ }
  }
}
Register-SitecoreInstallExtension -Command Invoke-OutputFileTask -As OutputFile -Type Task