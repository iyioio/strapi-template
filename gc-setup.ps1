#!/usr/bin/env pwsh
param(
    [int]$step=-2, # -1 == all steps, -2 == no steps
    [switch]$noLogin,
    [switch]$allSteps,
    [switch]$recreateDbuser,
    [switch]$getSecrets,
    [switch]$getUrl,
    [switch]$getServiceInfo,
    [switch]$skipSetProjectRegion,
    [switch]$updateSecrets
)
$ErrorActionPreference="Stop"

$namedSecrets=Get-Content -Path "$PSScriptRoot/gc-env-secrets.json" -Raw | ConvertFrom-Json
$namedSecretValues=@{}

if($allSteps){
    $step=-1
}

$config=Get-Content -Path "$PSScriptRoot/gc-config.json" -Raw | ConvertFrom-Json


if(!$config.GC_PROJECT_ID){
    throw "config.GC_PROJECT_ID required"
}
if(!$config.GC_REGION){
    throw "config.GC_REGION required"
}
if(!$config.DATABASE_NAME){
    throw "config.DATABASE_NAME required"
}
if(!$config.DATABASE_SERVER_INSTANCE){
    throw "config.DATABASE_SERVER_INSTANCE required"
}
if(!$config.DATABASE_USERNAME){
    throw "config.DATABASE_USERNAME required"
}
if(!$config.SECRET_NAME){
    throw "config.SECRET_NAME required"
}

$dbTypes=@('postgres')
if(!$dbTypes.Contains($config.DATABASE_TYPE)){
    throw "Invalid dbType. Supported types = $dbTypes"
}



$project=$config.GC_PROJECT_ID
$region=$config.GC_REGION
$serviceEmail=''
$bucketName=$config.BUCKET_NAME
$dbPassword=''
$secretName=$config.SECRET_NAME;
$dbName=$config.DATABASE_NAME
$dbInst=$config.DATABASE_SERVER_INSTANCE
$dbUsername=$config.DATABASE_USERNAME
$recreateDbuser=$recreateDbuser;


$dir="$PSScriptRoot"


if(!$?){throw "mkdir failed"}

function GeneratePassword {

    param(
        [int]$length=40
    )

    $chars=( ([byte]65..[byte]90) + ([byte]97..[byte]122) + ([byte]48..[byte]57))

    $buf=[System.Byte[]]::CreateInstance([System.Byte],$length)
    $stream=[System.IO.File]::OpenRead('/dev/urandom')
    $stream.Read($buf,0,$length) | Out-Null

    for($i=0;$i -lt $length;$i++){
        $buf[$i]=$chars[$buf[$i]%$chars.Length]
    }

    return [System.Text.Encoding]::ASCII.GetString($buf)
}

function AddServiceAccountToGitHub{

}

function EnableApis{

    Write-Host "EnableApis" -ForegroundColor Cyan

    # enable required APIs
    gcloud services enable `
        appengine.googleapis.com `
        vpcaccess.googleapis.com `
        run.googleapis.com `
        sql-component.googleapis.com `
        sqladmin.googleapis.com `
        compute.googleapis.com `
        cloudbuild.googleapis.com `
        secretmanager.googleapis.com `
        artifactregistry.googleapis.com
    if(!$?){throw "gcloud enable APIs"}

}

function LoadServcieEmail{
    $script:serviceEmail=GetServiceInfo -prop serviceAccount
    if(!$? -or !$script:serviceEmail){
      throw "Unable to load default app engine service account"
    }
}

function ConfigureServiceAccount{

    Write-Host "ConfigureServiceAccount" -ForegroundColor Cyan

    LoadServcieEmail

    gcloud projects add-iam-policy-binding $project `
        --member serviceAccount:$script:serviceEmail `
        --role roles/cloudsql.client
    if(!$?){throw "Grant service account access to db failed"}


}

function GetNamedSecret{
    param(
        [string]$name=$(throw "-name required"),
        [switch]$autoCreate
    )

    $sn="$secretName--$name"

    $value=gcloud secrets versions access latest --secret=$sn | Join-String -Separator "`n"

    if($?){
        return $value
    }elseif($autoCreate){
        $value=Read-Host "Enter ($name) secret" -MaskInput

        gcloud secrets delete $sn --quiet | Out-Null
        try{
            $value | Out-File "$dir/.env-secrets" -NoNewline
            gcloud secrets create $sn --data-file "$dir/.env-secrets"
            if(!$?){throw "create ($sn) secret failed"}
        }finally{
            rm -rf "$dir/.env-secrets"
        }

        return $value
    }else{
        throw "Named secret ($sn) not found"
    }
}

function GatherNamedSecrets{
    foreach($n in $namedSecrets){
        $value=GetNamedSecret -name $n -autoCreate
        $namedSecretValues.$n=$value
    }
}

function AppendNamedSecrets{

    GatherNamedSecrets

    $content=gcloud secrets versions access latest --secret=$secretName | Join-String -Separator "`n"
    $content=$content.Trim().Split('##END_GEN##')[0].Trim()
    $content+="`n##END_GEN##`n`n##NAMED##`n"

    foreach($n in $namedSecrets){
        $content+="$n=$($namedSecretValues.$n)`n"
    }

    gcloud secrets delete $secretName --quiet | Out-Null
    try{
        $content | Out-File "$dir/.env-secrets"
        gcloud secrets create $secretName --data-file "$dir/.env-secrets"
        if(!$?){throw "create db user password secret failed"}
    }finally{
        rm -f "$dir/.env-secrets"
    }

}

function LoadSecrets{
    param(
        [switch]$print,
        [switch]$returnVars
    )
    $content=(gcloud secrets versions access latest --secret=$secretName | Join-String -Separator "`n").Split("`n")

    $vars=@{}

    foreach($line in $content){
        $parts=$line.Split('=',2)
        if(($parts[0] -ne '') -and !$parts[0].StartsWith('#')){
            $vars[$parts[0]]=$parts[1]
        }
    }

    $script:dbPassword=$vars.DATABASE_PASSWORD

    if($print){
        $vars
    }

    if($returnVars){
        return $vars
    }

}


function CreateSecrets{

    Write-Host "CreateSecrets" -ForegroundColor Cyan

    try{
        echo "DATABASE_PASSWORD=$(GeneratePassword -length 32)" > "$dir/.env-secrets"
        echo "APP_KEYS=$(GeneratePassword -length 32),$(GeneratePassword -length 32)" >> "$dir/.env-secrets"
        echo "JWT_SECRET=$(GeneratePassword -length 64)" >> "$dir/.env-secrets"
        echo "API_TOKEN_SALT=$(GeneratePassword -length 64)" >> "$dir/.env-secrets"
        echo "##END_GEN##" >> "$dir/.env-secrets"

        gcloud secrets delete $secretName --quiet | Out-Null

        gcloud secrets create $secretName --data-file "$dir/.env-secrets"
        if(!$?){throw "create db user password secret failed"}

        gcloud secrets add-iam-policy-binding $secretName `
            --member serviceAccount:$serviceEmail --role roles/secretmanager.secretAccessor
        if(!$?){throw "Grant service account access to password secret failed"}

    }finally{
        rm -f "$dir/.env-secrets"
    }

    LoadSecrets
}

function CreateDb{

    Write-Host "CreateDb" -ForegroundColor Cyan

    $ErrorActionPreference="SilentlyContinue"
    gcloud sql databases describe $dbName --instance $dbInst 2>&1 | Out-Null
    $result=$?
    $ErrorActionPreference="Stop"

    if(!$result){
        Write-Host "Creating db $($dbName)"
        gcloud sql databases create $dbName --instance $dbInst
        if(!$?){throw "create db failed"}
    }else{
        Write-Host "Db already exists $($dbName)"
    }
}

function CreateDbUser{

    Write-Host "CreateDbUser" -ForegroundColor Cyan

    $existing=gcloud sql users list --instance $dbInst --filter $dbUsername --format "value(name)"

    if($existing){
        if($recreateDbuser){
            gcloud sql users delete $dbUsername --instance $dbInst
            if(!$?){throw "delete db user failed"}
        }else{
            gcloud sql users set-password $dbUsername --instance $dbInst --password $dbPassword
            if(!$?){throw "update db user password failed"}
        }
    }else{
        gcloud sql users create $dbUsername --instance $dbInst --password $dbPassword
        if(!$?){throw "create db user failed"}
    }

}

function CreateBucket{

    Write-Host "CreateBucket" -ForegroundColor Cyan

    gsutil mb -l $region "gs://$bucketName"
    if(!$?){throw "gcloud create bucket failed"}

}

function ConfigureBucket{

    Write-Host "ConfigureBucket" -ForegroundColor Cyan

    gsutil cors set cors.json "gs://$bucketName"
    if(!$?){throw "Configure bucket CORS failed"}

    gsutil iam ch allUsers:objectViewer "gs://$bucketName"
    if(!$?){throw "Configure bucket permissions failed"}
    Write-Host "Bucket is now public"

    gsutil iam ch "serviceAccount:$($serviceEmail):objectAdmin" "gs://$bucketName"
    if(!$?){throw "Configure bucket permissions for service account failed"}
    Write-Host "$serviceEmail now has full access to bucket"

}

function GetServiceInfo{

    param(
        [string]$prop
    )

    $json=gcloud app describe --format=json | ConvertFrom-Json

    if(!$prop){
        return $json
    }elseif($prop -eq "url"){
        return $json.defaultHostname ? "https://$($json.defaultHostname)" : $(throw "status.defaultHostname not found")
    }elseif($json.$prop){
        return $json.$prop;
    }else{
        throw "Invalid prop - $prop"
    }
}

function InvokeUtilManage{

    param(
        [string[]]$commandArgs
    )

    $url=GetServiceInfo -prop url
    $vars=LoadSecrets -returnVars

    $JSON = @{
        "key" = $vars.MANAGE_SECRET_KEY
        "args" = $commandArgs
    } | ConvertTo-Json

    Invoke-RestMethod -Uri "$url/util-manage" -Method Post -Body $JSON -ContentType "application/json"

}


Push-Location $dir

try{

    if(!$noLogin){
        gcloud auth login
        if(!$?){throw "gcloud login failed"}
    }

    if(!$skipSetProjectRegion){
        gcloud config set project $project
        if(!$?){throw "set gcloud project failed"}

        gcloud config set run/region $region
        if(!$?){throw "set gcloud run region failed"}
    }

    if($step -eq -1 -or $step -eq 1){
        EnableApis
    }

    if($step -eq -1 -or $step -eq 2){
        ConfigureServiceAccount
    }else{
        LoadServcieEmail
    }

    if($step -eq -1 -or $step -eq 3){
        CreateSecrets
        AppendNamedSecrets
    }elseif($step -gt 3 -or $step -eq -2){
        LoadSecrets
    }

    if($updateSecrets){
      AppendNamedSecrets
    }

    if($step -eq -1 -or $step -eq 4){
        CreateDb
    }

    if($step -eq -1 -or $step -eq 5){
        CreateDbUser
    }

    if($step -eq -1 -or $step -eq 6){
        CreateBucket
    }

    if($step -eq -1 -or $step -eq 7){
        ConfigureBucket
    }

    if($getSecrets){
        LoadSecrets -print
    }

    if($getUrl){
        Write-Host $(GetServiceInfo -prop url)
    }

    if($getServiceInfo){
        GetServiceInfo
    }

}finally{
    Pop-Location
}

Write-Host "Complete" -ForegroundColor DarkGreen
