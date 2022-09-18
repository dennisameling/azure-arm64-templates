# Azure ARM64 Windows 11 templates

- Go to https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-templates-use-the-portal to learn how to create resources using ARM (Azure Resource Manager) templates.
- Use the template from `azure-arm-template.json` in this repo.
    - Tip: click "Edit parameters" after importing the template. Paste the example parameters from `azure-arm-template-example-parameters.json`.

## Included software and configuration

See `post-deployment-script.ps1` for more details.

- Git for Windows x64 (installed to `C:\Program Files\Git`)
- GitHub Actions Runner
- Windows Developer Mode enabled
- Windows Defender Exclusion for the entire `C:\` drive

## Logs and debugging of the post-deployment script

The [Custom Script Extension for Windows](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows#troubleshoot-and-support) docs are a good resource, but here's the most important info:

- Custom Script execution logs can be found in `C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension`
- The script itself (and downloaded files) can be found in `C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.*\Downloads`
- If the GitHub Actions Runner setup fails, check `C:\actions-runner\_diag` for its log files.
