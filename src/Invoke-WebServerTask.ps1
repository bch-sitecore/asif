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
            "IIS-WebServerRole",          "IIS-WebServer",              "IIS-WebServerManagementTools",
            "IIS-ApplicationDevelopment", "IIS-ASPNET45",               "IIS-CommonHttpFeatures",
            "IIS-DefaultDocument",        "IIS-DirectoryBrowsing",      "IIS-HealthAndDiagnostics",
            "IIS-HttpCompressionStatic",  "IIS-HttpErrors",             "IIS-HttpLogging",
            "IIS-ISAPIExtensions",        "IIS-ISAPIFilter",            "IIS-NetFxExtensibility45",
            "IIS-Performance",            "IIS-RequestFiltering",       "IIS-Security",
            "IIS-StaticContent",          "NetFx4Extended-ASPNET45"
          ) | ForEach-Object {
            Enable-WindowsOptionalFeature -Online -FeatureName $_
          }
        }
      }
    } Else {
      Write-Verbose "IIS/WebServer already exists"
      Write-TaskInfo -Message "IIS/WebServer" -Tag "Exists"
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-WebServerTask -As WebServer -Type Task

Function Invoke-URLRewriteModuleTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $url32 = "http://download.microsoft.com/download/6/8/F/68F82751-0644-49CD-934C-B52DF91765D1/rewrite_x86_en-US.msi"
    $url64 = "http://download.microsoft.com/download/D/D/E/DDE57C26-C62C-4C59-A1BB-31D58B36ADA2/rewrite_amd64_en-US.msi"

    $url = ($url32, $url64)[[System.Environment]::Is64BitOperatingSystem]
    $outFile = Join-Path $env:TEMP -ChildPath "rewrite_en-US.msi"

    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"

    If ($PSCmdlet.ShouldProcess("Install URL Rewrite Module")) {
      Write-Verbose "Installing URL Rewrite Module"
      InstallMsi $url -OutFile $outFile
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-URLRewriteModuleTask -As URLRewriteModule -Type Task

Function Invoke-WebDeployModuleTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param()
  Process {
    $url32 = "http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_x86_en-US.msi"
    $url64 = "http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"

    $url = ($url32, $url64)[[System.Environment]::Is64BitOperatingSystem]
    $outFile = Join-Path $env:TEMP -ChildPath "WebDeploy_en-US.msi"

    Write-TaskInfo -Message $url -Tag "url"
    Write-TaskInfo -Message $outFile -Tag "outFile"

    If ($PSCmdlet.ShouldProcess("Install WebDeploy Module")) {
      Write-Verbose "Installing WebDeploy Module"
      InstallMsi $url -OutFile $outFile
    }
  }
}
Register-SitecoreInstallExtension -Command Invoke-WebDeployModuleTask -As WebDeployModule -Type Task