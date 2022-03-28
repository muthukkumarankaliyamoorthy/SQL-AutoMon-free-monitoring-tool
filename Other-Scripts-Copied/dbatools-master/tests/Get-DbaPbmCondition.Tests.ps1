$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Condition', 'InputObject', 'IncludeSystemObject', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}
<#
    Integration test should appear below and are custom to the command you are writing.
    Read https://github.com/dataplat/dbatools/blob/development/contributing.md#tests
    for more guidence.
#>

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $conditionName = "dbatoolsCondition_$(get-random)"
        $conditionQuery = "
            Declare @condition_id int
            EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'$conditionName', @description=N'', @facet=N'Database', @expression=N'<Operator>
            <TypeClass>Bool</TypeClass>
            <OpType>EQ</OpType>
            <Count>2</Count>
            <Attribute>
                <TypeClass>String</TypeClass>
                <Name>Name</Name>
            </Attribute>
            <Constant>
                <TypeClass>String</TypeClass>
                <ObjType>System.String</ObjType>
                <Value>test</Value>
            </Constant>
            </Operator>', @is_name_condition=1, @obj_name=N'test', @condition_id=@condition_id OUTPUT
            Select @condition_id as conditionId"

        $server = Connect-DbaInstance -SqlInstance $script:instance2
        $conditionId = $server.Query($conditionQuery) | Select-Object -expand conditionId
    }
    AfterAll {
        $dropQuery = "EXEC msdb.dbo.sp_syspolicy_delete_condition @condition_id=$conditionId"
        $null = $server.Query($dropQuery)
    }

    Context "Command returns results" {
        $results = Get-DbaPbmCondition -SqlInstance $script:instance2
        It "Should get results" {
            $results | Should Not Be $null
        }

        It "Should have name property '$conditionName'" {
            $results.Name | Should Be $conditionName
        }
    }

    Context "Command actually works by condition name" {
        $results = Get-DbaPbmCondition -SqlInstance $script:instance2 -Condition $conditionName
        It "Should get results" {
            $results | Should Not Be $null
        }

        It "Should have name property '$conditionName'" {
            $results.Name | Should Be $conditionName
        }
    }
}