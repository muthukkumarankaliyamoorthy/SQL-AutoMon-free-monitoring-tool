function Remove-DbaAgentAlertCategory {
    <#
    .SYNOPSIS
        Remove-DbaAgentAlertCategory removes an alert category.

    .DESCRIPTION
        Remove-DbaAgentAlertCategory makes it possible to remove an alert category.
        Insure that the category you want to remove is not used with any alerts. If an alert uses this category it will be get the category [Uncategorized].

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. You must have sysadmin access and server version must be SQL Server version 2000 or greater.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Category
        The name of the category

    .PARAMETER InputObject
        Allows piping from Get-DbaAgentAlertCategory.

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: Agent, Alert, AlertCategory
        Author: Patrick Flynn (@sqllensman)

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Remove-DbaAgentAlertCategory

    .EXAMPLE
        PS C:\> Remove-DbaAgentAlertCategory -SqlInstance sql1 -Category 'Category 1'

        Remove the alert category Category 1 from the instance.

    .EXAMPLE
        PS C:\> Remove-DbaAgentAlertCategory -SqlInstance sql1 -Category Category1, Category2, Category3

        Remove multiple alert categories from the instance.

    .EXAMPLE
        PS C:\> Remove-DbaAgentAlertCategory -SqlInstance sql1, sql2, sql3 -Category Category1, Category2, Category3

        Remove multiple alert categories from the multiple instances.

    .EXAMPLE
        PS C:\> Get-DbaAgentAlertCategory -SqlInstance SRV1 | Out-GridView -Title 'Select SQL Agent alert category(-ies) to drop' -OutputMode Multiple | Remove-DbaAgentAlertCategory

        Using a pipeline this command gets all SQL Agent alert category(-ies) on SRV1, lets the user select those to remove and then removes the selected SQL Agent alert category(-ies).

    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ParameterSetName = 'NonPipeline', Mandatory = $true, Position = 0)]
        [DbaInstanceParameter[]]$SqlInstance,
        [Parameter(ParameterSetName = 'NonPipeline')]
        [PSCredential]$SqlCredential,
        [Parameter(ParameterSetName = 'NonPipeline')]
        [string[]]$Category,
        [parameter(ValueFromPipeline, ParameterSetName = 'Pipeline', Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Agent.AlertCategory[]]$InputObject,
        [Parameter(ParameterSetName = 'NonPipeline')][Parameter(ParameterSetName = 'Pipeline')]
        [switch]$EnableException
    )

    begin {
        $agentCategories = @( )
    }

    process {
        if ($SqlInstance) {
            $params = $PSBoundParameters
            $null = $params.Remove('WhatIf')
            $null = $params.Remove('Confirm')
            $agentCategories = Get-DbaAgentAlertCategory @params
        } else {
            $agentCategories += $InputObject
        }
    }

    end {
        # We have to delete in the end block to prevent "Collection was modified; enumeration operation may not execute." if directly piped from Get-DbaAgentAlertCategory.
        foreach ($agentCategory in $agentCategories) {
            if ($PSCmdlet.ShouldProcess($agentCategory.Parent.Parent.Name, "Removing the SQL Agent alert category $($agentCategory.Name) on $($agentCategory.Parent.Parent.Name)")) {
                $output = [pscustomobject]@{
                    ComputerName = $agentCategory.Parent.Parent.ComputerName
                    InstanceName = $agentCategory.Parent.Parent.ServiceName
                    SqlInstance  = $agentCategory.Parent.Parent.DomainInstanceName
                    Name         = $agentCategory.Name
                    Status       = $null
                    IsRemoved    = $false
                }
                try {
                    $agentCategory.Drop()
                    $output.Status = "Dropped"
                    $output.IsRemoved = $true
                } catch {
                    Stop-Function -Message "Failed removing the SQL Agent alert category $($agentCategory.Name) on $($agentCategory.Parent.Parent.Name)" -ErrorRecord $_
                    $output.Status = (Get-ErrorMessage -Record $_)
                    $output.IsRemoved = $false
                }
                $output
            }
        }
    }
}