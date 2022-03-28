$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object {$_ -notin ('whatif', 'confirm')}
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'Threshold', 'ExcludeSystem', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object {$_}) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {
    Context "Verify Test Identity Usage on TinyInt" {
        BeforeAll {
            $table = "TestTable_$(Get-random)"
            $tableDDL = "CREATE TABLE $table (testId TINYINT IDENTITY(1,1),testData DATETIME2 DEFAULT getdate() )"
            Invoke-DbaQuery -SqlInstance $script:instance1 -Query $tableDDL -database TempDb

        }
        AfterAll {
            $cleanup = "Drop table $table"
            Invoke-DbaQuery -SqlInstance $script:instance1 -Query $cleanup -database TempDb
        }

        $insertSql = "INSERT INTO $table (testData) DEFAULT VALUES"
        for ($i = 1; $i -le 128; $i++) {
            Invoke-DbaQuery -SqlInstance $script:instance1 -Query $insertSql -database TempDb
        }
        $results = Test-DbaIdentityUsage -SqlInstance $script:instance1 -Database TempDb | Where-Object {$_.Table -eq $table}

        It "Identity column should have 128 uses" {
            $results.NumberOfUses | Should Be 128
        }
        It "TinyInt identity column with 128 rows inserted should be 50.20% full" {
            $results.PercentUsed | Should Be 50.20
        }

        $insertSql = "INSERT INTO $table (testData) DEFAULT VALUES"
        for ($i = 1; $i -le 127; $i++) {
            Invoke-DbaQuery -SqlInstance $script:instance1 -Query $insertSql -database TempDb
        }
        $results = Test-DbaIdentityUsage -SqlInstance $script:instance1 -Database TempDb | Where-Object {$_.Table -eq $table}

        It "Identity column should have 255 uses" {
            $results.NumberOfUses | Should Be 255
        }
        It "TinyInt with 255 rows should be 100% full" {
            $results.PercentUsed | Should Be 100
        }

    }

    Context "Verify Test Identity Usage with increment of 5" {
        BeforeAll {
            $table = "TestTable_$(Get-random)"
            $tableDDL = "CREATE TABLE $table (testId tinyint IDENTITY(0,5),testData DATETIME2 DEFAULT getdate() )"
            Invoke-DbaQuery -SqlInstance $script:instance1 -Query $tableDDL -database TempDb

        }
        AfterAll {
            $cleanup = "Drop table $table"
            Invoke-DbaQuery -SqlInstance $script:instance1 -Query $cleanup -database TempDb
        }

        $insertSql = "INSERT INTO $table (testData) DEFAULT VALUES"
        for ($i = 1; $i -le 25; $i++) {
            Invoke-DbaQuery -SqlInstance $script:instance1 -Query $insertSql -database TempDb
        }
        $results = Test-DbaIdentityUsage -SqlInstance $script:instance1 -Database TempDb | Where-Object {$_.Table -eq $table}

        It "Identity column should have 24 uses" {
            $results.NumberOfUses | Should Be 24
        }
        It "TinyInt identity column with 25 rows using increment of 5 should be 47.06% full" {
            $results.PercentUsed | Should Be 47.06
        }
    }
}