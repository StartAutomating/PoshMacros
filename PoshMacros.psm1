foreach ($file in Get-ChildItem $PSScriptRoot -Filter *-*.ps1) {
    . $file.Fullname
}

Set-Alias _+ Add-Macro
Set-Alias _? Get-Macro
Set-Alias _- Remove-Macro
Set-Alias _>> Export-Macro
Set-Alias _<< Import-Macro

# Parts are simple .ps1 files beneath a /Parts directory that can be used throughout the module.
$partsDirectory = $( # Because we want to be case-insensitive, and because it's fast
    foreach ($dir in [IO.Directory]::GetDirectories($psScriptRoot)) { # [IO.Directory]::GetDirectories()
        if ($dir -imatch "\$([IO.Path]::DirectorySeparatorChar)Parts$") { # and some Regex
            [IO.DirectoryInfo]$dir;break # to find our parts directory.
        }
    })

if ($partsDirectory) { # If we have parts directory
    foreach ($partFile in $partsDirectory.EnumerateFileSystemInfos()) { # enumerate all of the files.
        if ($partFile.Extension -eq '.ps1') { # If it's a PowerShell script,
            $partName = # get the name of the script.
                $partFile.Name.Substring(0, $partFile.Name.Length - $partFile.Extension.Length)
            $ExecutionContext.SessionState.PSVariable.Set( # and set a variable
                $partName, # named the script that points to the script (e.g. $foo = gcm .\Parts\foo.ps1)
                $ExecutionContext.SessionState.InvokeCommand.GetCommand($partFile.Fullname, 'ExternalScript').ScriptBlock
            )
        }
    }
}


$extensionModules =
    @(
        $myInvocation.MyCommand.ScriptBlock.Module
        . $GetExtensionModule $MyInvocation.MyCommand.ScriptBlock.Module.Name
    )

$extensionModules | Import-Macro


$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if ($script:macroList) {
        $script:macroList | Remove-Macro
<#        foreach ($macroItem in $script:macroList) {
            foreach ($exportedAlias in $macroItem.ExportedAliases.Values) {
                if (Test-Path "alias:$($exportedAlias.Name)") {
                    Remove-Item "alias:$($exportedAlias.Name)" -ErrorAction SilentlyContinue
                }
            }
            foreach ($exportedFunction in $macroItem.ExportedFunctions.Values) {
                if (Test-Path "function:$($exportedFunction.Name)") {
                    Remove-Item "function:$($exportedFunction.Name)" -ErrorAction SilentlyContinue
                }
            }
            if ($macroItem) {
                $macroItem | Remove-Module
            }
        }
  #>
    }
}

Export-ModuleMember -Function *-* -Alias *