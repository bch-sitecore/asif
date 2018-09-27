Function Invoke-GreetTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name
  )
  Process {
    If ($PSCmdlet.ShouldProcess($Name, "Greet")) {
      Write-Output "Hello, ${Name}"
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-GreetTask -As Greet -Type Task
