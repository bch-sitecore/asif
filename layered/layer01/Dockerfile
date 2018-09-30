# escape=`
ARG BASEIMAGE
FROM ${BASEIMAGE}
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

ENV SIFRepoName="SitecoreGallery" `
    SIFRepoLocation="https://sitecore.myget.org/F/sc-powershell/api/v2" `
    SIFModuleName="SitecoreInstallFramework"

RUN Install-PackageProvider -Name "NuGet" -Force ; `
    Register-PSRepository $env:SIFRepoName -SourceLocation $env:SIFRepoLocation -InstallationPolicy Trusted ; `
    Install-Module $env:SIFModuleName -Repository $env:SIFRepoName

COPY . /
WORKDIR /resourcefiles
RUN Install-SitecoreConfiguration -Path .\config.json

ENTRYPOINT ["powershell"]