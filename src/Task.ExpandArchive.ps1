Function Invoke-ExpandArchiveTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Source
    ,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Destination
    ,
    [Parameter()]
    [switch]$RemoveAfter
    ,
    [Parameter()]
    [switch]$Force
  )
  Process {
    Write-TaskInfo -Message $Source -Tag "Source"
    Write-TaskInfo -Message $Destination -Tag "Destination"
    Write-TaskInfo -Message $Force -Tag "Force"

    $Source | ForEach-Object {
      Write-TaskInfo -Message $_ -Tag "Source"
      Convert-Path $_ | ForEach-Object {
        $file = $_
        Write-TaskInfo -Message $file -Tag "File"
        If ($PSCmdlet.ShouldProcess($file, "Extract")) {
          If (!(test-Path $Destination)) {
            New-Item $Destination -ItemType Container | Out-Null
          }
          Expand-Archive $file -DestinationPath $Destination -Force:$Force
        }
        If ($RemoveAfter -and $PSCmdlet.ShouldProcess($_, "Remove")) {
          Remove-Item $file -Force:$Force
        }
      }
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-ExpandArchiveTask -As ExpandArchive -Type Task