function Export-Macro
{
    <#
    .Synopsis
        Exports Macros
    .Description
        Exports Macro definitions.

        Exported Macros are fully self contained and do not require the original module to run.
    .Notes
        By default, this will recreate each macro in it's own module, which will have PrivateData containing the Macro input.

        To export macros inline as a series of scripts and functions, use -Inline
    #>
    param(
    # The name of the macro.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [string[]]
    $Name,

    # The macro prefix.
    # The default prefix is an underscore _.
    [string]
    $Prefix = '_',

    # If set, will declare the functions inline, instead of declaring the macro module.
    [switch]
    $Inline
    )


    process {
        $macroSplat = @{} + $PSBoundParameters
        $macroSplat.Remove('Inline')
        $macroModules = Get-Macro @macroSplat

        foreach ($lm in $macroModules) {
            if ($Inline) {
                foreach ($cmd in $lm.ExportedCommands.Values) {
                    if ($cmd -is [Management.Automation.FunctionInfo])
                    {
                        "function $($cmd.Name) {
$($cmd.Definition)}"
                    }
                    elseif ($cmd -is [Management.Automation.AliasInfo])
                    {
                        "Set-Alias -Name '$($cmd.Name.Replace("'","''"))' -Value '$($cmd.Definition.Replace("'","''"))'"
                    }
                }
            } else {
                @"
`${$($lm.Name)} =
    New-Module -Name '$($lm.Name)' -ScriptBlock {
$($lm.Definition)
}
`${$($lm.Name)}.PrivateData = ConvertFrom-Json @'
$($lm.PrivateData | ConvertTo-Json -Depth 100)
'@
`${$($lm.Name)} | Import-Module -Global
"@
            }

        }
    }
}