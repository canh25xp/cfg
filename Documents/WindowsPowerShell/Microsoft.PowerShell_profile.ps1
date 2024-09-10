using namespace System.Management.Automation
using namespace System.Management.Automation.Language

# ==============================================
# SHELL INIT
# ==============================================

# Init enviroment variables
$Env:EDITOR = "nvim"
$Env:PAGER = "less"
$Env:NVIM_APPNAME = "nvim-kickstart"
$Env:VCPKG_ROOT = "C:\dev\vcpkg"

$Env:Path += ';C:\Program Files\Inkscape\bin'
$Env:Path += ";$Env:VCPKG_ROOT"

# Prompt
#function Prompt {
#    $prompt = Write-Prompt "$env:USERNAME@$env:COMPUTERNAME" -ForegroundColor ([ConsoleColor]::Green)
#    $prompt += ":$($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
#    $prompt
#}

# ==============================================
# SHELL EXTENSIONS
# ==============================================

# Init oh-my-posh outside of neovim
if ($null -eq $Env:NVIM) {
  # Load Oh-my-posh theme https://ohmyposh.dev/docs/themes
  oh-my-posh init pwsh --config "~/.config/oh-my-posh/catppuccin.omp.json" | Invoke-Expression
  # Using posh-git module for autocompletion
  $env:POSH_GIT_ENABLED = $true
}


# Init zoxide
Invoke-Expression (& { (zoxide init --cmd j powershell | Out-String) })
# (zoxide init powershell | Out-String) | Invoke-Expression # Same as above

# ==============================================
# SHELL ALIASES
# ==============================================

# Remove / Overide aliases
Remove-Item alias:diff -Force
Remove-Item alias:curl -Force
Remove-Item alias:ls -Force

# Bash like aliases
Set-Alias -Name su      -Value Start-AdminSession
Set-Alias -Name ff      -Value Find-File
Set-Alias -Name grep    -Value Find-String
Set-Alias -Name df      -Value Get-Volume
Set-Alias -Name which   -Value Show-Command
Set-Alias -Name ls      -Value Get-ChildItemPretty
Set-Alias -Name la      -Value Get-ChildItemPrettyAll
Set-Alias -Name ll      -Value Get-ChildItemPrettyLong
Set-Alias -Name du      -Value Get-DirectorySummary

# Helpful aliases
Set-Alias -Name wifi    -Value Get-Wifi
Set-Alias -Name meme    -Value Show-Meme # Maybe not so helpful :v
Set-Alias -Name wtf     -Value Get-Command
Set-Alias -Name path    -Value Get-Path
Set-Alias -Name doc     -Value Show-Documents
Set-Alias -Name pro     -Value Open-Profile
Set-Alias -Name word    -Value Open-WinWord
Set-Alias -Name cdx     -Value Open-ListFile
Set-Alias -Name cfg     -Value Get-Config

# Abbreviated aliases
Set-Alias -Name np      -Value notepad
Set-Alias -Name exp     -Value explorer
Set-Alias -Name vi      -Value nvim
Set-Alias -Name vim     -Value nvim
Set-Alias -Name edit    -Value $env:EDITOR
Set-Alias -Name lgit    -Value lazygit
Set-Alias -Name cz      -Value chezmoi
Set-Alias -Name gvim    -Value neovide
Set-Alias -Name linux   -Value Open-DefaultDistro

# ==============================================
# SHELL FUNCTIONS
# ==============================================

function Get-Config(){
  param()
    git --git-dir=$HOME/.cfg/ --work-tree=$HOME $args
}

function Open-Telegram {
  param ()
  & "$env:USERPROFILE\AppData\Roaming\Telegram Desktop\Telegram.exe"
}

function Open-DefaultDistro {
  wsl --cd ~
}

function Open-ListFile {
  param ()
  lf -print-last-dir $args | Set-Location
}

function Open-WinWord(){
	param()
	& "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE" $args
}

function Get-DirectorySummary($dir=".") {
    Get-ChildItem $dir |
        ForEach-Object { $f = $_ ;
            Get-ChildItem -r $_.FullName |
                Measure-Object -property length -sum |
                    Select-Object @{Name="Name";Expression={$f}},Sum}
}

function Start-GitBash {
    & "$env:PROGRAMFILES\Git\usr\bin\bash.exe" -i -l
}

function Open-Profile{
	Set-Location $HOME\Documents\PowerShell
}

function Get-Path {
    $env:PATH -split ';'
}

function Start-AdminSession {
    <#
    .SYNOPSIS
        Starts a new PowerShell session with elevated rights. Alias: su
    #>
    Start-Process -FilePath "wt" -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command &{Set-Location $PWD}"
}

function Get-Wifi {
    param ()
    netsh wlan show profile key=clear $args
}

function Show-Meme {
    <#
    .SYNOPSIS
        Displays meme in the console. Alias: meme
    #>
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("nvim", "thisisfine", "man")]
        [string]$Name = "thisisfine"
    )
    Invoke-Expression (Get-Content "~\Pictures\Arts\$Name.ps1" -Raw)
}

function Get-ChildItemPretty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = $PWD
    )
    eza --icons -1 --hyperlink --time-style relative $Path
}

function Get-ChildItemPrettyAll {
    eza -a --icons -1 --hyperlink --time-style relative $args
}

function Get-ChildItemPrettyLong {
    eza -a -l --icons --hyperlink --time-style relative $args
}

function Get-ChildItemList {
    <#
    .SYNOPSIS
        ls with fancy icons
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = $PWD
    )
    Get-ChildItem $Path | Format-TerminalIcons
}

function Show-Command {
    <#
    .SYNOPSIS
        Displays the definition of a command. Alias: which
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )
    Write-Verbose "Showing definition of '$Name'"
    Get-Command $Name | Select-Object -ExpandProperty Definition
}

function Find-File {
    <#
    .SYNOPSIS
        Finds a file in the current directory and all subdirectories. Alias: ff
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory = $true, Position = 0)]
        [string]$SearchTerm
    )

    Write-Verbose "Searching for '$SearchTerm' in current directory and subdirectories"
    $result = Get-ChildItem -Recurse -Filter "*$SearchTerm*" -ErrorAction SilentlyContinue

    Write-Verbose "Outputting results to table"
    $result | Format-Table -AutoSize
}


function Find-String {
    <#
    .SYNOPSIS
        Searches for a string in a file or directory. Alias: grep
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SearchTerm,
        [Parameter(ValueFromPipeline, Mandatory = $false, Position = 1)]
        [string]$Directory,
        [Parameter(Mandatory = $false)]
        [switch]$Recurse
    )

    Write-Verbose "Searching for '$SearchTerm' in '$Directory'"
    if ($Directory) {
        if ($Recurse) {
            Write-Verbose "Searching for '$SearchTerm' in '$Directory' and subdirectories"
            Get-ChildItem -Recurse $Directory | Select-String $SearchTerm
            return
        }

        Write-Verbose "Searching for '$SearchTerm' in '$Directory'"
        Get-ChildItem $Directory | Select-String $SearchTerm
        return
    }

    if ($Recurse) {
        Write-Verbose "Searching for '$SearchTerm' in current directory and subdirectories"
        Get-ChildItem -Recurse | Select-String $SearchTerm
        return
    }

    Write-Verbose "Searching for '$SearchTerm' in current directory"
    Get-ChildItem | Select-String $SearchTerm
}

function Get-CmdletAlias ($cmdletname) {
    Get-Alias |
        Where-Object -FilterScript {$_.Definition -like "$cmdletname"} |
            Format-Table -Property Definition, Name -AutoSize
}

function Show-Documents {
    glow $env:USERPROFILE\Documents\CheatSheets\
}

# ==============================================
# PSREADLINE SETTINGS
# ==============================================

# Commands default parameter
$PSDefaultParameterValues.Add('Format-*:AutoSize', $true)
$PSDefaultParameterValues.Add('Format-*:Wrap', $true)
$PSDefaultParameterValues.Add('Receive-Job:Keep', $true)
$PSDefaultParameterValues.Add('Get-Command:All', $true)

# Ignore some of the commands (not add to history)
Set-PSReadLineOption -AddToHistoryHandler {
    Param([string]$line)
    # History ignored git commands
    # if ($line -match "^git") {
    #     return $false
    # }
    # History ignored commands
    if (@("exit", "dir", "ls", "la", "pwd", "cd ..", "cls", "clear", "exp .", "pwsh").Contains($line.ToLowerInvariant())) {
        return $false
    }
    return $true
}

# Save history in home directory
# Set-PSReadLineOption -HistorySavePath "~\.history.txt"

# ==============================================
# KEY BINDINGS
# ==============================================

# Kill whole line
Set-PSReadLineKeyHandler -Chord Alt+l -Function RevertLine

# Change directory interactively
Set-PSReadLineKeyHandler -Chord Ctrl+o -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cdi")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}


# CaptureScreen is good for blog posts or email showing a transaction
# of what you did when asking for help or demonstrating a technique.
Set-PSReadLineKeyHandler -Chord 'Ctrl+k,Ctrl+c' -Function CaptureScreen

Set-PSReadLineKeyHandler -Chord "Ctrl+h" `
                         -BriefDescription GetHelp `
                         -LongDescription "Get help about the current command" `
                         -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::BeginningOfLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("help ")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

#region Smart Insert/Delete

# The next four key handlers are designed to make entering matched quotes
# parens, and braces a nicer experience.  I'd like to include functions
# in the module that do this, but this implementation still isn't as smart
# as ReSharper, so I'm just providing it as a sample.

Set-PSReadLineKeyHandler -Key '"',"'" `
                         -BriefDescription SmartInsertQuote `
                         -LongDescription "Insert paired quotes if not already on a quote" `
                         -ScriptBlock {
    param($key, $arg)

    $quote = $key.KeyChar

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # If text is selected, just quote it without any smarts
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        return
    }

    $ast = $null
    $tokens = $null
    $parseErrors = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

    function FindToken
    {
        param($tokens, $cursor)

        foreach ($token in $tokens)
        {
            if ($cursor -lt $token.Extent.StartOffset) { continue }
            if ($cursor -lt $token.Extent.EndOffset) {
                $result = $token
                $token = $token -as [StringExpandableToken]
                if ($token) {
                    $nested = FindToken $token.NestedTokens $cursor
                    if ($nested) { $result = $nested }
                }

                return $result
            }
        }
        return $null
    }

    $token = FindToken $tokens $cursor

    # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
    if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
        # If we're at the start of the string, assume we're inserting a new string
        if ($token.Extent.StartOffset -eq $cursor) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }

        # If we're at the end of the string, move over the closing quote if present.
        if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }
    }

    if ($null -eq $token -or
        $token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
        if ($line[0..$cursor].Where{$_ -eq $quote}.Count % 2 -eq 1) {
            # Odd number of quotes before the cursor, insert a single quote
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
        }
        else {
            # Insert matching quotes, move cursor to be in between the quotes
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
        }
        return
    }

    # If cursor is at the start of a token, enclose it in quotes.
    if ($token.Extent.StartOffset -eq $cursor) {
        if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
            $token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
            $end = $token.Extent.EndOffset
            $len = $end - $cursor
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
            return
        }
    }

    # We failed to be smart, so just insert a single quote
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

Set-PSReadLineKeyHandler -Key '(','{','[' `
                         -BriefDescription InsertPairedBraces `
                         -LongDescription "Insert matching braces" `
                         -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar)
    {
        <#case#> '(' { [char]')'; break }
        <#case#> '{' { [char]'}'; break }
        <#case#> '[' { [char]']'; break }
    }

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
    if ($selectionStart -ne -1)
    {
      # Text is selected, wrap it in brackets
      [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else {
      # No text is selected, insert a pair
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
      [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

Set-PSReadLineKeyHandler -Key ')',']','}' `
                         -BriefDescription SmartCloseBraces `
                         -LongDescription "Insert closing brace or skip" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
    }
}

Set-PSReadLineKeyHandler -Key Backspace `
                         -BriefDescription SmartBackspace `
                         -LongDescription "Delete previous character or matching quotes/parens/braces" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0)
    {
        $toMatch = $null
        if ($cursor -lt $line.Length)
        {
            switch ($line[$cursor])
            {
                <#case#> '"' { $toMatch = '"'; break }
                <#case#> "'" { $toMatch = "'"; break }
                <#case#> ')' { $toMatch = '('; break }
                <#case#> ']' { $toMatch = '['; break }
                <#case#> '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        }
        else
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
}

#endregion Smart Insert/Delete

# Sometimes you enter a command but realize you forgot to do something else first.
# This binding will let you save that command in the history so you can recall it,
# but it doesn't actually execute.  It also clears the line with RevertLine so the
# undo stack is reset - though redo will still reconstruct the command line.
Set-PSReadLineKeyHandler -Key Alt+w `
                         -BriefDescription SaveInHistory `
                         -LongDescription "Save current line in history but do not execute" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

# Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+V `
                         -BriefDescription PasteAsHereString `
                         -LongDescription "Paste the clipboard text as a here string" `
                         -ScriptBlock {
    param($key, $arg)

    Add-Type -Assembly PresentationCore
    if ([System.Windows.Clipboard]::ContainsText())
    {
        # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
        $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n","`n").TrimEnd()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    }
}

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadLineKeyHandler -Key 'Alt+(' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

# Each time you press Alt+', this key handler will change the token
# under or before the cursor.  It will cycle through single quotes, double quotes, or
# no quotes each time it is invoked.
Set-PSReadLineKeyHandler -Key "Alt+'" `
                         -BriefDescription ToggleQuoteArgument `
                         -LongDescription "Toggle quotes on the argument under the cursor" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $tokenToChange = $null
    foreach ($token in $tokens)
    {
        $extent = $token.Extent
        if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor)
        {
            $tokenToChange = $token

            # If the cursor is at the end (it's really 1 past the end) of the previous token,
            # we only want to change the previous token if there is no token under the cursor
            if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext())
            {
                $nextToken = $foreach.Current
                if ($nextToken.Extent.StartOffset -eq $cursor)
                {
                    $tokenToChange = $nextToken
                }
            }
            break
        }
    }

    if ($tokenToChange -ne $null)
    {
        $extent = $tokenToChange.Extent
        $tokenText = $extent.Text
        if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"')
        {
            # Switch to no quotes
            $replacement = $tokenText.Substring(1, $tokenText.Length - 2)
        }
        elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'")
        {
            # Switch to double quotes
            $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
        }
        else
        {
            # Add single quotes
            $replacement = "'" + $tokenText + "'"
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
            $extent.StartOffset,
            $tokenText.Length,
            $replacement)
    }
}

# This example will replace any aliases on the command line with the resolved commands.
Set-PSReadLineKeyHandler -Key "Alt+%" `
                         -BriefDescription ExpandAliases `
                         -LongDescription "Replace all aliases with the full command" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $startAdjustment = 0
    foreach ($token in $tokens)
    {
        if ($token.TokenFlags -band [TokenFlags]::CommandName)
        {
            $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
            if ($alias -ne $null)
            {
                $resolvedCommand = $alias.ResolvedCommandName
                if ($resolvedCommand -ne $null)
                {
                    $extent = $token.Extent
                    $length = $extent.EndOffset - $extent.StartOffset
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                        $extent.StartOffset + $startAdjustment,
                        $length,
                        $resolvedCommand)

                    # Our copy of the tokens won't have been updated, so we need to
                    # adjust by the difference in length
                    $startAdjustment += ($resolvedCommand.Length - $length)
                }
            }
        }
    }
}


# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
Set-PSReadLineKeyHandler -Key RightArrow `
                         -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
                         -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -lt $line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
    }
}
