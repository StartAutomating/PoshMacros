
PoshMacros [0.1]
================
Sleek and Simple PowerShell Macros
----------------
### Commands
---------------
|  Verb|Noun  |
|-----:|:-----|
|   Add|-Macro|
|Export|-Macro|
|   Get|-Macro|
|Import|-Macro|
|Remove|-Macro|
---------------
PoshMacros is a module to help build useful command line macros in PowerShell

Macro functions are quick commands that tend to start with an _.  They can be a:

* -Path (to a file or folder)
* -Alias
* -Command proxies (these can -RemoveParameter(s), have -OptionalParameter(s) and have -DefaultParameter(s))
* -ScriptBlock
* -URI (with variables in enclosed in curly brackets or braces, or preceeded by a dollar sign or colon)

### Defining Macros

Macros are defined with Add-Macro.  Add-Macro is aliased to _+.

#### Path Macros

You can define path macros.  These work like named directories in certain advanced shells:
* Running the command pushes into the directory (if already there, it echoes).
* Assigning the command returns the [IO.DirectoryInfo]
~~~
# Define a path macro.  Running this will pop you into the PoshMacros directory.  Assigning it will return the [IO.DirectoryInfo].
Add-Macro -Name PoshMacrosRoot -Path (Get-Module PoshMacros | Split-Path)
~~~

ShowUI\New-Path Macros can also point to files.

If the file one of a few data file types, the data will be returned:
* .CSV | .TSV (using Import-CSV)
* .CLIXML | .CLIX (using Import-Clixml)
* .JSON (using ConvertFrom-JSON)
* .svg | *.xml (by casting to [xml])
* .psd1 (using Import-LocalizedData)
* .ps1 (as an ExternalScript)
* .md | .htm[l] | .txt
~~~
Add-Macro -Name PesterManifest -Path (Get-Module Pester | Split-Path | Join-Path -ChildName 'Pester.psd1')
~~~

#### Aliases, Proxy Commands, and Script Blocks

You can also define aliases.  These act just like any other alias in PowerShell:

~~~
Add-Macro -Name Now -Alias Get-Date
_Now
~~~

You can also define a proxy -Command.  If you provide a variable name as a default value, it will be expanded when the proxy runs.

~~~
Add-Macro -Name MyProcess -Command Get-Process -DefaultParameter @{Id='$pid'} -RemoveParameter *
_MyProcess
~~~

You can also define a macro as an arbitrary -ScriptBlock

~~~
Add-Macro -Name Today -ScriptBlock { [DateTime]::Now.Date }
_Today
~~~

#### URI Macros

You can define a macro for a -URI with embedded variables.  As the example below makes clear, you can include

~~~
Add-Macro -Name GitRepos -Uri 'https://api.github.com/users/:username/repos?page={page}&per_page=$perPage' -DefaultParameter @{
    page = 1
    perpage = 50
}

$StartAutomatingRepos = _GitRepos -UserName StartAutomating
~~~

Like path macros, URI macros work differently when assigned or piped (at least on Windows).

On Windows, running a URI macro without assigning or piping will open the URL in a browser.

URI macros wrap Invoke-RestMethod, and will carry over all parameters from Invoke-RestMethod except for the URI.

Providing any of these parameters will override

### Getting Macros

Each Macro is defined in a dynamic module, so you can get macros either by running Get-Macro or Get-Module -Name NameOfMacro

~~~
Get-Macro
~~~

~~~
Get-Macro -Prefix '_' # Gets all macros with the prefix _
~~~

### Exporting Macros

You can use Export-Macro to export a macro definition.  These can be re-imported at any time, independently of the PoshMacros 
module.

~~~
Add-Macro -Name MyProcess -Command Get-Process -DefaultParameter @{Id='$pid'} -RemoveParameter *

Export-Macro -Name MyProcess
~~~

By default, Export-Macro will declare the dynamic module and metadata associated with a macro.
You can also simply export function definitions and aliases with -Inline.

~~~
Add-Macro -Name Now -Alias Get-Date

Export-Macro -Name Now -Inline
~~~

### Importing Macros

Macros can be defined within a module by adding a .PoshMacros section of a module's PrivateData, or attaching a .PoshMacros 
property to a module.

To see an example of this in action, use:

~~~
Import-Macro -Name PoshMacros -PassThru
~~~

You can examine the PrivateData of PoshMacros with:

~~~
(_PoshMacrosManifest).PrivateData.PoshMacros
~~~

Any modules that have PoshMacros will be automatically imported when PoshMacros loads.


### Removing Macros

Remove-Macro will undeclare macros:

~~~
Add-Macro -Name Now -ScriptBlock { [DateTime]::Now }
_Now # it works
Remove-Macro -Name _Now
_Now # it doesn't
~~~



