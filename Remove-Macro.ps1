function Remove-Macro
{
    <#
    .Synopsis
        Removes Macros
    .Description
        Removes Macros by name.  To remove all macros, pipe Get-Macro | Remove-Macro
    .Link
        Add-Macro
    .Link
        Get-Macro
    .Link
        Import-Macro
    .Link
        Remove-Macro
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
    # The name of the macro.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string[]]
    $Name,

    # The macro prefix.
    # The default prefix is an underscore _.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Prefix = '_'
    )

    process {
        $macroModules = Get-Macro @PSBoundParameters

        foreach ($lm in $macroModules) {
            #region Unload Each Module

            # Because we want to be thorough, and modules don't always clean up their aliases,
            foreach ($exportedAlias in $lm.ExportedAliases.Values) {
                if (Test-Path "alias:$($exportedAlias.Name)") { # remove each alias,
                    Remove-Item "alias:$($exportedAlias.Name)" -ErrorAction SilentlyContinue
                }
            }
            foreach ($exportedFunction in $lm.ExportedFunctions.Values) {
                if (Test-Path "function:$($exportedFunction.Name)") { # then remove each function,
                    Remove-Item "function:$($exportedFunction.Name)" -ErrorAction SilentlyContinue
                }
            }
            # then unload the module
            $lm | Remove-Module -ErrorAction SilentlyContinue
            #endregion Unload Each Module
        }
    }
}
