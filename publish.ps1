param (
    [Parameter(Mandatory=$true,HelpMessage="Test or Production")]
    [ValidateSet("Test", "Production")]
    [string]
    $environment,
    [Parameter(Mandatory=$true,HelpMessage="The three number version for this release")]
    [string]
    $version,
    [Parameter(Mandatory=$true,HelpMessage="Get a personal access token from https://octopus-deploy.visualstudio.com/_details/security/tokens following the instructions https://www.visualstudio.com/en-us/integrate/extensions/publish/command-line")]
    [string]
    $accessToken
)

$ErrorActionPreference = "Stop"

$buildArtifactsPath = "$PSScriptRoot\build\Artifacts"

function UpdateTfxCli() {
    Write-Host "Updating tfx-cli..."
    & npm up -g tfx-cli
}

function PublishVSIX($vsixFile, $environment) {
    if ($environment -eq "Production") {
            Write-Output "Publishing $vsixFile to everyone (public extension)..."
            & tfx extension publish --vsix $vsixFile --token $accessToken --no-prompt --json | Write-Host
        } elseif ($environment -eq "Test") {
            Write-Output "Publishing $vsixFile as a private test extension..."
            & tfx extension publish --vsix $vsixFile --token $accessToken --shareWith "octopus-deploy" --no-prompt --json | Write-Host
        } else {
            Write-Error "The valid environments are 'Test' and 'Production'"
    }
}

function PublishAllExtensions($environment) {
    $environmentArtifactsPath = "$buildArtifactsPath\$environment"
    Write-Output "Looking for VSIX file(s) to publish in $environmentArtifactsPath..."

    $vsixFiles = Get-ChildItem $environmentArtifactsPath -Include "*.$version.vsix" -Recurse
    foreach ($vsixFile in $vsixFiles) {
        PublishVSIX $vsixFile $environment
    }
}


UpdateTfxCli
PublishAllExtensions $environment