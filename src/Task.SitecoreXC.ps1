Function Invoke-SitecoreXCTask {
  [CmdletBinding(SupportsShouldProcess = $true)]
  Param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$WorkingDirectory
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SiteName = "ConnectSite"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SiteHostHeaderName = "sxa.storefront.com"
    ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SqlDbPrefix = $SiteName
    ,
    [Parameter()]
    [ValidateSet("SOLR", "AZURE")]
    [string]$CommerceSearchProvider = "SOLR"
  )
  Begin {
    Write-TaskInfo -Message $WorkingDirectory -Tag "WorkingDirectory"
    Write-TaskInfo -Message $SiteName -Tag "SiteName"
    Write-TaskInfo -Message $SiteHostHeaderName -Tag "SiteHostHeaderName"
    Write-TaskInfo -Message $SqlDbPrefix -Tag "SqlDbPrefix"
    Write-TaskInfo -Message $CommerceSearchProvider -Tag "SearchProvider"

    Push-Location $WorkingDirectory
    $global:DEPLOYMENT_DIRECTORY = $WorkingDirectory #BC Split-Path $MyInvocation.MyCommand.Path

    #tree /A /F (Resolve-Path "..\")
  }
  Process {
    # Add modules to $env:PSModulePath
    $modulesPath = Convert-Path ".\Modules"
    If (!(Test-Path $modulesPath)) {
      Write-Error "Unable to find Modules"
    }
    $envTarget = [System.EnvironmentVariableTarget]::User
    $PSModulePath = $env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath", $envTarget)
    $env:PSModulePath += "{0}{1}" -f [System.IO.Path]::PathSeparator, $modulesPath
    [System.Environment]::SetEnvironmentVariable("PSModulePath", $env:PSModulePath, $envTarget)

    $cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My `
      -DnsName $SiteHostHeaderName
    Export-Certificate -Cert $cert -FilePath "..\storefront.engine.cer" | Out-Null

    $params = @{
      Path = Resolve-Path '.\Configuration\Commerce\Master_SingleServer.json'
      SiteName = $SiteName
      SiteHostHeaderName = $SiteHostHeaderName
      InstallDir = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$SiteName"
      XConnectInstallDir = "$($Env:SYSTEMDRIVE)\inetpub\wwwroot\$($SiteName)_xconnect"
      CertificateName = $SiteName
      CommerceServicesDbServer = "localhost" #BC $($Env:COMPUTERNAME)    #OR "SQLServerName\SQLInstanceName"
      CommerceServicesDbName = "SitecoreCommerce9_SharedEnvironments"
      CommerceServicesGlobalDbName = "SitecoreCommerce9_Global"
      SitecoreDbServer = "localhost" #BC $($Env:COMPUTERNAME)            #OR "SQLServerName\SQLInstanceName"
      SitecoreCoreDbName = "$($SqlDbPrefix)_Core"
      SitecoreUsername = "sitecore\admin"
      SitecoreUserPassword = "b"
      CommerceSearchProvider = $CommerceSearchProvider
      SolrUrl = "https://solr.sc:8983/solr" #BC "https://localhost:8983/solr"
      SolrRoot = Join-Path $env:ProgramData -ChildPath "solr-*" -Resolve #BC "c:\\solr-6.6.2"
      SolrService = "Apache Solr 6.6.2" #BC "Solr-6.6.2"
      SolrSchemas = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "SolrSchemas" )
      SearchIndexPrefix = ""
      AzureSearchServiceName = ""
      AzureSearchAdminKey = ""
      AzureSearchQueryKey = ""
      CommerceEngineDacPac = FindFile -Path "..\Sitecore.Commerce.Engine.SDK.*\Sitecore.Commerce.Engine.DB.dacpac"
      CommerceOpsServicesPort = "5015"
      CommerceShopsServicesPort = "5005"
      CommerceAuthoringServicesPort = "5000"
      CommerceMinionsServicesPort = "5010"
      SitecoreCommerceEngineZipPath = FindFile "..\Sitecore.Commerce.Engine.*.zip"
      SitecoreBizFxServicesContentPath = FindPath -Path "..\Sitecore.BizFX.*" -
      SitecoreIdentityServerZipPath = FindFile -Path "..\Sitecore.IdentityServer.1.*.zip"
      CommerceEngineCertificatePath = FindFile -Path "..\storefront.engine.cer"
      SiteUtilitiesSrc = ( Join-Path -Path $DEPLOYMENT_DIRECTORY -ChildPath "SiteUtilityPages" )
      HabitatImagesModuleFullPath = FindFile -Path "..\Sitecore.Commerce.Habitat.Images-*.zip"
      AdvImagesModuleFullPath = FindFile -Path "..\Adventure Works Images.zip"
      CommerceConnectModuleFullPath = FindFile -Path "..\Sitecore Commerce Connect*.zip"
      CommercexProfilesModuleFullPath = FindFile -Path "..\Sitecore Commerce ExperienceProfile Core *.zip"
      CommercexAnalyticsModuleFullPath = FindFile -Path "..\Sitecore Commerce ExperienceAnalytics Core *.zip"
      CommerceMAModuleFullPath = FindFile -Path "..\Sitecore Commerce Marketing Automation Core *.zip"
      CommerceMAForAutomationEngineModuleFullPath = FindFile -Path "..\Sitecore Commerce Marketing Automation for AutomationEngine *.zip"
      CEConnectPackageFullPath = FindFile -Path "..\Sitecore.Commerce.Engine.Connect*.update"
      PowerShellExtensionsModuleFullPath = FindFile -Path "..\Sitecore PowerShell Extensions*.zip"
      SXAModuleFullPath = FindFile -Path "..\Sitecore Experience Accelerator*.zip"
      SXACommerceModuleFullPath = FindFile -Path "..\Sitecore Commerce Experience Accelerator 1.*.zip"
      SXAStorefrontModuleFullPath = FindFile -Path "..\Sitecore Commerce Experience Accelerator Storefront 1.*.zip"
      SXAStorefrontThemeModuleFullPath = FindFile -Path "..\Sitecore Commerce Experience Accelerator Storefront Themes*.zip"
      SXAStorefrontCatalogModuleFullPath = FindFile -Path "..\Sitecore Commerce Experience Accelerator Habitat Catalog*.zip"
      MergeToolFullPath = FindFile -Path "..\Microsoft.Web.XmlTransform.dll" #BC "..\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath\Web\Microsoft.Web.XmlTransform.dll"
      UserAccount = @{
        Domain = $Env:COMPUTERNAME
        UserName = 'CSFndRuntimeUser'
        Password = 'Pu8azaCr'
      }
      BraintreeAccount = @{
        MerchantId = ''
        PublicKey = ''
        PrivateKey = ''
      }
      SitecoreIdentityServerName = "SitecoreIdentityServer"
    }

    Write-Verbose ($params | ConvertTo-Json)

    If ($CommerceSearchProvider -eq "SOLR") {
      Install-SitecoreConfiguration @params
    } ElseIf ($CommerceSearchProvider -eq "AZURE"){
      Install-SitecoreConfiguration @params -Skip InstallSolrCores
    }
  }
  End {
    Pop-Location

    $env:PSModulePath = $PSModulePath
    [System.Environment]::SetEnvironmentVariable("PSModulePath", $env:PSModulePath, $envTarget)
  }
}
Register-SitecoreInstallExtension -Command Invoke-SitecoreXCTask -As SitecoreXC -Type Task

Function FindFile {
  Param([string]$Path)
  Process {
    If (Test-Path $Path) {
      Convert-Path $Path | Where-Object { Test-Path $_ -PathType Leaf } | Select-Object -First 1
    }
  }
}
Function FindPath {
  Param([string]$Path)
  Process {
    If (Test-Path $Path) {
      Convert-Path $Path | Where-Object { Test-Path $_ -PathType Container } | Select-Object -First 1
    }
  }
}