#Requires -Version 5.1
<#
.SYNOPSIS
    Launch Claude Code in Docker with automatic dependency management (Windows).

.DESCRIPTION
    Windows PowerShell equivalent of bin/run-claude-code (bash).
    Checks Docker, creates missing dependencies, pulls the latest image,
    and starts the Claude Code container.

.EXAMPLE
    .\bin\run-claude-code.ps1
    .\bin\run-claude-code.ps1 -HostNetwork
    .\bin\run-claude-code.ps1 -DryRun -NoPull
#>

[CmdletBinding(PositionalBinding=$false)]
param(
    [switch]$HostNetwork,
    [switch]$NoDockerSock,
    [switch]$NoPull,
    [int]$OAuthPort = 3334,
    [switch]$DryRun,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$RemainingArgs
)

# Handle bash-style --kebab-case arguments (PowerShell only supports single-dash)
if ($RemainingArgs) {
    $i = 0
    while ($i -lt $RemainingArgs.Count) {
        switch ($RemainingArgs[$i]) {
            '--help'          { $Help = $true }
            '--host-network'  { $HostNetwork = $true }
            '--no-docker-sock'{ $NoDockerSock = $true }
            '--no-pull'       { $NoPull = $true }
            '--dry-run'       { $DryRun = $true }
            '--oauth-port'    {
                $i++
                if ($i -ge $RemainingArgs.Count) {
                    Write-Output 'Error: --oauth-port requires a port number.'
                    exit 1
                }
                $OAuthPort = [int]$RemainingArgs[$i]
            }
            default {
                Write-Output "Unknown option: $($RemainingArgs[$i])"
                Write-Output 'Use -Help for usage information.'
                exit 1
            }
        }
        $i++
    }
}

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
$Image = if ($env:CLAUDE_TEST_IMAGE) { $env:CLAUDE_TEST_IMAGE } else { 'wraithrmm/claude-code-docker:latest' }
$UserHome = if ($env:CLAUDE_TEST_USERPROFILE) { $env:CLAUDE_TEST_USERPROFILE } else { $env:USERPROFILE }
$ClaudeJson = Join-Path $UserHome '.claude.json'
$ClaudeDir = Join-Path $UserHome '.claude'
$WorkspaceDir = 'C:\Users\claude-code'

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

function Show-Help {
    Write-Output @"
run-claude-code.ps1 - Launch Claude Code in Docker (Windows)

Usage: .\bin\run-claude-code.ps1 [OPTIONS]

Run this command from the root of any project you want to work on.
Your current working directory is mounted into the container as the project workspace.

Options:
  -HostNetwork         Use host networking instead of bridge (default: bridge)
    (alias: --host-network)
  -NoDockerSock        Don't mount the Docker socket into the container
    (alias: --no-docker-sock)
  -NoPull              Skip pulling the latest image before running
    (alias: --no-pull)
  -OAuthPort PORT      Host port for MCP OAuth callbacks (default: 3334)
    (alias: --oauth-port)
  -DryRun              Print the docker command without executing
    (alias: --dry-run)
  -Help                Show this help message
    (alias: --help)

Dependencies (auto-created if missing):
  %USERPROFILE%\.claude.json    Claude authentication/configuration
  %USERPROFILE%\.claude\        Claude persistent state directory
  C:\Users\claude-code\         Shared workspace directory

Examples:
  cd C:\path\to\your\project
  .\bin\run-claude-code.ps1                        # Run with default settings
  .\bin\run-claude-code.ps1 -HostNetwork           # Run with host networking
  .\bin\run-claude-code.ps1 -OAuthPort 4444        # Use alternate port
  .\bin\run-claude-code.ps1 -DryRun                # Show command without running
  .\bin\run-claude-code.ps1 --dry-run --no-pull    # Bash-style flags also work
"@
}

function Test-DockerInstalled {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $docker) {
        Write-Output 'Error: Docker is not installed.'
        Write-Output ''
        Write-Output 'Installation tips:'
        Write-Output '  Windows:'
        Write-Output '    1. Download Docker Desktop from https://www.docker.com/products/docker-desktop'
        Write-Output '    2. Run the installer and follow the prompts'
        Write-Output '    3. Restart your computer if prompted'
        exit 1
    }
}

function Test-DockerRunning {
    $null = & docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Output 'Error: Docker is installed but not running.'
        Write-Output ''
        Write-Output 'Please start Docker Desktop and try again.'
        exit 1
    }
}

function Ensure-ClaudeFile {
    param(
        [string]$FilePath,
        [string]$DefaultContent,
        [string]$Description
    )
    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        Write-Output "Creating ${Description}: $FilePath"
        $parentDir = Split-Path -Parent $FilePath
        if ($parentDir -and -not (Test-Path -LiteralPath $parentDir)) {
            $null = New-Item -ItemType Directory -Path $parentDir -Force
        }
        Set-Content -LiteralPath $FilePath -Value $DefaultContent -NoNewline
    }
}

function Ensure-ClaudeDirectory {
    param(
        [string]$DirPath,
        [string]$Description
    )
    if (-not (Test-Path -LiteralPath $DirPath -PathType Container)) {
        Write-Output "Creating ${Description}: $DirPath"
        try {
            $null = New-Item -ItemType Directory -Path $DirPath -Force -ErrorAction Stop
        }
        catch {
            Write-Output "Warning: Could not create $DirPath (permission denied)"
            Write-Output "You may need to create it manually with administrator privileges."
        }
    }
}

function Pull-Image {
    if ($NoPull) {
        Write-Output 'Skipping image pull (--no-pull)'
        return
    }

    Write-Output ''
    Write-Output "Checking for updates to $Image..."
    Write-Output '  (This may take a moment. Use -NoPull to skip this step)'
    Write-Output ''

    & docker pull $Image 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Output 'Image up to date.'
    }
    else {
        Write-Output 'Warning: Failed to pull latest image. Using cached version if available.'
    }
}

function Start-Container {
    $dockerArgs = @('run', '-it', '--rm')

    # Networking
    if ($HostNetwork) {
        $dockerArgs += '--network'
        $dockerArgs += 'host'
    }

    # MCP OAuth callback port
    $dockerArgs += '-p'
    $dockerArgs += "${OAuthPort}:3334"

    # Volume mounts
    $currentDir = (Get-Location).Path

    $dockerArgs += '-v'
    $dockerArgs += "${currentDir}:/workspace/project"

    $dockerArgs += '-v'
    $dockerArgs += "${ClaudeJson}:/root/.claude.json"

    $dockerArgs += '-v'
    $dockerArgs += "${ClaudeDir}:/root/.claude"

    if (-not $NoDockerSock) {
        $dockerArgs += '-v'
        $dockerArgs += '//./pipe/docker_engine:/var/run/docker.sock'
    }

    if ($script:WorkspaceAvailable) {
        $dockerArgs += '-v'
        $dockerArgs += "${WorkspaceDir}:${WorkspaceDir}"
    }

    # Git config mount
    $gitConfig = Join-Path $UserHome '.gitconfig'
    if (Test-Path -LiteralPath $gitConfig -PathType Leaf) {
        $dockerArgs += '-v'
        $dockerArgs += "${gitConfig}:/opt/user-gitconfig/.gitconfig:ro"
    }

    # Environment variables
    $dockerArgs += '-e'
    $dockerArgs += "HOST_PWD=$currentDir"

    $dockerArgs += '-e'
    $dockerArgs += "HOST_USER=$env:USERNAME"

    $dockerArgs += '-e'
    $dockerArgs += 'RUN_AS_ROOT=true'

    # Image and entrypoint
    $dockerArgs += $Image
    $dockerArgs += '/bin/bash'

    if ($DryRun) {
        if ($NoPull) {
            Write-Output "Would skip: docker pull $Image"
        }
        else {
            Write-Output "Would execute: docker pull $Image"
        }
        Write-Output ''
        Write-Output 'Would execute:'
        Write-Output ''
        Write-Output ("docker " + ($dockerArgs -join ' '))
        Write-Output ''
    }
    else {
        Write-Output 'Starting Claude Code container...'
        Write-Output ''
        Write-Output "  *** MCP OAuth callback port: ${OAuthPort} -> 3334 (container) ***"
        Write-Output "      Override with: -OAuthPort <port>"
        Write-Output ''
        & docker @dockerArgs
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# Dot-source guard: only run main logic when executed directly
if ($MyInvocation.InvocationName -ne '.') {
    if ($Help) {
        Show-Help
        exit 0
    }

    # Validate OAuthPort
    if ($OAuthPort -lt 1 -or $OAuthPort -gt 65535) {
        Write-Output "Error: Invalid port number: $OAuthPort (must be 1-65535)"
        exit 1
    }

    Write-Output 'Checking dependencies...'
    Test-DockerInstalled
    Test-DockerRunning

    # Ensure all dependencies exist
    Ensure-ClaudeFile -FilePath $ClaudeJson -DefaultContent '{}' -Description 'Claude config file'
    Ensure-ClaudeDirectory -DirPath $ClaudeDir -Description 'Claude state directory'

    # Workspace dir may need elevated permissions - don't fail if it can't be created
    $script:WorkspaceAvailable = $true
    if (-not (Test-Path -LiteralPath $WorkspaceDir -PathType Container)) {
        Ensure-ClaudeDirectory -DirPath $WorkspaceDir -Description 'Claude workspace directory'
        if (-not (Test-Path -LiteralPath $WorkspaceDir -PathType Container)) {
            $script:WorkspaceAvailable = $false
        }
    }

    Write-Output ''
    Pull-Image
    Write-Output ''
    Start-Container
}
