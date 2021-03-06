#Copyright (c) 2014, Unify Solutions Pty Ltd
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
#IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
#OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

### Written by Carol Wapshere, UNIFY Solutions
###
### Installs the pre-requisites for the Update-ReferringPolicy.ps1 script:
###   - Schema changes
###       o "ReferringPolicy" attribute type
###       o "Referring Policy" bindings for Set, WorkflowDefinition and EmailTemplate
###
###   - MPRs that grant Administrators access to change the new attribute:
###       o "Set Access Control: Administrators manage custom attributes"
###       o "Workflow Access Control: Administrators manage custom attributes"
###       o "EmailTemplate Access Control: Administrators manage custom attributes"
###     These MPRs may be renamed or removed, as long as an equivalent policy is put in their place.
###
###   - Search Scopes - adds the ReferringPolicy column to the following search scopes, if found:
###       o All Sets
###       o All Workflows
###       o Email Templates
###     Search Scope changes will not appear until the Portal has been reset.
### 
### Notes:
###  - Uses the FIMFunctions.ps1 functions library. Correct the path where it is called below.
###  - The script can be re-run - it will search for existing objects before creating, even if DisplayNames have been changed.
###  - Problems will occur if the following default sets have been renamed: "Administrators", "All Sets", "All Workflows", "All Email Templates"
###

. E:\scripts\FIMFunctions.ps1


### Extend the schema

# Attribute Type
$AttrObj = export-fimconfig -OnlyBaseResources -CustomConfig ("/AttributeTypeDescription[Name='ReferringPolicy']")
if (-not $AttrObj)
{
    write-host "Adding Attribute ReferringPolicy..."
    $ImportObject = CreateImportObject -ObjectType "AttributeTypeDescription"
    SetSingleValue $ImportObject "Name" "ReferringPolicy"
    SetSingleValue $ImportObject "DisplayName" "Referring Policy"
    SetSingleValue $ImportObject "Description" "Policy objects that use this object"
    SetSingleValue $ImportObject "DataType" "String"
    SetSingleValue $ImportObject "Multivalued" "true"
    $ImportObject.Changes
    $ImportObject | Import-FIMConfig

    $AttrObj = export-fimconfig -OnlyBaseResources -CustomConfig ("/AttributeTypeDescription[Name='ReferringPolicy']")
    if (-not $AttrObj) {Throw "Failed to create Attribute Type"}
}
else {write-host "Attribute Type already exists"}

$AttrObjID = $AttrObj.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

# Set Binding
$SetObjType = export-fimconfig -OnlyBaseResources -CustomConfig ("/ObjectTypeDescription[Name='Set']")
if (-not $SetObjType) {Throw "Failed to find an Object Type matching 'Set'"}
$SetObjID = $SetObjType.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

$SetBinding = export-fimconfig -OnlyBaseResources -CustomConfig ("/BindingDescription[BoundAttributeType='{0}' and BoundObjectType='{1}']" -f $AttrObjID,$SetObjID)
if (-not $SetBinding)
{
    write-host "Binding to Set object type..."
    $ImportObject = CreateImportObject -ObjectType "BindingDescription"
    SetSingleValue $ImportObject "DisplayName" "Referring Policy"
    SetSingleValue $ImportObject "Description" "Sets, Groups and MPRs that use this Set"
    SetSingleValue $ImportObject "BoundAttributeType" $AttrObj.ResourceManagementObject.ObjectIdentifier
    SetSingleValue $ImportObject "BoundObjectType" $SetObjType.ResourceManagementObject.ObjectIdentifier
    SetSingleValue $ImportObject "Required" "false"
    $ImportObject.Changes
    $ImportObject | Import-FIMConfig

    $SetBinding = export-fimconfig -OnlyBaseResources -CustomConfig ("/BindingDescription[BoundAttributeType='{0}' and BoundObjectType='{1}']" -f $AttrObjID,$SetObjID)
    if (-not $SetBinding) {Throw "Failed to create Binding"}
}
else {write-host "Set Binding already exists"}

# Workflow Binding
$WFObjType = export-fimconfig -OnlyBaseResources -CustomConfig ("/ObjectTypeDescription[Name='WorkflowDefinition']")
if (-not $WFObjType) {Throw "Failed to find an Object Type matching 'WorkflowDefinition'"}
$WFObjID = $WFObjType.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

$WFBinding = export-fimconfig -OnlyBaseResources -CustomConfig ("/BindingDescription[BoundAttributeType='{0}' and BoundObjectType='{1}']" -f $AttrObjID,$WFObjID)
if (-not $WFBinding)
{
    write-host "Binding to WorkflowDefinition object type..."
    $ImportObject = CreateImportObject -ObjectType "BindingDescription"
    SetSingleValue $ImportObject "DisplayName" "Referring Policy"
    SetSingleValue $ImportObject "Description" "MPRs that call this Workflow"
    SetSingleValue $ImportObject "BoundAttributeType" $AttrObj.ResourceManagementObject.ObjectIdentifier
    SetSingleValue $ImportObject "BoundObjectType" $WFObjType.ResourceManagementObject.ObjectIdentifier
    SetSingleValue $ImportObject "Required" "false"
    $ImportObject.Changes
    $ImportObject | Import-FIMConfig

    $WFBinding = export-fimconfig -OnlyBaseResources -CustomConfig ("/BindingDescription[BoundAttributeType='{0}' and BoundObjectType='{1}']" -f $AttrObjID,$WFObjID)
    if (-not $WFBinding) {Throw "Failed to create Binding"}
}
else {write-host "WorkflowDefinition Binding already exists"}

# Email Template Binding
$ETObjType = export-fimconfig -OnlyBaseResources -CustomConfig ("/ObjectTypeDescription[Name='EmailTemplate']")
if (-not $ETObjType) {Throw "Failed to find an Object Type matching 'EmailTemplate'"}
$ETObjID = $ETObjType.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

$ETBinding = export-fimconfig -OnlyBaseResources -CustomConfig ("/BindingDescription[BoundAttributeType='{0}' and BoundObjectType='{1}']" -f $AttrObjID,$ETObjID)
if (-not $ETBinding)
{
    write-host "Binding to EmailTemplate object type..."
    $ImportObject = CreateImportObject -ObjectType "BindingDescription"
    SetSingleValue $ImportObject "DisplayName" "Referring Policy"
    SetSingleValue $ImportObject "Description" "Workflows that use this Email Template"
    SetSingleValue $ImportObject "BoundAttributeType" $AttrObj.ResourceManagementObject.ObjectIdentifier
    SetSingleValue $ImportObject "BoundObjectType" $ETObjType.ResourceManagementObject.ObjectIdentifier
    SetSingleValue $ImportObject "Required" "false"
    $ImportObject.Changes
    $ImportObject | Import-FIMConfig

    $ETBinding = export-fimconfig -OnlyBaseResources -CustomConfig ("/BindingDescription[BoundAttributeType='{0}' and BoundObjectType='{1}']" -f $AttrObjID,$ETObjID)
    if (-not $ETBinding) {Throw "Failed to create Binding"}
}
else {write-host "EmailTemplate Binding already exists"}


### Create MPRs that grant the Administrators Set the rights to modfy the ReferringPolicy attribute

$AdminSet = Export-FIMConfig -OnlyBaseResources -CustomConfig "/Set[DisplayName='Administrators']"
if (-not $AdminSet) {Throw "Cannot find Administrators Set"}
$AdminSetID = $AdminSet.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

# MPR granting permission to update ReferringPolicy on Sets
$AllSetsSet = Export-FIMConfig -OnlyBaseResources -CustomConfig "/Set[DisplayName='All Sets']"
if (-not $AllSetsSet) {Throw "Cannot find the 'All Sets' set."}
$AllSetsSetID = $AllSetsSet.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

$SetMPR = Export-FIMConfig -OnlyBaseResources -CustomConfig ("/ManagementPolicyRule[PrincipalSet='{0}' and ResourceCurrentSet='{1}' and ActionParameter='ReferringPolicy' and ActionType='Modify']" -f $AdminSetID,$AllSetsSetID)

if (-not $SetMPR)
{
    write-host "Creating policy 'Set Access Control: Administrators manage custom attributes'"
    $ImportObject = CreateImportObject -ObjectType "ManagementPolicyRule"
    SetSingleValue $ImportObject "ManagementPolicyRuleType" "Request"
    SetSingleValue $ImportObject "DisplayName" "Set Access Control: Administrators manage custom attributes"
    SetSingleValue $ImportObject "Description" "Grants access to modify custom attributes."
    AddMultiValue  $ImportObject "ActionParameter" "ReferringPolicy"
    AddMultiValue  $ImportObject "ActionType" "Add"
    AddMultiValue  $ImportObject "ActionType" "Remove"
    AddMultiValue  $ImportObject "ActionType" "Read"
    SetSingleValue $ImportObject "GrantRight" "true"
    SetSingleValue $ImportObject "ResourceCurrentSet" $AllSetsSetID
    SetSingleValue $ImportObject "ResourceFinalSet" $AllSetsSetID
    SetSingleValue $ImportObject "PrincipalSet" $AdminSetID
    SetSingleValue $ImportObject "Disabled" "False"
    $ImportObject.Changes
    $ImportObject | Import-FIMConfig
}
else {write-host "A policy granting Administrators rights to change ReferringPolicy on Sets already exists."}

# MPR granting permission to update ReferringPolicy on WorkflowDefinitions
$AllWFSet = Export-FIMConfig -OnlyBaseResources -CustomConfig "/Set[DisplayName='All Workflows']"
if (-not $AllWFSet) {Throw "Cannot find the 'All Workflows' set."}
$AllWFSetID = $AllWFSet.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

$WFMPR = Export-FIMConfig -OnlyBaseResources -CustomConfig ("/ManagementPolicyRule[PrincipalSet='{0}' and ResourceCurrentSet='{1}' and ActionParameter='ReferringPolicy' and ActionType='Modify']" -f $AdminSetID,$AllWFSetID)

if (-not $WFMPR)
{
    write-host "Creating policy 'Workflow Access Control: Administrators manage custom attributes'"
    $ImportObject = CreateImportObject -ObjectType "ManagementPolicyRule"
    SetSingleValue $ImportObject "ManagementPolicyRuleType" "Request"
    SetSingleValue $ImportObject "DisplayName" "Workflow Access Control: Administrators manage custom attributes"
    SetSingleValue $ImportObject "Description" "Grants access to modify custom attributes."
    AddMultiValue  $ImportObject "ActionParameter" "ReferringPolicy"
    AddMultiValue  $ImportObject "ActionType" "Add"
    AddMultiValue  $ImportObject "ActionType" "Remove"
    AddMultiValue  $ImportObject "ActionType" "Read"
    SetSingleValue $ImportObject "GrantRight" "true"
    SetSingleValue $ImportObject "ResourceCurrentSet" $AllWFSetID
    SetSingleValue $ImportObject "ResourceFinalSet" $AllWFSetID
    SetSingleValue $ImportObject "PrincipalSet" $AdminSetID
    SetSingleValue $ImportObject "Disabled" "False"
    $ImportObject.Changes
    $ImportObject | Import-FIMConfig
}
else {write-host "A policy granting Administrators rights to change ReferringPolicy on Workflows already exists."}

# MPR granting permission to update ReferringPolicy on Email Templates
$AllETSet = Export-FIMConfig -OnlyBaseResources -CustomConfig "/Set[DisplayName='All Email Templates']"
if (-not $AllETSet) {Throw "Cannot find the 'All Email Templates' set."}
$AllETSetID = $AllETSet.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")

$ETMPR = Export-FIMConfig -OnlyBaseResources -CustomConfig ("/ManagementPolicyRule[PrincipalSet='{0}' and ResourceCurrentSet='{1}' and ActionParameter='ReferringPolicy' and ActionType='Modify']" -f $AdminSetID,$AllETSetID)

if (-not $ETMPR)
{
    write-host "Creating policy 'EmailTemplate Access Control: Administrators manage custom attributes'"
    $ImportObject = CreateImportObject -ObjectType "ManagementPolicyRule"
    SetSingleValue $ImportObject "ManagementPolicyRuleType" "Request"
    SetSingleValue $ImportObject "DisplayName" "EmailTemplate Access Control: Administrators manage custom attributes"
    SetSingleValue $ImportObject "Description" "Grants access to modify custom attributes."
    AddMultiValue  $ImportObject "ActionParameter" "ReferringPolicy"
    AddMultiValue  $ImportObject "ActionType" "Add"
    AddMultiValue  $ImportObject "ActionType" "Remove"
    AddMultiValue  $ImportObject "ActionType" "Read"
    SetSingleValue $ImportObject "GrantRight" "true"
    SetSingleValue $ImportObject "ResourceCurrentSet" $AllETSetID
    SetSingleValue $ImportObject "ResourceFinalSet" $AllETSetID
    SetSingleValue $ImportObject "PrincipalSet" $AdminSetID
    SetSingleValue $ImportObject "Disabled" "False"
    $ImportObject.Changes
    $ImportObject | Import-FIMConfig
}
else {write-host "A policy granting Administrators rights to change ReferringPolicy on Email Templates already exists."}


### Search Scopes

# All Sets
$SetSS = Export-FIMConfig -OnlyBaseResources -CustomConfig "/SearchScopeConfiguration[DisplayName='All Sets' and SearchScopeResultObjectType='Set']"
if ($SetSS)
{
    $Columns = ($SetSS.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'SearchScopeColumn'}).Value
    if (-not $Columns.contains("ReferringPolicy"))
    {
        write-host "Updating 'All Sets' search scope'"
        $Columns = $Columns + ";ReferringPolicy"
        $ImportObject = ModifyImportObject -TargetIdentifier $SetSS.ResourceManagementObject.ObjectIdentifier -ObjectType "SearchScopeConfiguration"
        SetSingleValue $ImportObject "SearchScopeColumn" $Columns
        $ImportObject.Changes
        $ImportObject | Import-FIMConfig
    }
    else {write-host "'All Sets' search scope already updated."}
}
else {write-host "No search scope found named 'All Sets' - skipping."}

# All Workflows
$WFSS = Export-FIMConfig -OnlyBaseResources -CustomConfig "/SearchScopeConfiguration[DisplayName='All Workflows' and SearchScopeResultObjectType='WorkflowDefinition']"
if ($WFSS)
{
    $Columns = ($WFSS.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'SearchScopeColumn'}).Value
    if (-not $Columns.contains("ReferringPolicy"))
    {
        write-host "Updating 'All Workflows' search scope'"
        $Columns = $Columns + ";ReferringPolicy"
        $ImportObject = ModifyImportObject -TargetIdentifier $WFSS.ResourceManagementObject.ObjectIdentifier -ObjectType "SearchScopeConfiguration"
        SetSingleValue $ImportObject "SearchScopeColumn" $Columns
        $ImportObject.Changes
        $ImportObject | Import-FIMConfig
    }
    else {write-host "'All Workflows' search scope already updated."}
}
else {write-host "No search scope found named 'All Workflows' - skipping."}

# Email Templates
$ETSS = Export-FIMConfig -OnlyBaseResources -CustomConfig "/SearchScopeConfiguration[DisplayName='Email Templates' and SearchScopeResultObjectType='EmailTemplate']"
if ($ETSS)
{
    $Columns = ($ETSS.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'SearchScopeColumn'}).Value
    if (-not $Columns.contains("ReferringPolicy"))
    {
        write-host "Updating 'Email Templates' search scope'"
        $Columns = $Columns + ";ReferringPolicy"
        $ImportObject = ModifyImportObject -TargetIdentifier $ETSS.ResourceManagementObject.ObjectIdentifier -ObjectType "SearchScopeConfiguration"
        SetSingleValue $ImportObject "SearchScopeColumn" $Columns
        $ImportObject.Changes
        $ImportObject | Import-FIMConfig
    }
    else {write-host "'Email Templates' search scope already updated."}
}
else {write-host "No search scope found named 'Email Templates' - skipping."}


