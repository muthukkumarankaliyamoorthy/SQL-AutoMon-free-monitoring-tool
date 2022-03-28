$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'TargetVersion', 'Path', 'IncludeDatabaseSpecific', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$commandname Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $file = "c:\temp\myNotebook.ipynb"
    }
    AfterAll {
        $null = Remove-Item -Path $file -ErrorAction SilentlyContinue
    }
    Context "creates notebook" {
        It "should create a file" {
            $notebook = New-DbaDiagnosticAdsNotebook -TargetVersion 2017 -Path $file -IncludeDatabaseSpecific
            $notebook | Should Not BeNullOrEmpty
        }

        It "returns a file that includes specific phrases" {
            $results = New-DbaDiagnosticAdsNotebook -TargetVersion 2017 -Path $file -IncludeDatabaseSpecific
            $results | Should Not BeNullOrEmpty
            ($results | Get-Content) -contains "information for current instance"
        }
    }
}