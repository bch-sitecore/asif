
Function Invoke-SqlServerModuleTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $moduleName = "SqlServer"
    $moduleNamespace = "Microsoft.SqlServer.Management.Smo"
  
    If ($PSCmdlet.ShouldProcess("PSModule:$($moduleName)", "Install")) {
      If ($null -eq (Get-Module $moduleName -ListAvailable -ErrorAction SilentlyContinue)) {
        Install-Module $moduleName -AllowClobber -Force
      }
      Import-Module $moduleName
      [System.Reflection.Assembly]::LoadWithPartialName($moduleNamespace) | Out-Null
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-SqlServerModuleTask -As SqlServerModule -Type Task