
Function Invoke-SqlServerModuleTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $moduleName = "SqlServer"
    $moduleNamespace = "Microsoft.SqlServer.Management.Smo"
  
    If ($PSCmdlet.ShouldProcess("PSModule:$($moduleName)", "Install")) {
      If ($null -eq (Get-InstalledModule $moduleName -AllVersions -ErrorAction SilentlyContinue)) {
        Write-TaskInfo -Message "Module not found, installing" -Tag $moduleName
        Install-Module $moduleName -AllowClobber -Force
      }
      Write-TaskInfo -Message "Importing module" -Tag $moduleName
      Import-Module $moduleName
      Write-Verbose "Importing namespace"
      Write-TaskInfo -Message $moduleNamespace -Tag "namespace"
      [System.Reflection.Assembly]::LoadWithPartialName($moduleNamespace) | Out-Null
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-SqlServerModuleTask -As SqlServerModule -Type Task