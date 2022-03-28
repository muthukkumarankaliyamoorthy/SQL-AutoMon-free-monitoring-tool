$scriptBlock = {
    param (
        $ModuleRoot,

        $DllRoot,

        $DoCopy
    )

    function Copy-Assembly {
        [CmdletBinding()]
        param (
            [string]$ModuleRoot,
            [string]$DllRoot,
            [bool]$DoCopy,
            [string]$Name
        )
        if (-not $DoCopy) {
            return
        }

        $DllRoot = (Resolve-Path -Path $DllRoot)

        if ((Resolve-Path -Path "$ModuleRoot\bin\smo") -eq $DllRoot) {
            return
        }

        if (-not (Test-Path $DllRoot)) {
            $null = New-Item -Path $DllRoot -ItemType Directory -ErrorAction Ignore -Force
        }

        Copy-Item -Path "$ModuleRoot\bin\smo\$Name.dll" -Destination $DllRoot
    }

    #region Names
    if ($PSVersionTable.PSEdition -eq "Core") {
        $names = @(
            'win\Microsoft.Data.SqlClient',
            'Microsoft.Data.Tools.Sql.BatchParser',
            'Microsoft.SqlServer.ConnectionInfo',
            'Microsoft.SqlServer.Management.Dmf',
            'Microsoft.SqlServer.Management.PSProvider',
            'Microsoft.SqlServer.Management.PSSnapins',
            'Microsoft.SqlServer.Management.XEvent',
            'Microsoft.SqlServer.XEvent.Linq',
            'Microsoft.SqlServer.Management.XEventDbScoped',
            'Microsoft.SqlServer.Management.XEventDbScopedEnum',
            'Microsoft.SqlServer.Management.XEventEnum',
            'Microsoft.SqlServer.Smo',
            'Microsoft.SqlServer.SmoExtended',
            'System.Security.SecureString',
            'Microsoft.Data.Tools.Utilities',
            'Microsoft.SqlServer.Dac',
            'Microsoft.SqlServer.Dac.Extensions',
            'Microsoft.SqlServer.Types',
            'Microsoft.SqlServer.Management.RegisteredServers',
            'Microsoft.SqlTools.Hosting',
            'Microsoft.SqlTools.ManagedBatchParser',
            'Microsoft.SqlServer.Management.Dmf',
            'Microsoft.SqlServer.XE.Core',
            'System.Net.Http',
            'Microsoft.Identity.Client',
            'Microsoft.SqlServer.XEvent.XELite',
            'SqlServer.XEvent'
        )
    } else {
        $names = @(
            'System.Net.Http',
            'Microsoft.Data.SqlClient',
            'Microsoft.SqlServer.Smo',
            'Microsoft.SqlServer.SmoExtended',
            'Microsoft.SqlServer.ConnectionInfo',
            'Microsoft.SqlServer.BatchParser',
            'Microsoft.SqlServer.BatchParserClient',
            'Microsoft.SqlServer.XE.Core',
            'Microsoft.SqlServer.Management.XEvent',
            'Microsoft.SqlServer.Management.XEventDbScoped',
            'Microsoft.SqlServer.Management.Sdk.Sfc',
            'Microsoft.SqlServer.SqlWmiManagement',
            'Microsoft.SqlServer.Management.RegisteredServers',
            'Microsoft.SqlServer.Management.Collector',
            'Microsoft.SqlServer.SqlClrProvider',
            'Microsoft.SqlServer.SqlTDiagm',
            'Microsoft.SqlServer.SString',
            'Microsoft.SqlServer.Dac',
            'Microsoft.Data.Tools.Sql.BatchParser',
            'Microsoft.Data.Tools.Utilities',
            'Microsoft.SqlServer.Dmf',
            'Microsoft.SqlServer.Dmf.Common',
            'Microsoft.SqlServer.Types',
            'Microsoft.SqlServer.XEvent.Linq',
            'Microsoft.Identity.Client',
            'Microsoft.SqlServer.XEvent.XELite',
            'SqlServer.XEvent'
        )
    }
    # XEvent stuff kills CI/CD
    if ($PSVersionTable.OS -match "ARM64") {
        $names = $names | Where-Object { $PSItem -notmatch "XE" }
    }
    #endregion Names

    $basePath = $dllRoot
    if ($PSVersionTable.PSEdition -eq 'core') {
        $basePath = "$(Join-Path $dllRoot coreclr)"
    }

    $shared = @()
    $separator = [IO.Path]::DirectorySeparatorChar
    $shared += "third-party" + $separator + "Bogus" + $separator + "Bogus"
    $assemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()

    foreach ($name in $shared) {
        $assemblyPath = "$script:PSModuleRoot" + $separator + "bin\libraries" + $separator + "$name.dll"

        $null = try {
            Import-Module $assemblyPath
        } catch {
            try {
                [Reflection.Assembly]::LoadFrom($assemblyPath)
            } catch {
                Write-Error "Could not import $assemblyPath : $($_ | Out-String)"
            }
        }
    }

    foreach ($name in $names) {
        if ($name.StartsWith("win\") -and ($isLinux -or $IsMacOS)) {
            $name = $name.Replace("win\", "")
        }
        $x64only = 'Microsoft.SqlServer.Replication', 'Microsoft.SqlServer.XEvent.Linq', 'Microsoft.SqlServer.BatchParser', 'Microsoft.SqlServer.Rmo', 'Microsoft.SqlServer.BatchParserClient'
        if ($name -in $x64only -and $env:PROCESSOR_ARCHITECTURE -eq "x86") {
            Write-Verbose -Message "Skipping $name. x86 not supported for this library."
            continue
        }
        Copy-Assembly -ModuleRoot $ModuleRoot -DllRoot $DllRoot -DoCopy $DoCopy -Name $name
        $assemblyPath = "$basepath$([IO.Path]::DirectorySeparatorChar)$name.dll"

        if (-not (($assemblies.FullName | Out-String).Contains("$name,".Replace("win\", "")))) {
            $null = try {
                Import-Module $assemblyPath
            } catch {
                try {
                    [Reflection.Assembly]::LoadFrom($assemblyPath)
                } catch {
                    Write-Error "Could not import $assemblyPath : $($_ | Out-String)"
                }
            }
        }
    }
}

$script:serialImport = $true
if ($script:serialImport) {
    $scriptBlock.Invoke($script:PSModuleRoot, "$(Join-Path $script:DllRoot smo)", $script:copyDllMode)
} else {
    $script:smoRunspace = [System.Management.Automation.PowerShell]::Create()
    if ($script:smoRunspace.Runspace.Name) {
        try { $script:smoRunspace.Runspace.Name = "dbatools-import-smo" }
        catch { }
    }
    $script:smoRunspace.AddScript($scriptBlock).AddArgument($script:PSModuleRoot).AddArgument("$(Join-Path $script:DllRoot smo)").AddArgument((-not $script:strictSecurityMode))
    $script:smoRunspace.BeginInvoke()
}