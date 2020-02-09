@{
    RootModule = 'PoshMacros.psm1'
    ModuleVersion = '0.1'
    AliasesToExport = '*'
    PrivateData = @{
        'PoshMacros' = @{
            'commands' = 'Get-Command'
            'PoshMacrosManifest' = @{
                Path = 'PoshMacros.psd1'
            }
        }
    }
    GUID = 'd6b450b2-8a06-4252-b647-783bc6481f0c'
    Author = 'James Brundage'
    CompanyName = 'Start-Automating'
    Copyright = '2020 Start-Automating'
    Description = 'Sleek and Simple PowerShell Macros'
}