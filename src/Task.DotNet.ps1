Function Invoke-DotNetTask {
  [CmdletBinding()]
  Param()
  Begin {
    # TODO: add x86
    $sdkUrl = "https://download.microsoft.com/download/8/A/7/8A765126-50CA-4C6F-890B-19AE47961E4B/dotnet-sdk-2.1.402-win-x64.exe"
    $sdkOutFile = Join-Path $env:TEMP -ChildPath "dotnet-sdk-2.1.402-win-x64.exe"
    $hostingUrl = "https://download.microsoft.com/download/3/a/3/3a3bda26-560d-4d8e-922e-6f6bc4553a84/DotNetCore.2.0.9-WindowsHosting.exe"
    $hostingOutFile = Join-Path $env:TEMP -ChildPath "DotNetCore.2.0.9-WindowsHosting.exe"
  }
  Process {
    InstallExe $sdkUrl -OutFile $sdkOutFile -ArgumentList /install, /quiet, /norestart
    InstallExe $hostingUrl -OutFile $hostingOutFile -ArgumentList /install, /quiet, /norestart
  }
}