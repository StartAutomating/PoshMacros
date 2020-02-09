<#
.Synopsis
    The Macro for -Path based functions
.Description
    The process{} block for any macro that uses -Path.
.Notes
    Macros must be included inline, in order to get the correct invocation name.
#>

$callStack = @(Get-PSCallStack)

$isBeingAssigned = -not "$($callstack[-1].Position.Text)".Trim().StartsWith($MyInvocation.InvocationName)
$isBeingPiped = $MyInvocation.PipelinePosition -lt $MyInvocation.PipelineLength
$pathItem = Get-Item -ErrorAction SilentlyContinue -Path $path
$fileData =
    switch ($pathItem.Extension) {
        .json {
            [IO.File]::ReadAllText($pathItem.FullName) | ConvertFrom-Json
        }
        .psd1 {
            Import-LocalizedData -BaseDirectory $pathItem.Directory.FullName -FileName $pathItem.Name
        }
        {'.clixml', '.clix' -contains $_} {
            Import-Clixml -LiteralPath $pathItem.FullName
        }
        {$_ -like '*.xml' -or $_ -eq '.svg'} {
            [xml][IO.File]::ReadAllText($pathItem.FullName)
        }
        {'.csv', '.tsv' -contains $_} {
            if ($pathItem.Extension -eq '.tsv') {
                Import-Csv -LiteralPath $pathItem.FullName -Delimiter "`t"
            } else {
                Import-Csv -LiteralPath $pathItem.FullName
            }
        }
        {'.md', '.txt','.html','.htm' -contains $_} {
            [IO.File]::ReadAllText($pathItem.FullName)
        }

    }
    <#if ($pathItem.Extension -eq '.json')
    {

    }
    elseif ('.clixml', '.clix' -contains $pathItem.Extension)
    {

    }
    elseif
    {

    }
    elseif ($pathItem.Extension -eq '.psd1')
    {

    }
    elseif ()
    {

    }
    elseif ('.md', '.txt','.html','.htm' -contains $pathItem.Extension)
    {

    }#>
if ($isBeingAssigned -or $isBeingPiped) {
    if ($pathItem) {
        if ($fileData)
        {
            $fileData
        } else {
            $pathItem
        }
    } else {
        $path
    }
} else {
    if ($pathItem.PSIsContainer) {
        if ("$(Resolve-Path $path)" -eq "$(Resolve-Path $pwd)") {
            $path
        } else {
            Push-Location $path
        }

    } elseif ($pathItem) {
        if ($fileData)
        {
            $fileData
        } else {
            . $path @args
        }

    } else {
        $path
    }
}