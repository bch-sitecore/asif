Function Invoke-SplitConfigFunction {
  Param(
    [Parameter(Mandatory = $true)]
    [string]$InputObject
    ,
    [Parameter()]
    [string]$Delimeter = " "
  )
  Process {
    $InputObject -split $Delimeter
  }
}
Register-SitecoreInstallExtension -Command Invoke-SplitConfigFunction -As Split -Type ConfigFunction