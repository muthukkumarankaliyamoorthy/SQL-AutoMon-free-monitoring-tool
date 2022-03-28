$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [array]$params = ([Management.Automation.CommandMetaData]$ExecutionContext.SessionState.InvokeCommand.GetCommand($CommandName, 'Function')).Parameters.Keys
        [object[]]$knownParameters = 'DataType', 'RandomizerType', 'RandomizerSubType', 'Min', 'Max', 'Precision', 'CharacterString', 'Format', 'Separator', 'Symbol', 'Locale', 'Value', 'EnableException'
        It "Should only contain our specific parameters" {
            Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params | Should -BeNullOrEmpty
        }
    }
}

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Command returns values" {

        It "Should return a String type" {
            $result = Get-DbaRandomizedValue -DataType varchar

            $result.GetType().Name | Should Be "String"
        }

        It "Should return random string of max length 255" {
            $result = Get-DbaRandomizedValue -DataType varchar

            $result.Length | Should BeGreaterThan 1
        }

        It -Skip "Should return a random address zipcode" {
            $result = Get-DbaRandomizedValue -RandomizerSubType Zipcode -Format "#####"

            $result.Length | Should Be 5
        }
    }
}
