param (
    # GitHub Actions Runner registration token. Note that these tokens are only valid for one hour after creation, so we always expect the user to provide one.
    # https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners
    [Parameter(Mandatory=$true)]
    [string]$GitHubActionsRunnerToken,

    # GitHub Actions Runner repository. E.g. "https://github.com/MY_ORG" (org-level) or "https://github.com/MY_ORG/MY_REPO" or (repo-level_
    # https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners
    [Parameter(Mandatory=$true)]
    [string]$GitHubActionsRunnerRepo
)

Write-Output "Starting post-deployment script."

# =================================
# TOOL VERSIONS AND OTHER VARIABLES
# =================================

$GitForWindowsVersion = "2.37.3"
# Note that the GitHub Actions Runner auto-updates itself by default, but do try to reference a relatively new version here.
$GitHubActionsRunnerVersion = "2.296.2"
$GithubActionsRunnerHash = "96d03cf54dbfe2e016bd2aa5a08ffbd2a803b1899b0ae3eedf4bd18e370f14a4"
$GithubActionsRunnerLabels = "self-hosted,Windows,ARM64"
# Keep this path short to prevent Long Path issues
$GitHubActionsRunnerPath = "C:\actions-runner"

# ======================
# WINDOWS DEVELOPER MODE
# ======================

# Needed for symlink support
Write-Output "Enabling Windows Developer Mode..."
Start-Process -Wait "reg" 'add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"'
Write-Output "Enabled Windows developer mode."

# =============================
# MICROSOFT DEFENDER EXCLUSIONS
# =============================

Write-Output "Adding Microsoft Defender Exclusions..."
Add-MpPreference -ExclusionPath "C:\"
Write-Output "Finished adding Microsoft Defender Exclusions."

# ======================
# GIT FOR WINDOWS
# ======================

Write-Output "Downloading Git for Windows..."
$GitForWindowsOutputFile = "./git-for-windows-installer.exe"
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/git-for-windows/git/releases/download/v${GitForWindowsVersion}.windows.1/Git-${GitForWindowsVersion}-64-bit.exe" -OutFile $GitForWindowsOutputFile
$ProgressPreference = 'Continue'

Write-Output "Installing Git for Windows..."
@"
[Setup]
Lang=default
Dir=C:\Program Files\Git
Group=Git
NoIcons=0
SetupType=default
Components=gitlfs,windowsterminal
Tasks=
EditorOption=VIM
CustomEditorPath=
DefaultBranchOption= 
PathOption=Cmd
SSHOption=OpenSSH
TortoiseOption=false
CURLOption=WinSSL
CRLFOption=CRLFAlways
BashTerminalOption=ConHost
GitPullBehaviorOption=FFOnly
UseCredentialManager=Core
PerformanceTweaksFSCache=Enabled
EnableSymlinks=Disabled
EnablePseudoConsoleSupport=Disabled
EnableFSMonitor=Disabled
"@ | Out-File -FilePath "./git-installer-config.inf"

Start-Process -Wait $GitForWindowsOutputFile '/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF="./git-installer-config.inf"'

Write-Output "Finished installing Git for Windows."

# ======================
# GITHUB ACTIONS RUNNER
# ======================

Write-Output "Downloading GitHub Actions runner..."

mkdir $GitHubActionsRunnerPath | Out-Null
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -UseBasicParsing -Uri https://github.com/actions/runner/releases/download/v${GitHubActionsRunnerVersion}/actions-runner-win-x64-${GitHubActionsRunnerVersion}.zip -OutFile ${GitHubActionsRunnerPath}\actions-runner-win-x64-${GitHubActionsRunnerVersion}.zip
$ProgressPreference = 'Continue'
if((Get-FileHash -Path ${GitHubActionsRunnerPath}\actions-runner-win-x64-${GitHubActionsRunnerVersion}.zip -Algorithm SHA256).Hash.ToUpper() -ne $GithubActionsRunnerHash.ToUpper()){ throw 'Computed checksum did not match' }

Write-Output "Installing GitHub Actions runner ${GitHubActionsRunnerVersion} as a Windows service with labels ${GithubActionsRunnerLabels}..."

Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("${GitHubActionsRunnerPath}\actions-runner-win-x64-${GitHubActionsRunnerVersion}.zip", $GitHubActionsRunnerPath)
cmd.exe /c "${GitHubActionsRunnerPath}\config.cmd" --unattended --runasservice --labels ${GithubActionsRunnerLabels} --url ${GitHubActionsRunnerRepo} --token ${GitHubActionsRunnerToken}

# Ensure that the service was created. If not, exit with error code.
$MatchedServices = Get-Service -Name "actions.runner.*"
if ($MatchedServices.count -eq 0) {
    Write-Error "GitHub Actions service not found (should start with actions.runner). Check the logs in ${GitHubActionsRunnerPath}\_diag for more details."
    exit 1
}
Write-Output "Finished installing GitHub Actions runner."
