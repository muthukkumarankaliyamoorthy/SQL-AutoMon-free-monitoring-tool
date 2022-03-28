function Test-DbaBackupEncrypted {
    <#
    .SYNOPSIS
        Tests to see if a backup is encrypted

    .DESCRIPTION
        Tests to see if a backup is encrypted

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER FilePath
        The path to the backups

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: Backups, Encryption
        Author: Chrissy LeMaire (@cl), http://netnerds.net

        Website: https://dbatools.io
        Copyright: (c) 2022 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Test-DbaBackupEncrypted

    .EXAMPLE
        PS C:\> Test-DbaBackupEncrypted -SqlInstance sql01 -Path /tmp/northwind.bak

        Test to see if /tmp/northwind.bak is encrypted

    .EXAMPLE
        PS C:\> Get-ChildItem \\nas\sql\backups | Test-DbaBackupEncrypted -SqlInstance sql01

        Test to see if all of the backups in \\nas\sql\backups are encrypted
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [DbaInstanceParameter]$SqlInstance,
        [PSCredential]$SqlCredential,
        [parameter(ValueFromPipeline, Mandatory)]
        [Alias("FullName")]
        [string[]]$FilePath,
        [Switch]$EnableException
    )
    begin {
        try {
            $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
        } catch {
            Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $SqlInstance
            return
        }
    }
    process {
        if (Test-FunctionInterrupt) { return }

        #for each database, create custom object for return set.
        foreach ($file in $FilePath) {
            $encrypted = $false
            $thumbprint = $null

            $file = $file.Replace("'", "''")
            $sql = "RESTORE HEADERONLY FROM DISK = N'$file'"
            $results = $server.Query($sql)

            if ($results.KeyAlgorithm -isnot [dbnull] -or
                $results.EncryptorThumbprint -isnot [dbnull] -or
                $results.EncryptorType -isnot [dbnull]) {

                Write-Message -Level Verbose -Message "KeyAlgorithm or EncryptorThumbprint or EncryptorType is not null"
                $encrypted = $true
            }

            try {
                $sql = "RESTORE FILELISTONLY FROM DISK = N'$file'"
                $filelistonly = $server.Query($sql)
                $thumb = ($filelistonly | Where-Object TDEThumbprint | Select-Object -First 1).TDEThumbprint

                if ($thumb.Length -gt 1) {
                    Write-Message -Level Verbose -Message "Thumbprint found: $($filelistonly.TDEThumbprint)"
                    $encrypted = $true
                    $thumbprint = Convert-ByteToHexString $thumb
                }
            } catch {
                if ($PSItem -match "thumbprint") {
                    Write-Message -Level Verbose -Message "Thumbprint referenced in exception"
                    $encrypted = $true
                } else {
                    Write-Message -Level Verbose -Message "Caught exception: $PSItem"
                }
            }

            Write-Message -Level Verbose -Message "Checking $file"
            [pscustomobject]@{
                ComputerName        = $server.ComputerName
                InstanceName        = $server.ServiceName
                SqlInstance         = $server.DomainInstanceName
                FilePath            = $file
                BackupName          = $results.BackupName | Select-Object -First 1
                Encrypted           = $encrypted
                KeyAlgorithm        = $results.KeyAlgorithm | Select-Object -First 1
                EncryptorThumbprint = $results.EncryptorThumbprint | Select-Object -First 1
                EncryptorType       = $results.EncryptorType | Select-Object -First 1
                TDEThumbprint       = $thumbprint
                Compressed          = ($results | Select-Object -First 1).Compressed -eq $true
            }
        }
    }
}