Function Invoke-ElementAtConfigFunction {
  Param(
    [Parameter(Mandatory = $true)]
    [string[]]$InputObject
    ,
    [Parameter(Mandatory = $true)]
    [int]$Index
  )
  Begin {
    $absIndex = [Math]::Abs($Index)
    $count = $InputObject.Count
  }
  Process {
    If ($count -le $absIndex) {
      Throw "Too few objects, unable to fetch element at index ${Index}"
    }
    If ($Index -lt 0) {
      $Index += $count
    }
    $InputObject[$Index]
  }
}
Register-SitecoreInstallExtension -Command Invoke-ElementAtConfigFunction -As ElementAt -Type ConfigFunction