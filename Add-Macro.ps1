function Add-Macro
{
    <#
    .Synopsis
        Adds a macro
    .Description
        Adds a macro function.

        Macro functions are quick commands that tend to start with an _.  They can be a:

        * -Path (to a file or folder)
        * -URI (with optional replacement strings using curly brackets, braces or dollar signs)
        * -ScriptBlock
        * -Alias
        * -Command proxies (these can -RemoveParameter(s), have -OptionalParameter(s) and have -DefaultParameter(s))
    .Link
        Import-Macro
    .Link
        Export-Macro
    .Link
        Get-Macro
    .Link
        Remove-Macro
    #>
    param(
    # The name of the macro
    [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
    [string]
    $Name,

    # The name of the command macro will run.
    [Parameter(Mandatory,ParameterSetName='Alias',ValueFromPipelineByPropertyName)]
    [string]
    $Alias,

    # The script block the macro will run.  This will define the macro as a function
    [Parameter(Mandatory,ParameterSetName='ScriptBlock',Position=1,ValueFromPipelineByPropertyName)]
    [ScriptBlock]
    $ScriptBlock,

    <#
    The path used by the macro.

    When a path macro is being assigned, it will return the file or folder info.

    If a path macro points to a folder, and we are not in that folder, we will Push-Location to the path.

    If a path macro points to a folder, and we are already in the folder, we will echo the path.

    If a path macro points to a file, it will be invoked with any positional arguments.
    #>
    [Parameter(Mandatory,ParameterSetName='Path')]
    [string]
    $Path,

    # The URI used by the macro.
    # This may contain replacement parameters, using brackets or curly braces to denote the name of the parameter.
    [Parameter(Mandatory,ParameterSetName='Uri')]
    [ValidatePattern('^http(?:s)?\:')]
    [Alias('URL')]
    [string]
    $Uri,

    # If command the macro will wrap.
    # Command wrappers are different than Aliases, in that they can -RemoveParameter, -DefaultParameter, and can whitelist parameter names with -OptionalParameter
    [Parameter(Mandatory,ParameterSetName='ProxyCommand')]
    [string]
    $Command,

    # The list of parameters in the URI that are optional
    [Parameter(ParameterSetName='Uri')]
    [Parameter(ParameterSetName='ProxyCommand')]
    [Alias('OptionalParameters')]
    [string[]]
    $OptionalParameter,

    # The default parameter values.
    # Providing a parameter default will mark make parameters that were mandatory optional.
    [Parameter(ParameterSetName='Uri')]
    [Parameter(ParameterSetName='ProxyCommand')]
    [Alias('DefaultParameters','DefaultValue','DefaultValues')]
    [Collections.IDictionary]
    $DefaultParameter,

    # A list of parameters to remove from a Proxy Command.
    [Parameter(ParameterSetName='ProxyCommand')]
    [Alias('RemoveParameters')]
    [string[]]
    $RemoveParameter,

    # The prefix added to a macro that does not have it.
    # The default prefix is an underscore _.
    [string]
    $Prefix = '_',

    # If set, will not alter the name you pass in.
    [switch]
    $NoPrefix,

    # If set, will output the created macro module.
    [switch]
    $PassThru
    )

    begin {
        if (-not $script:macroList) {
            $script:macroList = [Collections.Generic.List[PSObject]]::new()
        }

$REST_Variable = [Regex]::new(@'
(?>                           # A variable can be in a URL segment or subdomain
    (?<Start>[/\.])           # Match the <Start>ing slash|dot ...
    (?<IsOptional>\?)?        # ... an optional ? (to indicate optional) ...
    (?:
        \{(?<Variable>\w+)\}| # ... A <Variable> name in {} OR
        \[(?<Variable>\w+)\]| #     A <Variable> name in [] OR
        \$(?<Variable>\w+)  | #     A $ followed by a <Variable> OR
        \:(?<Variable>\w+)    #     A : followed by a <Variable>
    )
|                             # OR it can be in a query parameter:
    (?<Start>[?&])            # Match The <Start>ing ? or & ...
    (?<Query>[\w\-]+)         # ... the <Query> parameter name ...
    =                         # ... an equals ...
    (?<IsOptional>\?)?        # ... an optional ? (to indicate optional) ...
    (?:
        \{(?<Variable>\w+)\}| # ... A <Variable> name in {} OR
        \[(?<Variable>\w+)\]| #     A <Variable> name in [] OR
        \$(?<Variable>\w+)  | #     A $ followed by a <Variable> OR
        \:(?<Variable>\w+)    #     A : followed by a <Variable>
    )
)
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')



    }

    process {
        if (-not $Name.StartsWith($Prefix, 'OrdinalIgnoreCase') -and -not $NoPrefix) {
            $name = "${Prefix}$name"
        }
        $moduleScript =
            if ($Alias)
            {
                "Set-Alias '$Name' '$($Alias)'; Export-ModuleMember -Alias '$Name'"
            }
            elseif ($ScriptBlock)
            {
                "function $Name {$ScriptBlock}"
            }
            elseif ($path)
            {
                "function $name {
begin {
    `$path = '$("$path".Replace("'", "''"))'
}
process {
${Path.Macro}
}
}"
            } elseif ($uri)
            {
                $variableNames =
                    foreach ($match in $REST_Variable.Matches($uri)) {
                        if ($match.Groups['IsOptional'].Value -eq '?') {
                            $OptionalParameter += $match.Groups['Variable'].Value
                        }
                        $match.Groups['Variable'].Value
                    }

                if ($DefaultParameter) {
                    $OptionalParameter += $DefaultParameter.Keys
                }

                $OptionalParameter = $OptionalParameter | Select-Object -Unique
                $position = 0

                $parameterDeclaration =
                    @(foreach ($v in $variableNames) {
                        @("[Parameter($(if ($OptionalParameter -notcontains $v) { "Mandatory,"})ParameterSetName='$uri',ValueFromPipelineByPropertyName,Position=$position)]"
                        "[string]"
                        "`$$v") -join [Environment]::NewLine
                        $position++
                    })

                $parameterDeclaration = $parameterDeclaration -join ",$([Environment]::NewLine)"
                $underylingCommand = 'Invoke-RestMethod'

                $underylingCommandMd =
                    [Management.Automation.CommandMetaData]$ExecutionContext.SessionState.InvokeCommand.GetCommand(
                        $underylingCommand, 'All'
                    )

                $null = $underylingCommandMd.Parameters.Remove('Uri'), $underylingCommandMd.Parameters.Remove('Url')
                $additionalParams = [Management.Automation.ProxyCommand]::GetParamBlock($underylingCommandMd)
                if ($additionalParams -and $additionalParams.contains('$')) {
                    $parameterDeclaration += ','
                    $parameterDeclaration += $additionalParams
                }
"
function $name {
[CmdletBinding(SupportsShouldProcess)]
param(
$parameterDeclaration
)
begin {
    `$url = '$("$uri".Replace("'", "''"))'
    `$underlyingCommand = `$executionContext.SessionState.InvokeCommand.GetCommand('$underylingCommand', 'All')
    `$underlyingParameters = @{}
    foreach (`$k in `$psBoundParameters.Keys) {
        if (`$underlyingCommand.Parameters.`$k) {
            `$underlyingParameters[`$k] = `$psBoundParameters[`$k]
        }
    }
    $(if ($DefaultParameter) {@"
    `$default = ConvertFrom-Json @'
$($defaultParameter | ConvertTo-Json -depth 100)
'@
    foreach (`$prop in `$default.psobject.properties) {
        if (-not `$psBoundParameters.ContainsKey(`$prop.Name)) {
            if (`$prop.Value -is [string] -and `$prop.Value.StartsWith('`$')) {
                `$executionContext.SessionState.PSVariable.Set(`$prop.Name, (
                    `$executionContext.SessionState.PSVariable.Get(`$prop.Value.TrimStart('$')).Value
                ))
            }
            elseif (`$prop.Value -is [ScriptBlock]) {
                `$executionContext.SessionState.PSVariable.Set(`$prop.Name, (& `$prop.Value))
            }
            else {
                `$executionContext.SessionState.PSVariable.Set(`$prop.Name, `$prop.Value)
            }
        }
    }
"@})
    `$urlReplaceRegex = [Regex]::new(@'
$REST_Variable
'@, 'IgnoreCase,IgnorePatternWhitespace')
    `$urlReplacer = {$ReplaceUrlVariable}

}
process {
    ${Url.Macro}
}
}
"

            }
            elseif ($Command)
            {
                $realCmd = $ExecutionContext.SessionState.InvokeCommand.GetCommand($command, 'All')
                if (-not $realCmd) { Write-Error "$Command not found"; return }
                $commandMetaData = [Management.Automation.CommandMetaData]$realCmd


                foreach ($rp in $RemoveParameter) {
                    $wasRemoved = $commandMetaData.Parameters.Remove($rp)
                    if (-not $wasRemoved) {
                        foreach ($parameterName in @($commandMetaData.Parameters.Keys)) {
                            if ($parameterName -like $rp -and $commandMetaData.Parameters.Remove($parameterName)) {
                                continue
                            }
                        }
                    }
                }

                $proxy =
                    if ($DefaultParameter) {
                        $proxy = [Management.Automation.ProxyCommand]::Create($commandMetaData)
                        $insertAt = $proxy.IndexOf(
                            '$scriptCmd = {& $wrappedCmd @PSBoundParameters }',[StringComparison]::OrdinalIgnoreCase)

                        $proxy.Insert($insertAt, @"
`$defaultJson = ConvertFrom-Json @'
$(ConvertTo-Json -Depth 100 -InputObject $DefaultParameter)
'@
foreach (`$prop in `$defaultJson.psobject.properties) {
    `$psBoundParameters[`$prop.Name] =
        if (`$prop.Value -is [string] -and `$prop.Value.StartsWith('`$')) {
            `$executionContext.SessionState.PSVariable.Get(`$prop.Value.TrimStart('$')).Value
        }
        elseif (`$prop.Value -is [ScriptBlock]) {
            & `$prop.Value
        }
        else {
            `$prop.Value
        }

}
"@ + ([Environment]::NewLine) + (' ' * 8))


                    } else {
                        [Management.Automation.ProxyCommand]::Create($commandMetaData)
                    }

                "function $name {
$proxy
}
"
            }

        if (-not $moduleScript) { return }
        $moduleExists = try { Get-Module -ErrorAction SilentlyContinue -Name $name } catch {  Write-Verbose ($_ |Out-String)}
        if ($moduleExists) {
            if ($script:macroList.Contains($moduleExists)) {
                $null = $script:macroList.Remove($moduleExists)
            }
            $moduleExists | Remove-Macro
        }
        $newModule = New-Module -Name $Name -ScriptBlock ([ScriptBlock]::Create($moduleScript))
        $newModule.PrivateData = [PSCustomObject]([Ordered]@{IsPoshMacro=$true} + $PSBoundParameters)
        $importedNewModule = $newModule | Import-Module -Global -PassThru
        if (-not $importedNewModule) { return }
        $importedNewModule.PSTypenames.add('Macro.Module')
        $script:macroList.Add($importedNewModule)

        if ($PassThru) {$importedNewModule }
    }
}