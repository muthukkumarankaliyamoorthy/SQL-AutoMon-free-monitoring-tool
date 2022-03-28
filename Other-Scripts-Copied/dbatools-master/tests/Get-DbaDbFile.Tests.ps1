$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object { $_ -notin ('whatif', 'confirm') }
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'ExcludeDatabase', 'FileGroup', 'InputObject', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object { $_ }) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$CommandName Unit Tests" -Tag "Unit" {
    Context "Ensure array" {
        $results = Get-Command -Name Get-DbaDbFile | Select-Object -ExpandProperty ScriptBlock
        It "returns disks as an array" {
            $results -match '\$disks \= \@\(' | Should -Be $true
        }
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    Context "Should return file information" {
        $results = Get-DbaDbFile -SqlInstance $script:instance1
        It "returns information about tempdb files" {
            $results.Database -contains "tempdb" | Should -Be $true
        }
    }

    Context "Should return file information for only tempdb" {
        $results = Get-DbaDbFile -SqlInstance $script:instance1 -Database tempdb
        foreach ($result in $results) {
            It "returns only tempdb files" {
                $result.Database | Should -Be "tempdb"
            }
        }
    }

    Context "Should return file information for only tempdb primary filegroup" {
        $results = Get-DbaDbFile -SqlInstance $script:instance1 -Database tempdb -FileGroup Primary
        foreach ($result in $results) {
            It "returns only tempdb files that are in Primary filegroup" {
                $result.Database | Should -Be "tempdb"
                $result.FileGroupName | Should -Be "Primary"
            }
        }
    }

    Context "Physical name is populated" {
        $results = Get-DbaDbFile -SqlInstance $script:instance1 -Database master
        It "master returns proper results" {
            $result = $results | Where-Object LogicalName -eq 'master'
            $result.PhysicalName -match 'master.mdf' | Should -Be $true
            $result = $results | Where-Object LogicalName -eq 'mastlog'
            $result.PhysicalName -match 'mastlog.ldf' | Should -Be $true
        }
    }

    Context "Database ID is populated" {
        It "returns proper results for the master db" {
            $results = Get-DbaDbFile -SqlInstance $script:instance1 -Database master
            $results.DatabaseID | Get-Unique | Should -Be (Get-DbaDatabase -SqlInstance $script:instance1 -Database master).ID
        }
        It "uses a pipeline input and returns proper results for the tempdb" {
            $tempDB = Get-DbaDatabase -SqlInstance $script:instance1 -Database tempdb
            $results = $tempDB | Get-DbaDbFile
            $results.DatabaseID | Get-Unique | Should -Be $tempDB.ID
        }
    }
}