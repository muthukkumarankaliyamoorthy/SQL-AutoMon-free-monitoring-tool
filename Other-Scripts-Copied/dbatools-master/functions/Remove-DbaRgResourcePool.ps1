function Remove-DbaRgResourcePool {
    <#
    .SYNOPSIS
        Removes a resource pool from the Resource Governor on the specified SQL Server.

    .DESCRIPTION
        Removes a resource pool from the Resource Governor on the specified SQL Server.
        A resource pool represents a subset of the physical resources (memory, CPUs and IO) of an instance of the Database Engine.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Credential object used to connect to the Windows server as a different user

    .PARAMETER ResourcePool
        Name of the resource pool to be created.

    .PARAMETER Type
        Internal or External.

    .PARAMETER SkipReconfigure
        Resource Governor requires a reconfiguriation for resource pool changes to take effect.
        Use this switch to skip issuing a reconfigure for the Resource Governor.

    .PARAMETER InputObject
        Allows input to be piped from Get-DbaRgResourcePool.

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: ResourcePool, ResourceGovernor
        Author: John McCall (@lowlydba), https://www.lowlydba.com/

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Remove-DbaRgResourcePool

    .EXAMPLE
        PS C:\> Remove-DbaRgResourcePool -SqlInstance sql2016 -ResourcePool "poolAdmin" -Type Internal

        Removes an internal resource pool named "poolAdmin" for the instance sql2016.

    .EXAMPLE
        PS C:\> Get-DbaRgResourcePool -SqlInstance sql2016 -Type "Internal" | Where-Object { $_.IsSystemObject -eq $false } | Remove-DbaRgResourcePool

        Removes all user internal resource pools for the instance sql2016 by piping output from Get-DbaRgResourcePool.
    #>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Default", ConfirmImpact = "Low")]
    param (
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [DbaInstanceParameter[]]$SqlInstance,
        [Parameter(ValueFromPipelineByPropertyName)]
        [PSCredential]$SqlCredential,
        [string[]]$ResourcePool,
        [ValidateSet("Internal", "External")]
        [string]$Type = "Internal",
        [switch]$SkipReconfigure,
        [Parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject -and -not $ResourcePool) {
            Stop-Function -Message "You must pipe in a resource pool or specify a ResourcePool."
            return
        }
        if (-not $InputObject -and -not $SqlInstance) {
            Stop-Function -Message "You must pipe in a resource pool or specify a SqlInstance."
            return
        }

        if (($InputObject) -and ($PSBoundParameters.Keys -notcontains 'Type')) {
            if ($InputObject -is [Microsoft.SqlServer.Management.Smo.ResourcePool]) {
                $Type = "Internal"
            } elseif ($InputObject -is [Microsoft.SqlServer.Management.Smo.ExternalResourcePool]) {
                $Type = "External"
            }
        }

        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance -SqlCredential $SqlCredential
            } catch {
                Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }
            if ($Type -eq "Internal") {
                $InputObject += $server.ResourceGovernor.ResourcePools | Where-Object Name -in $ResourcePool
            } elseif ($Type -eq "External") {
                $InputObject += $server.ResourceGovernor.ExternalResourcePools | Where-Object Name -in $ResourcePool
            }
        }

        foreach ($resPool in $InputObject) {
            try {
                $server = $resPool.Parent.Parent
                if ($Pscmdlet.ShouldProcess($resPool, "Dropping existing resource pool")) {
                    try {
                        $resPool.Drop()
                    } catch {
                        Stop-Function -Message "Could not remove existing resource pool $resPool on $server." -Target $resPool -Continue
                    }
                }

                # Reconfigure Resource Governor
                if ($SkipReconfigure) {
                    Write-Message -Level Warning -Message "Resource pool changes will not take effect in Resource Governor until it is reconfigured."
                } elseif ($PSCmdlet.ShouldProcess($server, "Reconfiguring the Resource Governor")) {
                    $server.ResourceGovernor.Alter()
                }
            } catch {
                Stop-Function -Message "Failure" -ErrorRecord $_ -Target $resPool -Continue
            }
        }
    }
}