$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object { $_ -notin ('whatif', 'confirm') }
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'LinkedServer', 'InputObject', 'Force', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object { $_ }) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $random = Get-Random
        $instance2 = Connect-DbaInstance -SqlInstance $script:instance2
        $instance3 = Connect-DbaInstance -SqlInstance $script:instance3

        $linkedServerName1 = "dbatoolscli_LS1_$random"
        $linkedServerName2 = "dbatoolscli_LS2_$random"
        $linkedServerName3 = "dbatoolscli_LS3_$random"
        $linkedServerName4 = "dbatoolscli_LS4_$random"

        $linkedServer1 = New-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName1
        $linkedServer2 = New-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName2
        $linkedServer3 = New-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName3
        $linkedServer4 = New-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName4

        $securePassword = ConvertTo-SecureString -String 's3cur3P4ssw0rd?' -AsPlainText -Force
        $loginName = "dbatoolscli_test_$random"
        New-DbaLogin -SqlInstance $instance2, $instance3 -Login $loginName -SecurePassword $securePassword

        $newLinkedServerLogin = New-Object Microsoft.SqlServer.Management.Smo.LinkedServerLogin
        $newLinkedServerLogin.Parent = $linkedServer4
        $newLinkedServerLogin.Name = $loginName
        $newLinkedServerLogin.RemoteUser = $loginName
        $newLinkedServerLogin.SetRemotePassword(($securePassword | ConvertFrom-SecurePass))
        $newLinkedServerLogin.Create()
    }
    AfterAll {
        if ($instance2.LinkedServers.Name -contains $linkedServerName1) {
            $instance2.LinkedServers[$linkedServerName1].Drop()
        }

        if ($instance2.LinkedServers.Name -contains $linkedServerName2) {
            $instance2.LinkedServers[$linkedServerName2].Drop()
        }

        if ($instance2.LinkedServers.Name -contains $linkedServerName3) {
            $instance2.LinkedServers[$linkedServerName3].Drop()
        }

        if ($instance2.LinkedServers.Name -contains $linkedServerName4) {
            $instance2.LinkedServers[$linkedServerName4].Drop($true)
        }

        Remove-DbaLogin -SqlInstance $instance2, $instance3 -Login $loginName -Confirm:$false
    }

    Context "ensure command works" {

        It "Removes a linked server" {
            $results = Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName1
            $results.Length | Should -Be 1
            Remove-DbaLinkedServer -SqlInstance $script:instance2 -LinkedServer $linkedServerName1 -Confirm:$false
            $results = Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName1
            $results | Should -BeNullOrEmpty
        }

        It "Tries to remove a non-existent linked server" {
            Remove-DbaLinkedServer -SqlInstance $script:instance2 -LinkedServer $linkedServerName1 -Confirm:$false -WarningVariable warnings
            $warnings | Should -BeLike "*Linked server $linkedServerName1 does not exist on $($instance2.Name)"
        }

        It "Removes a linked server passed in via pipeline" {
            $results = Get-DbaLinkedServer -SqlInstance $script:instance2 -LinkedServer $linkedServerName2
            $results.Length | Should -Be 1
            Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName2 | Remove-DbaLinkedServer -Confirm:$false
            $results = Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName2
            $results | Should -BeNullOrEmpty
        }

        It "Removes a linked server using a server passed in via pipeline" {
            $results = Get-DbaLinkedServer -SqlInstance $script:instance2 -LinkedServer $linkedServerName3
            $results.Length | Should -Be 1
            $instance2 | Remove-DbaLinkedServer -LinkedServer $linkedServerName3 -Confirm:$false
            $results = Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName3
            $results | Should -BeNullOrEmpty
        }

        It "Tries to remove a linked server that still has logins" {
            Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName4 | Remove-DbaLinkedServer -Confirm:$false -WarningVariable warnings
            $warnings | Should -BeLike "*There are still remote logins or linked logins for the server*"
        }

        It "Removes a linked server that requires the -Force param" {
            Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName4 | Remove-DbaLinkedServer -Confirm:$false -Force
            $results = Get-DbaLinkedServer -SqlInstance $instance2 -LinkedServer $linkedServerName4
            $results | Should -BeNullOrEmpty
        }
    }
}