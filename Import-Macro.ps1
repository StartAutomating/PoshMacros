function Import-Macro
{
    <#
    .Synopsis
        Imports Macros from a module
    .Description
        Imports Macros that are defined in a module.

    .Notes
        Modules can define Macros by adding a PoshMacros property to PrivateData, or to the module itself.

        The key of each Macro will be treated as it's name, and the value should be a hashtable of input parameters or a string.

        If the value is a string, the macro will be an alias.
        Otherwise, the macro will be defined using the input parameter hashtable.
    .Link
        Add-Macro
    .Link
        Export-Macro
    #>
    [OutputType()]
    param(
    # The name of the module
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string]
    $Name,

    # If set, will output the created macro module.
    [switch]
    $PassThru
    )

    begin {
        $loadedModules = @(if ($name) {Get-Module $Name}) + $MyInvocation.MyCommand.Module
        $myModuleName = $MyInvocation.MyCommand.Module.Name
        $myModuleRoot = $MyInvocation.MyCommand.Module | Split-Path
    }

    process {
        $theModule = foreach ($_ in $loadedModules) {
            if ($_.Name -eq $name) { $_; break }
        }

        if (-not $theModule) {
            Write-Error "Module $name is not imported"
            return
        }

        $macroData =
            if ($theModule.$myModuleName) {
                $theModule.$myModuleName
            } elseif ($theModule.PrivateData.$myModuleName) {
                $theModule.PrivateData.$myModuleName
            }

        if ($macroData -isnot [Collections.IDictionary]) {
            Write-Error "Module $name macros are not defined in a Dictionary"
            return
        }

        foreach ($kv in $macroData.GetEnumerator()) {
            $macroSplat = @{Name=$kv.Key}
            if ($kv.Value -is [string]) {
                $macroSplat.Alias = $kv.Value
            } else {
                if ($kv.Value -isnot [Collections.IDictionary]) {
                    Write-Error "Module $name macro $($kv.Key) must be a dictionary or string"
                    continue
                }
                $macroSplat += $kv.Value
                if ($macroSplat.Path -is [string] -and $macroSplat.Path -notmatch '^[\\/]') {
                    $macroSplat.Path = Join-Path $myModuleRoot $macroSplat.Path
                }
                if ($macroSplat.ScriptBlock -and $macroSplat.ScriptBlock -isnot [ScriptBlock]) {
                    $macroSplat.ScriptBlock = [ScriptBlock]::Create($macroSplat.ScriptBlock)
                    if (-not $macroSplat.ScriptBlock) { continue }
                }
            }
            if ($macroSplat.Count -gt 1) {
                Add-Macro @macroSplat -PassThru:$passThru
            }
        }
    }
}
