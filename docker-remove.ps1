#!/usr/bin/env pwsh
param(
    [string]$ns=$(throw "-ns required")
)
$ErrorActionPreference="Stop"

docker rm -f "$ns-sql"
docker rm -f "$ns-phpmyadmin"
docker network rm "$ns-net"