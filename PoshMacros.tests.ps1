#requires -Module Pester
#requires -Module PoshMacros
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingCmdletAliases", "", Justification="This tests aliases")]
param()
describe 'PoshMacros' {
    context 'Add-Macro' {
        it 'Can make a macro to a -Path' {
            Add-Macro -Name PSHome -Path $PSHOME
            (_PSHome) | should be $PSHOME
        }
        it 'Defines small functions that start with _' {
            Add-Macro -Name TwoPlusTwo -ScriptBlock { 2 + 2 }
            _TwoPlusTwo | should be 4
        }

        it 'Is easier to type _+ than Add-Macro' {
            _+ -Name OnePlusOne -ScriptBlock {1+1}
            _OnePlusOne | should be 2
        }

        it 'Can make an -Alias' {
            _+ -Name now -Alias Get-Date
            _now | Select-Object -ExpandProperty Date | should be ([DateTime]::Now.Date)
        }

        it 'Can make a Proxy -Command' {
            _+ -Name CurrentProcess -Command Get-Process -RemoveParameter * -DefaultParameter @{id='$pid'}
            _CurrentProcess | Select-Object -ExpandProperty id | should be $pid
        }

        it 'Can make a -uri macro' {
            _+ -Name GitRepos -Uri 'https://api.github.com/users/:username/repos?page={page}&per_page=$perPage' -DefaultParameter @{
                page = 1
                perpage = 50
            }

            $userName = 'StartAutomating'
            $gitRepos = _GitRepos -Username $userName -perPage 1
            $gitRepos.owner.login | should be $userName
        }
    }

    context 'Export-Macro' {
        it 'Can export macros' {
            _+ -Name now -Alias Get-Date
            Export-Macro -Name _n* | should belike '*Set-Alias*Get-Date*'
        }
        it 'Can export macros inline' {
            _+ -Name now -Alias Get-Date
            _+ -Name yesterday -ScriptBlock {[DateTime]::Now.AddDays(-1).Date}
            $exportedInline = Export-Macro -Inline -Name _now, _yesterday
            $exportedInline[0] | should belike '*Set-Alias*Get-Date*'
            $exportedInline[1] | should belike '*yesterday*{*DateTime*Now*-1*Date}*'
        }
    }


    context 'Get-Macro' {
        it 'Gets macros' {
            Get-Macro
        }
        it 'Can get a Macro by -Name' {
            _+ -Name now -Alias Get-Date
            Get-Macro -Name _now |
                Select-Object -ExpandProperty Name |
                should be _now
        }
        it 'Can get a Macro by wildcard' {
            _+ -Name now -Alias Get-Date
            Get-Macro -Name _n* |
                Select-Object -ExpandProperty Name |
                should belike _n*
        }
    }


    context 'Import-Macro' {
        it 'Can import macros' {
            Get-Module PoshMacros | Import-Macro

            (_PoshMacrosManifest).RootModule |
                should be PoshMacros.psm1
        }
    }
    context 'Remove-Macro' {
        it 'Removes Macros' {
            _+ -Name now -Alias Get-Date
            Remove-Macro -Name _now
            {_now} | should throw
        }
    }

}