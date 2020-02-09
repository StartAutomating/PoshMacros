function Get-Macro
{
    <#
    .Synopsis
        Gets Macros
    .Description
        Gets the currently loaded Macros
    #>
    param(
    # The name of the macro.
    # If not provided, all macros will be returned.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string[]]
    $Name,

    # The macro prefix.
    # The default prefix is an underscore _.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Prefix = '_'
    )

    begin {
        $loadedModules = Get-Module
    }

    process {
        foreach ($lm in $loadedModules) {
            if ((-not $lm.Name) -or
                (-not $lm.Name.StartsWith($Prefix, 'OrdinalIgnoreCase'))) { continue }
            if ($Name -and
                $lm.Name -notcontains $Name) {

                $loadedModuleLikeName = $null

                foreach ($n in $name) {
                    if ($lm.Name -like $n -or $lm.Name -like "${prefix}$n") {
                        $loadedModuleLikeName = $lm
                        break
                    }
                }

                if (-not $loadedModuleLikeName) { continue}
            }
            if (-not $lm.PrivateData.IsPoshMacro) { continue }
            $lm
        }
    }
}