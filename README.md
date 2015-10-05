# cLocalGroup

The **cLocalGroup** module contains the **cLocalGroup** DSC resource that provides a mechanism to manage local groups.

Unlike the [**Group**](https://technet.microsoft.com/en-us/library/dn282124.aspx) built-in DSC resource, the **cLocalGroup**  resource does not require the `Credential` property to add non-local accounts to the group. However, this is not guaranteed to work in all environments.

## Resources

### cLocalGroup

* **Ensure**: Indicates if the group exists. Set this property to `Absent` to ensure that the group does not exist. Setting it to `Present` (the default value) ensures that the group exists.
* **GroupName**: Indicates the name of the group.
* **Description**: Indicates the description of the group.
* **Members**: Indicates that you want to ensure these members form the group.
* **MembersToExclude**: Indicates the users who you want ensure are not members of this group.
* **MembersToInclude**: Indicates the users who you want to ensure are members of the group.

> **Note:**
> The **Members** property cannot be combined with either of the **MembersToExclude** or **MembersToInclude** properties.

## Versions

### 1.0.0 (October 5, 2015)

* Initial release with the following resources:
  - **cLocalGroup**

## Examples

This configuration will ensure that two local groups exist (with or without the specified members).

```powershell

configuration Sample_cLocalGroup
{
    Import-DscResource -ModuleName cLocalGroup

    cLocalGroup LocalGroup1
    {
        Ensure = 'Present'
        GroupName = 'Group-1'
        Description = 'Created by the cLocalGroup DSC resource'
        Members = 'IIS APPPOOL\DefaultAppPool', 'NT AUTHORITY\IUSR'
    }

    cLocalGroup LocalGroup2
    {
        Ensure = 'Present'
        GroupName = 'Group-2'
        Description = 'Created by the cLocalGroup DSC resource'
        MembersToExclude = "$Env:UserDomain\Domain Users", 'Guest'
        MembersToInclude = "$Env:UserDomain\$Env:UserName", 'BUILTIN\Administrators'
    }
}

Sample_cLocalGroup -OutputPath "$Env:SystemDrive\Sample_cLocalGroup"

Start-DscConfiguration -Path "$Env:SystemDrive\Sample_cLocalGroup" -Force -Verbose -Wait

Get-DscConfiguration


```

