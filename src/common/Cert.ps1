<#
  .SYNOPSIS
    Gets a certificate (if present) by the specified lookup method.
  .PARAMETER ByDnsName
    Retrieve certificate by the supplied dns name.
  .PARAMETER ByFriendlyName
    Retrieve certificate by the supplied friendly name.
  .PARAMETER Thumbprint
    Retrieve certificate by the supplied certificate thumbprint.
  .PARAMETER CertStoreLocation
    Certificate store location to search (Defaults to Cert:\LocalMachine\My)
#>
Function GetCert {
  [CmdletBinding(DefaultParameterSetName = "ByDnsName")]
  Param(
    [Parameter(ParameterSetName = "ByDnsName", Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ByDnsName
    ,
    [Parameter(ParameterSetName = "ByFriendlyName", Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ByFriendlyName
    ,
    [Parameter(ParameterSetName = "ByThumbprint", Position = 0, Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ByThumbprint
    ,
    [Parameter(ParameterSetName = "ByDnsName", Position = 1)]
    [Parameter(ParameterSetName = "ByFriendlyName", Position = 1)]
    [Parameter(ParameterSetName = "ByThumbprint", Position = 1)]
    [ValidateDrive("Cert")] #[ValidateScript({ $_.StartsWith("cert:\", "CurrentCultureIgnoreCase") })]
    [Alias("In")]
    [string]$CertStoreLocation = "Cert:\LocalMachine\My"
  )
  Begin {
    Switch ($PSCmdlet.ParameterSetName) {
      ByDnsName {
        $criteria = "DnsName=$($ByDnsName)"
        $filter = { $ByDnsName -eq $_.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false) }
      }
      ByFriendlyName {
        $criteria = "FriendlyName=$($ByFriendlyName)"
        $filter = { $ByFriendlyName -eq $_.FriendlyName }
      }
      ByThumbprint {
        $criteria = "Thumbprint=$($ByThumbprint)"
        $filter = { $ByThumbprint -eq $_.Thumbprint }
      }
    }
  }
  Process {
    Write-Verbose "Searching for certificate in $($CertStoreLocation) with $($criteria)"
    $matches = Get-ChildItem $CertStoreLocation -Recurse | Where-Object $filter

    If (!$matches) {
      Write-Verbose "No matching certificate(s) found."
    } ElseIf (($matches | Measure-Object).Count -gt 1) {
      Write-Error "Multiple certificates matching "
    } Else {
      Write-Verbose "Certificate found ($($CertStoreLocation)\$($matches.Thumbprint))"
    }

    $matches
  }
}