<#
.SYNOPSIS
  Creates .venv if missing, activates the virtual environment, updates pip, and installs requirements.
.DESCRIPTION
  Use dot-sourcing in PowerShell: . .\setup_env.ps1
#>

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPath = Join-Path $scriptRoot '../.venv'
$rootRequirementsPath = Join-Path $scriptRoot '../requirements.txt'
$requirementsPaths = @(
    $rootRequirementsPath,
    (Join-Path $scriptRoot '../api/requirements.txt'),
    (Join-Path $scriptRoot '../consumer/requirements.txt')
)

if (-not (Test-Path $rootRequirementsPath)) {
    Write-Error "requirements.txt not found in '$scriptRoot'."
    return
}

if (-not (Test-Path $venvPath)) {
    Write-Host 'Creating virtual environment .venv...'
    python -m venv $venvPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed with 'python'. Trying 'py'..."
        py -m venv $venvPath
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Failed to create virtual environment. Check your Python installation.'
        return
    }
}

$activateScript = Join-Path $venvPath 'Scripts\Activate.ps1'
if (-not (Test-Path $activateScript)) {
    Write-Error "Could not find activation script: $activateScript"
    return
}

Write-Host 'Activating virtual environment...'
. $activateScript

Write-Host 'Updating pip...'
python -m pip install --upgrade pip

foreach ($requirementsPath in $requirementsPaths) {
    if (-not (Test-Path $requirementsPath)) {
        Write-Host "Skipping missing requirements file: $requirementsPath"
        continue
    }

    Write-Host "Installing dependencies from $(Split-Path -Leaf $requirementsPath)..."
    python -m pip install -r $requirementsPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install dependencies from '$requirementsPath'."
        return
    }
}

Write-Host 'Setup complete. The venv is activated in this PowerShell session.'
