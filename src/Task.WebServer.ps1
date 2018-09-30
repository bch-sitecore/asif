Function Invoke-WebServerTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $isServer = $null -ne (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue)
    $isInstalled = If ($isServer) { (Get-WindowsFeature "Web-Server").Installed }
                   Else           { "Enabled" -eq (Get-WindowsOptionalFeature -Online -FeatureName "IIS-WebServerRole").State }
  
    Write-TaskInfo -Message $isServer -Tag "isServer"
    Write-TaskInfo -Message $isInstalled -Tag "isInstalled"

    If (!$isInstalled) {
      If ($PSCmdlet.ShouldProcess("IIS/WebServer", "Install")) {
        If ($isServer) {
          Write-Verbose "Installing IIS/WebServer using Install-WindowsFeature"
          Install-WindowsFeature Web-Server -IncludeAllSubFeature -IncludeManagementTools
        } Else {
          Write-Verbose "Installing IIS/WebServer using Enable-WindowsOptionalFeature"
          @(
            "IIS-WebServerRole", "IIS-WebServer", "IIS-WebServerManagementTools"
          ) | ForEach-Object {
            Write-TaskInfo -Message $_ -Tag "FeatureName"
            Enable-WindowsOptionalFeature -Online -FeatureName $_
          }
        }
      }
    } Else {
      Write-Verbose "IIS/WebServer already exists"
      Write-TaskInfo -Message "IIS/WebServer" -Tag "Exists"
    }
    If ($PSCmdlet.ShouldProcess("Additional features", "Install")) {
      $featureName = @(
        "IIS-ApplicationDevelopment", "IIS-ASPNET45",               "IIS-CommonHttpFeatures",
        "IIS-DefaultDocument",        "IIS-DirectoryBrowsing",      "IIS-HealthAndDiagnostics",
        "IIS-HttpCompressionStatic",  "IIS-HttpErrors",             "IIS-HttpLogging",
        "IIS-ISAPIExtensions",        "IIS-ISAPIFilter",            "IIS-NetFxExtensibility45",
        "IIS-Performance",            "IIS-RequestFiltering",       "IIS-Security",
        "IIS-StaticContent",          "NetFx4Extended-ASPNET45"
      ) | ForEach-Object {
        Write-TaskInfo -Message $_ -Tag "FeatureName"
        Enable-WindowsOptionalFeature -Online -FeatureName $_
      }
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-WebServerTask -As WebServer -Type Task