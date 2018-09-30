# escape=`
ARG BASEIMAGE
FROM ${BASEIMAGE}
SHELL ["powershell", "-Command", "$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue';"]

COPY . /
WORKDIR /resourcefiles
RUN Install-SitecoreConfiguration -Path .\config.json -Verbose

ENTRYPOINT ["powershell"]