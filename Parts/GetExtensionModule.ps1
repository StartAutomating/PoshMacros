<#
.Synopsis
    Gets Extension Modules
.Description
    Gets modules that can extend or plugin to other existing modules.

    A module is considered an extension module if:

    * It Requires this module name ($Module.RequiredModules -contains $ModuleName)
    * It Tags this module name  ($Module.PrivateData.PSdata.Tags -contains $ModuleName)
    * It has private data for this module ($Module.PrivateData.$ModuleName exists)
    * It has attached data for this module ($module.$ModuleName exists)
#>
param(
    # The name of the extensible module.
    [Parameter(Mandatory,Position=0)]
    [string]
    $ModuleName
)

$loadedModules = Get-Module

foreach ($module in $loadedModules) {
    $requiredModuleNames = @(foreach ($_ in $module.RequiredModules) {$_.Name })
    if ($requiredModuleNames -notcontains $ModuleName -and
        $module.PrivateData.PSData.Tags -notcontains $ModuleName -and
        -not $module.PrivateData.$ModuleName -and
        -not $Module.$ModuleName) { continue }
    $module
}