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

###
### Update-ReferringPolicy.ps1
### Written by Carol Wapshere, UNIFY Solutions
###
### Updates the ReferringPolicy attribute on the following object types with a list of the names of Policy objects that use it:
###   - Sets: Both MPRs and Sets where this Set is used as part of the criteria,
###   - Workflow Definitions: A list of MPRs that call the workflow,
###   - Email Templates: A list of workflows that use it.
### 
### Notes:
###  - Uses the FIMFunctions.ps1 functions library. Correct the path where it is called below.
###  - Requires changes to schema, policy and search scopes - see "Install-ReferringPolicy.ps1".
###  - Use Event Broker to run the script on a schedule as required. In a properly managed environment it should only be necessary to run on Dev then migrate the changes.
###  - Only searches on ObjectID so custom activities specifying a policy object display name (such as an email template) won't be detected.
###
### Changes:
###   18/02/2014 - Changed to a multivalued String attribute for ReferringPolicy instead of Reference. The Reference version causes loop errors
###                when running the SyncPolicy script during a config migration.

. E:\scripts\FIMFunctions.ps1


$ObjectNames = @{} # DisplayName of all exported objects
$CurrValue = @{}  # Current values for ReferringPolicy


# Get all Sets
$Sets = export-fimconfig -customconfig ("/Set") -OnlyBaseResources
$hashSets = @{}
$SetGUIDs = @()
foreach ($obj in $Sets)
{
    $GUID = $obj.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")
    $hashSets.Add($GUID,@())
    $SetGUIDs += $GUID
    $DisplayName = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'DisplayName'}).Value
    $ObjectNames.Add($GUID,$DisplayName)
    $ReferringPolicy = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'ReferringPolicy'}).Values
    $CurrValue.Add($GUID,$ReferringPolicy)
}

# Find Sets that refer to other Sets
foreach ($obj in $Sets)
{
    $GUID = $obj.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")
    $Filter = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'Filter'}).Value
    foreach ($setID in $SetGUIDs)
    {
        if ($Filter -and $Filter.contains($setID)) {$hashSets.($setID) += $GUID}
    }
}

# Find Groups that refer to Sets
$Groups = export-fimconfig -customconfig ("/Group") -OnlyBaseResources
if ($Groups) {foreach ($obj in $Groups)
{
    $GUID = $obj.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")
    $Filter = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'Filter'}).Value
    foreach ($setID in $SetGUIDs)
    {
        if ($Filter -and $Filter.contains($setID)) {$hashSets.($setID) += $GUID}
    }
}}


# Get all Email Templates
$ETs = export-fimconfig -customconfig ("/EmailTemplate") -OnlyBaseResources
$hashETs = @{}
$ETGuids = @()
foreach ($obj in $ETs)
{
    $GUID = $obj.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")
    $hashETs.Add($GUID,@())
    $ETGuids += $GUID
    $DisplayName = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'DisplayName'}).Value
    $ObjectNames.Add($GUID,$DisplayName)
    $ReferringPolicy = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'ReferringPolicy'}).Values
    $CurrValue.Add($GUID,$ReferringPolicy)
}


# Get all Workflows and which Email Templates they use
$WFs = export-fimconfig -customconfig ("/WorkflowDefinition") -OnlyBaseResources
$hashWFs = @{}
foreach ($obj in $WFs)
{
    $GUID = $obj.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")
    $hashWFs.Add($GUID,@())
    $DisplayName = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'DisplayName'}).Value
    $ObjectNames.Add($GUID,$DisplayName)
    $ReferringPolicy = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'ReferringPolicy'}).Values
    $CurrValue.Add($GUID,$ReferringPolicy)
    $XOML = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'XOML'}).Value
    foreach ($ET in $ETGuids)
    {
        if ($XOML.Contains($ET) -and ($hashETs.($ET) -notcontains $GUID))
        {
            $hashETs.($ET) += $GUID
        }      
    }
}



# Get all MPRs and find which Sets and Workflows they use
$MPRs = export-fimconfig -customconfig ("/ManagementPolicyRule") -OnlyBaseResources

foreach ($obj in $MPRs)
{
    $MPRID = $obj.ResourceManagementObject.ObjectIdentifier.Replace("urn:uuid:","")
    $DisplayName = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'DisplayName'}).Value
    $ObjectNames.Add($MPRID,$DisplayName)
    $PrincipalSet = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'PrincipalSet'}).Value
    $ResourceCurrentSet = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'ResourceCurrentSet'}).Value
    $ResourceFinalSet = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'ResourceFinalSet'}).Value
    $ActionWorkflowDefinition = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'ActionWorkflowDefinition'}).Values
    $AuthorizationWorkflowDefinition = ($obj.ResourceManagementObject.ResourceManagementAttributes | where {$_.AttributeName -eq 'AuthorizationWorkflowDefinition'}).Values

    if ($PrincipalSet)
    {
        $Guid = $PrincipalSet.Replace("urn:uuid:","")
        if ($hashSets.Item($Guid) -notcontains $MPRID) {$hashSets.Item($Guid) += $MPRID}
    }
    if ($ResourceCurrentSet)
    {
        $Guid = $ResourceCurrentSet.Replace("urn:uuid:","")
        if ($hashSets.Item($Guid) -notcontains $MPRID) {$hashSets.Item($Guid) += $MPRID}
    }
    if ($ResourceFinalSet)
    {
        $Guid = $ResourceFinalSet.Replace("urn:uuid:","")
        if ($hashSets.Item($Guid) -notcontains $MPRID) {$hashSets.Item($Guid) += $MPRID}
    }
    if ($ActionWorkflowDefinition)
    {
        foreach ($WF in $ActionWorkflowDefinition)
        {
            $Guid = $WF.Replace("urn:uuid:","")
            if ($hashWFs.Item($Guid) -notcontains $MPRID) {$hashWFs.Item($Guid) += $MPRID}
        }
    }
    if ($AuthorizationWorkflowDefinition)
    {
        foreach ($WF in $AuthorizationWorkflowDefinition)
        {
            $Guid = $WF.Replace("urn:uuid:","")
            if ($hashWFs.Item($Guid) -notcontains $MPRID) {$hashWFs.Item($Guid) += $MPRID}
        }
    }
}


# Update Workflows
foreach ($WFID in $hashWFs.Keys)
{  
    $ImportObject = ModifyImportObject -TargetIdentifier $WFID -ObjectType "WorkflowDefinition"
    if ($hashWFs.($WFID) -and $hashWFs.($WFID).count -gt 0) 
    {
        $arrPolicyNames = @()
        foreach ($GUID in $hashWFs.($WFID)) {$arrPolicyNames += $ObjectNames.($GUID)}
        
        foreach ($Name in $arrPolicyNames)
        {
            if ($CurrValue.($WFID) -notcontains $Name) 
            {
                AddMultiValue $ImportObject "ReferringPolicy" $Name
            }
        }
        foreach ($Name in $CurrValue.($WFID))
        {
            if ($arrPolicyNames -notcontains $Name) 
            {
                RemoveMultiValue $ImportObject "ReferringPolicy" $Name
            }
        }
    }
    if ($ImportObject.Changes)
    {
        $ImportObject.Changes
        import-fimconfig -importObject $ImportObject
    }
}

# Update Sets
foreach ($SetID in $hashSets.Keys)
{   
    $ImportObject = ModifyImportObject -TargetIdentifier $SetID -ObjectType "Set"
    if ($hashSets.($SetID) -and $hashSets.($SetID).count -gt 0) 
    {
        $arrPolicyNames = @()
        foreach ($GUID in $hashSets.($SetID)) {$arrPolicyNames += $ObjectNames.($GUID)}
        
        foreach ($Name in $arrPolicyNames)
        {
            if ($CurrValue.($SetID) -notcontains $Name) 
            {
                AddMultiValue $ImportObject "ReferringPolicy" $Name
            }
        }
        foreach ($Name in $CurrValue.($SetID))
        {
            if ($arrPolicyNames -notcontains $Name) 
            {
                RemoveMultiValue $ImportObject "ReferringPolicy" $Name
            }
        }
    }
    if ($ImportObject.Changes)
    {
        $ImportObject.Changes
        import-fimconfig -importObject $ImportObject
    }
}

# Update Email Templates
foreach ($ETID in $hashETs.Keys)
{   
    $ImportObject = ModifyImportObject -TargetIdentifier $ETID -ObjectType "Set"
    if ($hashETs.($ETID) -and $hashETs.($ETID).count -gt 0) 
    {
        $arrPolicyNames = @()
        foreach ($GUID in $hashETs.($ETID)) {$arrPolicyNames += $ObjectNames.($GUID)}
        
        foreach ($Name in $arrPolicyNames)
        {
            if ($CurrValue.($ETID) -notcontains $Name) 
            {
                AddMultiValue $ImportObject "ReferringPolicy" $Name
            }
        }
        foreach ($Name in $CurrValue.($ETID))
        {
            if ($arrPolicyNames -notcontains $Name) 
            {
                RemoveMultiValue $ImportObject "ReferringPolicy" $Name
            }
        }
    }
    if ($ImportObject.Changes)
   {
        $ImportObject.Changes
        import-fimconfig -importObject $ImportObject
    }
}
