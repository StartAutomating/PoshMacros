<#
.Synopsis
    Replaces URL segments and query strings with variables
.Description
    Replaces URL segments and query strings which contain variable names in brackets or curly braces with a PowerShell variable value.

    If no variable exists or it has a non-truthy value, then the segment will be omitted.
.Notes
    This is used as a delegate to [Regex]::Replace.  The match should contain the following groups:
    * Variable (the name of the variable)
    * Start ( the starting character of the match)
    * Query ( if matching a query string, this is the name of the variable)
#>
param([Parameter(Mandatory)][Text.RegularExpressions.Match]$match)
$var = $ExecutionContext.SessionState.PSVariable.Get($match.Groups['Variable'].ToString()) # Find the matching variable
if ($null -ne $var.Value) { # If it has a value, we're returning it.
    if ('?','&' -contains $match.Groups["Start"].Value) { # If the match was a query string segment,
        return $match.Groups['Start'].Value + # return <Start> +
            $match.Groups['Query'].Value +  # <Query>
            '=' + # an =
            $var.Value.ToString() # and then the value.
    } else { # Otherwise,
        return '/' + ($var.Value.ToString()) # return a leading slash and the value
    }
}
else # If there was no match
{
    if ($match.Groups['Start'].Value -ne '?') { # If we're the start of the query string,
        return '?' # keep the ? (there could be fixed query string values)
    } else { # otherwise,
        return '' # return a blank string.
    }
}