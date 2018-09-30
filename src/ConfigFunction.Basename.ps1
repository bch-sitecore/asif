Function Invoke-BasenameConfigFunction {
  Param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )
  Process {
    Write-Verbose "Invoke-BasenameConfigFunction: basename(${Path})"
    $FullPath = If ($Path.IndexOf("*") -gt 0) { Convert-Path $Path } Else { $Path }
    Write-Verbose "Invoke-BasenameConfigFunction: basename(${FullPath})"
    $result = [System.IO.Path]::GetFileNameWithoutExtension($FullPath)
    Write-Verbose "Invoke-BasenameConfigFunction: ${result}"
    Return $result
  }
}
Register-SitecoreInstallExtension -Command Invoke-BasenameConfigFunction -As Basename -Type ConfigFunction