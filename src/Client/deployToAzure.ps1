$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path   # repo root
$dockerfile = Join-Path $repoRoot 'src/Client/Dockerfile'

Push-Location $repoRoot

try {
    Write-Host "Working directory: $((Get-Location).Path)"

    docker build -t tf689registry.azurecr.io/client:latest -f $dockerfile $repoRoot;
    az acr login --name tf689registry;
    docker push tf689registry.azurecr.io/client:latest;
}
finally {
    Pop-Location
}

az containerapp update --name client --resource-group tf-cloudxp-sc_cloud_experience-analysis-689 --image tf689registry.azurecr.io/client:latest;
