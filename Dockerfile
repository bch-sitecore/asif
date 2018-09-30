# escape=`
ARG BASEIMAGE
FROM ${BASEIMAGE}
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

# Setup
ENV SIFRepoName="SitecoreGallery" `
    SIFRepoLocation="https://sitecore.myget.org/F/sc-powershell/api/v2" `
    SIFModuleName="SitecoreInstallFramework"
RUN Install-PackageProvider -Name "NuGet" -Force ; `
    Register-PSRepository $env:SIFRepoName -SourceLocation $env:SIFRepoLocation -InstallationPolicy Trusted ; `
    Install-Module $env:SIFModuleName -Repository $env:SIFRepoName

# Execute
COPY . /
WORKDIR /resourcefiles
RUN Install-SitecoreConfiguration -Path .\sitecore-onebox.json

# Cleanup
WORKDIR /
RUN Remove-Item \resourcefiles -Recurse ; `
    Uninstall-Module $env:SIFModuleName -Force ; `
    Unregister-PSRepository $env:SIFRepoName -Force

ENTRYPOINT ["powershell"]