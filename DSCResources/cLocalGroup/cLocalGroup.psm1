<#
Author  : Serge Nikalaichyk (https://www.linkedin.com/in/nikalaichyk)
Version : 1.0.1
Date    : 2015-10-15
#>


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName
    )

    $Group = Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue

    if ($Group)
    {
        Write-Verbose -Message "Local group '$GroupName' was found."

        $EnsureResult = 'Present'
    }
    else
    {
        Write-Verbose -Message "Local group '$GroupName' could not be found."

        $EnsureResult = 'Absent'
    }

    $ReturnValue = @{
            GroupName = $GroupName
            Description = $Group.Description
            Members = [String[]]@($Group.Members)
            Ensure = $EnsureResult
        }

    return $ReturnValue

}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Absent', 'Present')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Members,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $MembersToInclude
    )

    $PSBoundParameters.GetEnumerator() |
    ForEach-Object -Begin {
        $Width = $PSBoundParameters.Keys.Length | Sort-Object -Descending | Select-Object -First 1
    } -Process {
        "{0,-$($Width)} : '{1}'" -f $_.Key, ($_.Value -join ', ') |
        Write-Verbose
    }

    $TargetResource = Get-TargetResource -GroupName $GroupName

    if ($Ensure -eq 'Absent')
    {
        if ($TargetResource.Ensure -eq 'Absent')
        {
            $InDesiredState = $true
        }
        else
        {
            $InDesiredState = $false
        }
    }
    elseif ($Ensure -eq 'Present')
    {
        if ($TargetResource.Ensure -eq 'Absent')
        {
            $InDesiredState = $false
        }
        else
        {
            $InDesiredState = $true

            if ($PSBoundParameters.ContainsKey('Description'))
            {
                if ($TargetResource.Description -cne $Description)
                {
                    $InDesiredState = $false
                }
            }

            if ($PSBoundParameters.ContainsKey('Members'))
            {
                if ($PSBoundParameters.ContainsKey('MembersToExclude') -or $PSBoundParameters.ContainsKey('MembersToInclude'))
                {
                    throw "Parameter 'Members' cannot be specified along with 'MembersToExclude' or 'MembersToInclude'."
                }

                $ReferenceMembers = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[String]'

                if ($Members.Count -ne 0)
                {
                    $Members |
                    Resolve-IdentityReference |
                    Select-Object -ExpandProperty Name -Unique |
                    ForEach-Object {$ReferenceMembers.Add($_)}
                }

                if (Compare-Object -ReferenceObject $ReferenceMembers -DifferenceObject $TargetResource.Members)
                {
                    $InDesiredState = $false
                }
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('MembersToExclude'))
                {
                    $ReferenceMembersToExclude = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[String]'

                    $MembersToExclude |
                    Resolve-IdentityReference |
                    Select-Object -ExpandProperty Name -Unique |
                    ForEach-Object {$ReferenceMembersToExclude.Add($_)}
                }

                if ($PSBoundParameters.ContainsKey('MembersToInclude'))
                {
                    $ReferenceMembersToInclude = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[String]'

                    $MembersToInclude |
                    Resolve-IdentityReference |
                    Select-Object -ExpandProperty Name -Unique |
                    ForEach-Object {$ReferenceMembersToInclude.Add($_)}
                }

                if ($ReferenceMembersToExclude -and $ReferenceMembersToInclude)
                {
                    Compare-Object -DifferenceObject $ReferenceMembersToExclude -ReferenceObject $ReferenceMembersToInclude -ExcludeDifferent -IncludeEqual |
                    ForEach-Object {

                       "Member '{0}' is present in both 'MembersToExclude' and 'MembersToInclude' collections." -f $_.InputObject |
                       Write-Verbose

                       "'MembersToExclude' takes precedence over 'MembersToInclude'." |
                       Write-Verbose

                       [Void]$ReferenceMembersToInclude.Remove($_.InputObject)

                    }
                }

                if ($ReferenceMembersToExclude.Count -ne 0)
                {
                    if ($TargetResource.Members | Where-Object {$_ -in $ReferenceMembersToExclude})
                    {
                        $InDesiredState = $false
                    }
                }

                if ($ReferenceMembersToInclude.Count -ne 0)
                {
                    if ($ReferenceMembersToInclude | Where-Object {$_ -notin $TargetResource.Members})
                    {
                        $InDesiredState = $false
                    }
                }
            }
        }
    }

    if ($InDesiredState -eq $true)
    {
        Write-Verbose -Message "The target resource is already in the desired state. No action is required."
    }
    else
    {
        Write-Verbose -Message "The target resource is not in the desired state."
    }

    return $InDesiredState

}


function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Absent', 'Present')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [Parameter(Mandatory = $false)]
        [String]
        $Description,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Members,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $MembersToExclude,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $MembersToInclude
    )

    $TargetResource = Get-TargetResource -GroupName $GroupName

    if (-not $PSCmdlet.ShouldProcess($GroupName))
    {
        return
    }

    if ($Ensure -eq 'Absent')
    {
        if ($TargetResource.Ensure -eq 'Present')
        {
            Remove-LocalGroup -Name $GroupName -Confirm:$false -ErrorAction Stop
        }
    }
    elseif ($Ensure -eq 'Present')
    {
        if ($TargetResource.Ensure -eq 'Absent')
        {
            New-LocalGroup -Name $GroupName -ErrorAction Stop

            $TargetResource = Get-TargetResource -GroupName $GroupName -ErrorAction Stop
        }

        if ($PSBoundParameters.ContainsKey('Description'))
        {
            if ($TargetResource.Description -cne $Description)
            {
                Set-LocalGroup -Name $GroupName -Description $Description
            }
        }

        if ($PSBoundParameters.ContainsKey('Members'))
        {
            if ($PSBoundParameters.ContainsKey('MembersToExclude') -or $PSBoundParameters.ContainsKey('MembersToInclude'))
            {
                throw "Parameter 'Members' cannot be specified along with 'MembersToExclude' or 'MembersToInclude'."
            }

            $ReferenceMembers = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[String]'

            if ($Members.Count -ne 0)
            {
                $Members |
                Resolve-IdentityReference |
                Select-Object -ExpandProperty Name -Unique |
                ForEach-Object {$ReferenceMembers.Add($_)}
            }

            Compare-Object -ReferenceObject $ReferenceMembers -DifferenceObject $TargetResource.Members |
            ForEach-Object {

                if ($_.SideIndicator -eq '<=')
                {
                    Add-LocalGroupMember -Name $GroupName -Members $_.InputObject
                }

                if ($_.SideIndicator -eq '=>')
                {
                    Remove-LocalGroupMember -Name $GroupName -Members $_.InputObject
                }

            }
        }
        else
        {
            if ($PSBoundParameters.ContainsKey('MembersToExclude'))
            {
                $ReferenceMembersToExclude = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[String]'

                $MembersToExclude |
                Resolve-IdentityReference |
                Select-Object -ExpandProperty Name -Unique |
                ForEach-Object {$ReferenceMembersToExclude.Add($_)}
            }

            if ($PSBoundParameters.ContainsKey('MembersToInclude'))
            {
                $ReferenceMembersToInclude = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[String]'

                $MembersToInclude |
                Resolve-IdentityReference |
                Select-Object -ExpandProperty Name -Unique |
                ForEach-Object {$ReferenceMembersToInclude.Add($_)}
            }

            if ($ReferenceMembersToExclude -and $ReferenceMembersToInclude)
            {
                Compare-Object -DifferenceObject $ReferenceMembersToExclude -ReferenceObject $ReferenceMembersToInclude -ExcludeDifferent -IncludeEqual |
                ForEach-Object {

                    "Member '{0}' is present in both 'MembersToExclude' and 'MembersToInclude' collections." -f $_.InputObject |
                    Write-Verbose

                    "'MembersToExclude' takes precedence over 'MembersToInclude'." |
                    Write-Verbose
    
                    [Void]$ReferenceMembersToInclude.Remove($_.InputObject)

                }
            }

            if ($ReferenceMembersToExclude.Count -ne 0)
            {
                $TargetResource.Members |
                Where-Object {$_ -in $ReferenceMembersToExclude} |
                Remove-LocalGroupMember -Name $GroupName
            }

            if ($ReferenceMembersToInclude.Count -ne 0)
            {
                $ReferenceMembersToInclude |
                Where-Object {$_ -notin $TargetResource.Members} |
                Add-LocalGroupMember -Name $GroupName
            }
        }
    }
}


Export-ModuleMember -Function Get-TargetResource, Set-TargetResource, Test-TargetResource


#region Helper Functions

function Get-LocalGroup
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
    )
    begin
    {
        $Computer = [ADSI]"WinNT://$Env:ComputerName"
    }
    process
    {
        try
        {
            $Group = $Computer.PSBase.Children.Find($Name, 'Group')
        }
        catch
        {
            "Local group '{0}' could not be found: '{1}'" -f $Name, $_.Exception.Message |
            Write-Error

            return
        }
 
        $OutputObject = [PSCustomObject]@{
                Name = [String]$Group.Name 
                Description = [String]$Group.Description
                Members = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[String]'
            }

        $Group.PSBase.Invoke('Members') |
        ForEach-Object {
            $objectSID = ([ADSI]$_).InvokeGet('objectSID')
            $SecurityIdentifier = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $objectSID, 0
            $NTAccount = $SecurityIdentifier.Translate([System.Security.Principal.NTAccount])
            $OutputObject.Members.Add($NTAccount.Value)
        }

        return $OutputObject

    }
}


function New-LocalGroup
{
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
    )
    begin
    {
        $Computer = [ADSI]"WinNT://$Env:ComputerName"
    }
    process
    {
        if ($Name -match '(^[\s|\.]*?$)|([\\\/\"\[\]\:\|\<\>\+\=\;\,\?\*\@])')
        {
            "The name '$Name' cannot be used. Names may not consist entirely of periods and/or spaces, or contain these characters: \/`"[]:|<>+=;,?*@" |
            Write-Error

            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Create Group'))
        {
            Write-Verbose -Message "Creating local group '$Name'."

            $Group = $Computer.Create('Group', $Name)
            $Group.SetInfo()
        }
    }
}


function Remove-LocalGroup
{
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
    )
    begin
    {
        $Computer = [ADSI]"WinNT://$Env:ComputerName"
    }
    process
    {
        try
        {
            $Group = $Computer.PSBase.Children.Find($Name, 'Group')
        }
        catch
        {
            "Local group '{0}' could not be found: '{1}'" -f $Name, $_.Exception.Message |
            Write-Error

            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Remove Group'))
        {
            Write-Verbose -Message "Removing local group '$Name'."

            $Computer.PSBase.Children.Remove($Group)
        }
    }
}


function Set-LocalGroup
{
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $false)]
        [String]
        $Description = $null
    )
    begin
    {
        $Computer = [ADSI]"WinNT://$Env:ComputerName"
    }
    process
    {
        try
        {
            $Group = $Computer.PSBase.Children.Find($Name, 'Group')
        }
        catch
        {
            "Local group '{0}' could not be found: '{1}'" -f $Name, $_.Exception.Message |
            Write-Error

            return
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Set Group'))
        {
            if ($PSBoundParameters.ContainsKey('Description'))
            {
                Write-Verbose -Message "Setting description for local group '$Name'."

                $Group.Description = $Description
                $Group.SetInfo()
            }
        }
    }
}


function Add-LocalGroupMember
{
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Members
    )
    begin
    {
        $Computer = [ADSI]"WinNT://$Env:ComputerName"
    }
    process
    {
        try
        {
            $Group = $Computer.PSBase.Children.Find($Name, 'Group')
        }
        catch
        {
            "Local group '{0}' could not be found: '{1}'" -f $Name, $_.Exception.Message |
            Write-Error

            return
        }

        $Members |
        Select-Object -PipelineVariable Member |
        ForEach-Object {

            if ($Member -match '\\')
            {
                $ADsPath = $Member -ireplace '^(?<Domain>.*?)\\(?<UserName>.*?)$', 'WinNT://${Domain}/${UserName}'
            }
            else
            {
                try
                {
                    # Resolve and normalize member's identity
                    $Identity = Resolve-IdentityReference -Identity $Member -ErrorAction Stop
                    $ADsPath = $Identity.Name -ireplace '^(?<Domain>.*?)\\(?<UserName>.*?)$', 'WinNT://${Domain}/${UserName}'
                }
                catch
                {
                    Write-Error -Message $_.Exception.Message

                    return
                }
            }

            try
            {
                if ($PSCmdlet.ShouldProcess($Name, 'Add Member'))
                {
                    "Adding member '{0}' to local group '{1}'." -f $Member, $Name |
                    Write-Verbose

                    $Group.Add($ADsPath)
                }
            }
            catch
            {
                Write-Error -Message $_.Exception.Message

                return
            }

        }
    }
}


function Remove-LocalGroupMember
{
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Members
    )
    begin
    {
        $Computer = [ADSI]"WinNT://$Env:ComputerName"
    }
    process
    {
        try
        {
            $Group = $Computer.PSBase.Children.Find($Name, 'Group')
        }
        catch
        {
            "Local group '{0}' could not be found: '{1}'" -f $Name, $_.Exception.Message |
            Write-Error

            return
        }

        $Members |
        Select-Object -PipelineVariable Member |
        ForEach-Object {
 
            if ($Member -match '\\')
            {
                $ADsPath = $Member -ireplace '^(?<Domain>.*?)\\(?<UserName>.*?)$', 'WinNT://${Domain}/${UserName}'
            }
            else
            {
                try
                {
                    # Resolve and normalize member's identity
                    $Identity = Resolve-IdentityReference -Identity $Member -ErrorAction Stop
                    $ADsPath = $Identity.Name -ireplace '^(?<Domain>.*?)\\(?<UserName>.*?)$', 'WinNT://${Domain}/${UserName}'
                }
                catch
                {
                    Write-Error -Message $_.Exception.Message

                    return
                }
            }

            try
            {
                if ($PSCmdlet.ShouldProcess($Name, 'Remove Member'))
                {
                    "Removing member '{0}' from local group '{1}'." -f $Member, $Name |
                    Write-Verbose

                    $Group.Remove($ADsPath)
                }
            }
            catch
            {
                Write-Error -Message $_.Exception.Message

                return
            }

        }
    }
}


function Resolve-IdentityReference
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Identity
    )
    process
    {
        try
        {
            Write-Verbose -Message "Resolving identity reference '$Identity'."

            if ($Identity -match '^S-\d-(\d+-){1,14}\d+$')
            {
                [System.Security.Principal.SecurityIdentifier]$Identity = $Identity
            }
            else
            {
                [System.Security.Principal.NTAccount]$Identity = $Identity
            }

            $SID = $Identity.Translate([System.Security.Principal.SecurityIdentifier])
            $NTAccount = $SID.Translate([System.Security.Principal.NTAccount])

            $OutputObject = [PSCustomObject]@{Name = $NTAccount.Value; SID = $SID.Value}

            return $OutputObject
        }
        catch
        {
            "Unable to resolve identity reference '{0}'. Error: '{1}'" -f $Identity, $_.Exception.Message |
            Write-Error

            return
        }
    }
}


#endregion

