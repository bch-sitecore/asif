<#
  .SYNOPSIS
    Generates a new random password.
  .PARAMETER Length
    The length of the new password.
  .PARAMETER SecureString
    Return the password as a secure string.
#>
Function NewRandomPassword {
  [CmdletBinding()]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
  Param(
    [Parameter(Position = 0)]
    [ValidateRange(1, 255)]
    [int]$Length = 8
    ,
    [Parameter()]
    [Alias("SecureString")]
    [switch]$AsSecureString
  )
  Begin {
    $numbers = 48..57
    $lcLetters = 97..122
    $ucLetter = 65..90
  }
  Process {
    $password = ([char[]]($numbers + $lcLetters + $ucLetter) | Sort-Object { Get-Random })[0..($Length-1)] -join ""
    If ($AsSecureString) {
      ConvertTo-SecureString $password -AsPlainText -Force
    } Else {
      $password
    }
  }
}