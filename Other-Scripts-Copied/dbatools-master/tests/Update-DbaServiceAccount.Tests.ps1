$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object { $_ -notin ('whatif', 'confirm') }
        [object[]]$knownParameters = 'ComputerName', 'Credential', 'InputObject', 'ServiceName', 'Username', 'ServiceCredential', 'PreviousPassword', 'SecurePassword', 'NoRestart', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object { $_ }) -DifferenceObject $params).Count ) | Should -Be 0
        }
    }
}

Describe "$CommandName Integration Tests" -Tags "IntegrationTests" {

    BeforeAll {
        $login = 'winLogin'
        $password = 'MyV3ry$ecur3P@ssw0rd'
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $newPassword = 'Myxtr33mly$ecur3P@ssw0rd'
        $newSecurePassword = ConvertTo-SecureString $newPassword -AsPlainText -Force
        $server = Connect-DbaInstance -SqlInstance $script:instance2
        $computerName = $server.NetName
        $instanceName = $server.ServiceName
        $winLogin = "$computerName\$login"

        #cleanup
        $computer = [ADSI]"WinNT://$computerName"
        try {
            $user = [ADSI]"WinNT://$computerName/$login,user"
            if ($user.Name -eq $login) {
                $computer.Delete('User', $login)
            }
        } catch { <#User does not exist#> }

        if ($l = Get-DbaLogin -SqlInstance $script:instance2 -Login $winLogin) {
            $results = $server.Query("IF EXISTS (SELECT * FROM sys.server_principals WHERE name = '$winLogin') EXEC sp_who '$winLogin'")
            foreach ($spid in $results.spid) {
                $null = $server.Query("kill $spid")
            }
            if ($c = $l.EnumCredentials()) {
                $l.DropCredential($c)
            }
            $l.Drop()
        }
        #create Windows login
        $user = $computer.Create("user", $login)
        $user.SetPassword($password)
        $user.SetInfo()

        #Get current service users
        $services = Get-DbaService -ComputerName $script:instance2 -Type Engine, Agent -Instance $instanceName
        $currentAgentUser = ($services | Where-Object { $_.ServiceType -eq 'Agent' }).StartName
        $currentEngineUser = ($services | Where-Object { $_.ServiceType -eq 'Engine' }).StartName

        #Create a new sysadmin login on SQL Server
        $newLogin = New-Object Microsoft.SqlServer.Management.Smo.Login($server, $winLogin)
        $newLogin.LoginType = "WindowsUser"
        $newLogin.Create()
        $server.Roles['sysadmin'].AddMember($winLogin)

        $isRevertable = $true
        ForEach ($svcaccount in $currentAgentUser, $currentEngineUser) {
            if (! ($svcaccount.EndsWith('$') -or $svcaccount.StartsWith('NT AUTHORITY\') -or $svcaccount.StartsWith('NT Service\'))) {
                $isRevertable = $false
            }
        }
        #Do not continue with the test if current configuration cannot be rolled back
        if (!$isRevertable) {
            Throw 'Current configuration cannot be rolled back - the test will not continue.'
        }
    }

    AfterAll {
        #Cleanup
        $server.Logins[$winLogin].Drop()
        $computer.Delete('User', $login)
    }

    Context "Current configuration to be able to roll back" {
        It "Both agent and engine services must exist" {
            ($services | Measure-Object).Count | Should -Be 2
        }
        It "Current service accounts should be localsystem-like or MSA to allow for a rollback" {
            $isRevertable | Should -Be $true
        }
    }



    Context "Set new service account for SQL Services" {


        $errVar = $warnVar = $null
        $cred = New-Object System.Management.Automation.PSCredential($login, $securePassword)
        $results = Update-DbaServiceAccount -ComputerName $computerName -ServiceName $services.ServiceName -ServiceCredential $cred -ErrorVariable $errVar -WarningVariable $warnVar

        It "Should return something" {
            $results | Should -Not -Be $null
        }
        It "Should have no errors or warnings" {
            $errVar | Should -Be $null
            $warnVar | Should -Be $null
        }
        It "Should be successful" {
            foreach ($result in $results) {
                $result.Status | Should -Be 'Successful'
                $result.State | Should -Be 'Running'
                $result.StartName | Should -Be ".\$login"
            }
        }
    }

    Context "Change password of the service account" {
        #Change the password
        ([adsi]"WinNT://$computerName/$login,user").SetPassword($newPassword)

        $errVar = $warnVar = $null
        $results = $services | Sort-Object ServicePriority | Update-DbaServiceAccount -Password $newSecurePassword -ErrorVariable $errVar -WarningVariable $warnVar

        It "Password change should return something" {
            $results | Should -Not -Be $null
        }
        It "Should have no errors or warnings" {
            $errVar | Should -Be $null
            $warnVar | Should -Be $null
        }
        It "Should be successful" {
            foreach ($result in $results) {
                $result.Status | Should -Be 'Successful'
                $result.State | Should -Be 'Running'
            }
        }

        $results = Get-DbaService -ComputerName $computerName -ServiceName $services.ServiceName | Restart-DbaService
        It "Service restart should return something" {
            $results | Should -Not -Be $null
        }
        It "Service restart should be successful" {
            foreach ($result in $results) {
                $result.Status | Should -Be 'Successful'
                $result.State | Should -Be 'Running'
            }
        }
    }

    Context "Change agent service account to local system" {
        $errVar = $warnVar = $null
        $results = $services | Where-Object { $_.ServiceType -eq 'Agent' } | Update-DbaServiceAccount -Username 'NT AUTHORITY\LOCAL SYSTEM' -ErrorVariable $errVar -WarningVariable $warnVar

        It "Should return something" {
            $results | Should -Not -Be $null
        }
        It "Should have no errors or warnings" {
            $errVar | Should -Be $null
            $warnVar | Should -Be $null
        }
        It "Should be successful" {
            foreach ($result in $results) {
                $result.Status | Should -Be 'Successful'
                $result.State | Should -Be 'Running'
                $result.StartName | Should -Be 'LocalSystem'
            }
        }
    }
    Context "Revert SQL Agent service account changes ($currentAgentUser)" {
        $errVar = $warnVar = $null
        $results = $services | Where-Object { $_.ServiceType -eq 'Agent' } | Update-DbaServiceAccount -Username $currentAgentUser -ErrorVariable $errVar -WarningVariable $warnVar

        It "Should return something" {
            $results | Should -Not -Be $null
        }
        It "Should have no errors or warnings" {
            $errVar | Should -Be $null
            $warnVar | Should -Be $null
        }
        It "Should be successful" {
            foreach ($result in $results) {
                $result.Status | Should -Be 'Successful'
                $result.State | Should -Be 'Running'
                $result.StartName | Should -Be $currentAgentUser
            }
        }
    }
    Context "Revert SQL Engine service account changes ($currentEngineUser)" {
        $errVar = $warnVar = $null
        $results = $services | Where-Object { $_.ServiceType -eq 'Engine' } | Update-DbaServiceAccount -Username $currentEngineUser -ErrorVariable $errVar -WarningVariable $warnVar

        It "Should return something" {
            $results | Should -Not -Be $null
        }
        It "Should have no errors or warnings" {
            $errVar | Should -Be $null
            $warnVar | Should -Be $null
        }
        It "Should be successful" {
            foreach ($result in $results) {
                $result.Status | Should -Be 'Successful'
                $result.State | Should -Be 'Running'
                $result.StartName | Should -Be $currentEngineUser
            }
        }

    }

}