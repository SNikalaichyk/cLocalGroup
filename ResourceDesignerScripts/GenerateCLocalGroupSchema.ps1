
#requires -Version 4.0 -Modules xDSCResourceDesigner

$ModuleName = 'cLocalGroup'
$ResourceName = 'cLocalGroup'

$DscResourceProperties =  @(
    (New-xDscResourceProperty -Type String -Attribute Write -Name Ensure -ValidateSet 'Absent', 'Present' -Description 'Indicates if the group exists. Set this property to Absent to ensure that the group does not exist. Setting it to Present (the default value) ensures that the group exists.')
    (New-xDscResourceProperty -Type String -Attribute Key -Name GroupName -Description 'Indicates the name of the group.'),
    (New-xDscResourceProperty -Type String -Attribute Write -Name Description -Description 'Indicates the description of the group.'),
    (New-xDscResourceProperty -Type String[] -Attribute Write -Name Members -Description 'Indicates that you want to ensure these members form the group.'),
    (New-xDscResourceProperty -Type String[] -Attribute Write -Name MembersToExclude -Description 'Indicates the users who you want ensure are not members of this group.'),
    (New-xDscResourceProperty -Type String[] -Attribute Write -Name MembersToInclude -Description 'Indicates the users who you want to ensure are members of the group.')
)

New-xDscResource -Name $ResourceName -ModuleName $ModuleName -Property $DscResourceProperties -Verbose 

