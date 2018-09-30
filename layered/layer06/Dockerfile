# escape=`
ARG BASEIMAGE
FROM ${BASEIMAGE}
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

ARG dotnet_sdk="https://download.microsoft.com/download/8/A/7/8A765126-50CA-4C6F-890B-19AE47961E4B/dotnet-sdk-2.1.402-win-x64.exe"
ARG dotnet_hosting="https://download.microsoft.com/download/3/a/3/3a3bda26-560d-4d8e-922e-6f6bc4553a84/DotNetCore.2.0.9-WindowsHosting.exe"
RUN Invoke-WebRequest $env:dotnet_sdk -OutFile '.\dotnet-sdk.exe' -UseBasicParsing ; `
    Start-Process '.\dotnet-sdk.exe' -ArgumentList /install, /quiet, /norestart -Wait ; `
    Remove-Item '.\dotnet-sdk.exe' ; `
    Invoke-WebRequest $env:dotnet_hosting -OutFile '.\dotnet-hosting.exe' -UseBasicParsing ; `
    Start-Process '.\dotnet-hosting.exe' -ArgumentList /install, /quiet, /norestart -Wait ; `
    Remove-Item '.\dotnet-hosting.exe'

COPY . /
WORKDIR /resourcefiles
RUN Get-InstalledModule | Out-Null ; Install-SitecoreConfiguration -Path .\config.json

ENTRYPOINT ["powershell"]