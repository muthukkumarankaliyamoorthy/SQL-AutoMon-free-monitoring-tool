$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Reading db statuses" {
        BeforeAll {
            $server = Connect-DbaInstance -SqlInstance $script:instance2
            $db1 = "dbatoolsci_dbstate_online"
            $db2 = "dbatoolsci_dbstate_offline"
            $db3 = "dbatoolsci_dbstate_emergency"
            $db4 = "dbatoolsci_dbstate_single"
            $db5 = "dbatoolsci_dbstate_restricted"
            $db6 = "dbatoolsci_dbstate_multi"
            $db7 = "dbatoolsci_dbstate_rw"
            $db8 = "dbatoolsci_dbstate_ro"
            Get-DbaDatabase -SqlInstance $script:instance2 -Database $db1, $db2, $db3, $db4, $db5, $db6, $db7, $db8 | Remove-DbaDatabase -Confirm:$false
            $server.Query("CREATE DATABASE $db1")
            $server.Query("CREATE DATABASE $db2; ALTER DATABASE $db2 SET OFFLINE WITH ROLLBACK IMMEDIATE")
            $server.Query("CREATE DATABASE $db3; ALTER DATABASE $db3 SET EMERGENCY WITH ROLLBACK IMMEDIATE")
            $server.Query("CREATE DATABASE $db4; ALTER DATABASE $db4 SET SINGLE_USER WITH ROLLBACK IMMEDIATE")
            $server.Query("CREATE DATABASE $db5; ALTER DATABASE $db5 SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE")
            $server.Query("CREATE DATABASE $db6; ALTER DATABASE $db6 SET MULTI_USER WITH ROLLBACK IMMEDIATE")
            $server.Query("CREATE DATABASE $db7; ALTER DATABASE $db7 SET READ_WRITE WITH ROLLBACK IMMEDIATE")
            $server.Query("CREATE DATABASE $db8; ALTER DATABASE $db8 SET READ_ONLY WITH ROLLBACK IMMEDIATE")
            $setupright = $true
            $needed_ = $server.Query("select name from sys.databases")
            $needed = $needed_ | Where-Object name -in $db1, $db2, $db3, $db4, $db5, $db6, $db7, $db8
            if ($needed.Count -ne 8) {
                $setupright = $false
                It "has failed setup" {
                    Set-TestInconclusive -Message "Setup failed"
                }
            }
        }
        AfterAll {
            $null = Set-DbaDbState -Sqlinstance $script:instance2 -Database $db2, $db3, $db4, $db5, $db7 -Online -ReadWrite -MultiUser -Force
            Remove-DbaDatabase -Confirm:$false -SqlInstance $script:instance2 -Database $db1, $db2, $db3, $db4, $db5, $db6, $db7, $db8
        }
        if ($setupright) {
            # just to have a correct report on how much time BeforeAll takes
            It "Waits for BeforeAll to finish" {
                $true | Should Be $true
            }
            It "Honors the Database parameter" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db2
                $result.DatabaseName | Should be $db2
                $results = Get-DbaDbState -SqlInstance $script:instance2 -Database $db1, $db2
                $results.Count | Should be 2
            }
            It "Honors the ExcludeDatabase parameter" {
                $alldbs_ = $server.Query("select name from sys.databases")
                $alldbs = ($alldbs_ | Where-Object Name -notin @($db1, $db2, $db3, $db4, $db5, $db6, $db7, $db8)).name
                $results = Get-DbaDbState -SqlInstance $script:instance2 -ExcludeDatabase $alldbs
                $comparison = Compare-Object -ReferenceObject ($results.DatabaseName) -DifferenceObject (@($db1, $db2, $db3, $db4, $db5, $db6, $db7, $db8))
                $comparison.Count | Should Be 0
            }
            It "Identifies online database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db1
                $result.DatabaseName | Should Be $db1
                $result.Status | Should Be "ONLINE"
            }
            It "Identifies offline database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db2
                $result.DatabaseName | Should Be $db2
                $result.Status | Should Be "OFFLINE"
            }
            It "Identifies emergency database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db3
                $result.DatabaseName | Should Be $db3
                $result.Status | Should Be "EMERGENCY"
            }
            It "Identifies single_user database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db4
                $result.DatabaseName | Should Be $db4
                $result.Access | Should Be "SINGLE_USER"
            }
            It "Identifies restricted_user database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db5
                $result.DatabaseName | Should Be $db5
                $result.Access | Should Be "RESTRICTED_USER"
            }
            It "Identifies multi_user database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db6
                $result.DatabaseName | Should Be $db6
                $result.Access | Should Be "MULTI_USER"
            }
            It "Identifies read_write database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db7
                $result.DatabaseName | Should Be $db7
                $result.RW | Should Be "READ_WRITE"
            }
            It "Identifies read_only database" {
                $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db8
                $result.DatabaseName | Should Be $db8
                $result.RW | Should Be "READ_ONLY"
            }

            $result = Get-DbaDbState -SqlInstance $script:instance2 -Database $db1
            It "Has the correct properties" {
                $ExpectedProps = 'SqlInstance,InstanceName,ComputerName,DatabaseName,RW,Status,Access,Database'.Split(',')
                ($result.PsObject.Properties.Name | Sort-Object) | Should Be ($ExpectedProps | Sort-Object)
            }

            It "Has the correct default properties" {
                $ExpectedPropsDefault = 'SqlInstance,InstanceName,ComputerName,DatabaseName,RW,Status,Access'.Split(',')
                ($result.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames | Sort-Object) | Should Be ($ExpectedPropsDefault | Sort-Object)
            }
        }
    }
}