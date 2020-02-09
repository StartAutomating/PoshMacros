<#
.Synopsis
    The Macro for -URL based functions
.Description
    The process{} block for any macro that uses -URL.
.Notes
    Macros must be included inline, in order to get the correct invocation name.
#>

$callStack = @(Get-PSCallStack)
$isBeingAssigned = -not "$($callstack[-1].Position.Text)".Trim().StartsWith($MyInvocation.InvocationName)
$isBeingPiped = $MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength

Write-Verbose "Original URL: $url"
$url = $urlReplaceRegex.Replace("$url", $urlReplacer)
Write-Verbose "Replaced URL: $url"
$realUri = [uri]$url

if ($WhatIfPreference) { return $url }
if (-not $realUri) { return }
if (-not $isBeingAssigned -and -not $isBeingPiped -and -not $underlyingParameters.Count -and
    ($psVersionTable.Platform -eq 'Windows' -or -not $psVersionTable.PlatForm)) {
    if (-not $args) {
        Start-Process -FilePath $realUri
    } else {
        Start-Process -FilePath ("$realUri".TrimEnd('?') + '?' + $(@($args -join '&')))
    }
} else {

    Invoke-RestMethod -Uri $realUri @underlyingParameters
}
