#!/usr/bin/env pwsh
param(
    [string]$ns=$(throw "-ns required"),
    [int]$mysqlPort=$(throw "-mysqlPort required"),
    [int]$phpMyAdminPort=$(throw "-phpMyAdminPort"),
    [string]$dbName="cms"
)
$ErrorActionPreference="Stop"

docker network create "$ns-net"

docker run --name "$ns-sql" -d -p "$($mysqlPort):3306" --net "$ns-net" `
    -e MYSQL_ROOT_PASSWORD=SQLPasss `
    -e MYSQL_USER=sqluser `
    -e MYSQL_PASSWORD=SQLPasss `
    -e MYSQL_DATABASE=$dbName `
    mysql/mysql-server:8.0.13 --default-authentication-plugin=mysql_native_password
if(!$?){
    throw "create mysql failed"
}

docker run --name "$ns-phpmyadmin" -d -p "$($phpMyAdminPort):80" --net "$ns-net" -e "PMA_HOST=$ns-sql" phpmyadmin/phpmyadmin
if(!$?){
    throw "create phpmyadmin failed"
}

Write-Host "Setup successfully" -ForegroundColor DarkGreen
Write-Host "MySQL - port=$mysqlPort" -ForegroundColor Cyan
Write-Host "PhpMyAdmin - http://localhost:$phpMyAdminPort" -ForegroundColor Cyan