#This script automates the process of creating a training site. 
#Currently PS only supports the creation of modern sites.  
#You will have to manually create the site first then run this script. 


#EDIT THIS TO REFLECT STUDENT NAME AND URL FIRST!!!
$StudentName = "Mitzi Enciso" 
$StudentFriendlyURL = "MEnciso" 

$credentials = Get-Credential

#Connect to the site first by running connect-pnponline -url <your site> 
$TrainingSite = "https://memorialcare.sharepoint.com/sites/sharepoint/training/" + $StudentFriendlyURL
Connect-PnPOnline -Url $TrainingSite -Credentials $credentials

###########################################################################################

#get the web and context of the site
$web = Get-PnPWeb -Includes RoleAssignments
$context = Get-PnPContext

###########################################################################################

#set the Master Page
$MasterPageURL = "/sites/SharePoint/_catalogs/masterpage/MHS/MHSSystem.master"
$CustomMasterPageURL = "/sites/SharePoint/_catalogs/masterpage/MHS/MHSWorkGroupMasterPage.master"

Set-PnPMasterPage -MasterPageServerRelativeUrl $MasterPageURL -CustomMasterPageServerRelativeUrl $CustomMasterPageURL
Write-Host "Updated Master Page" -ForegroundColor DarkMagenta

###########################################################################################

#set the logo
$LogoURL = "/SiteAssets/WhiteDot.jpg"
Set-PnPWeb -SiteLogoUrl $LogoURL
Write-Host "Updated Logo to " $LogoURL -ForegroundColor Blue

###########################################################################################

#edit the home button to say 'Back to Training' in MH SiteLinks
Set-PnPListItem -List "MH SiteLinks" -Identity 1 -Values @{"Title" = "Back to Training"; "MHContactsOrder" = 1} 

#edit the view to have correct properties in MH SiteLinks
$view = Get-PnPView -List "MH SiteLinks" -Identity "All Links" 
$viewFields = $view.ViewFields

if(!($viewFields -contains "MHDepartmentUrl")) {
    $viewFields.Add("MHDepartmentUrl")
    Write-Host "Added MHDepartmentUrl" 
}
if(!($viewFields -contains "MHDeptLinkCategory")) {
    $viewFields.Add("MHDeptLinkCategory") 
}
if(!($viewFields -contains "MHContactsOrder")) {
    $viewFields.Add("MHContactsOrder")
}
$view.Update() 
$web.Context.ExecuteQuery() 
Write-Host "Updated MH SiteLinks" -ForegroundColor Blue

###########################################################################################

#set default owner to SharePoint Training
Set-PnPDefaultColumnValues -List "Documents" -Field "MHOwner" -Value ee2a031d-7f56-468d-a19c-e8e971ceb589
Write-Host "Updated default Owner to Documents" -ForegroundColor Magenta

###########################################################################################

#Update the permissions from Full Control to Site Admin 
foreach ($role in $web.RoleAssignments) {

    $context.Load($role.RoleDefinitionBindings)
    $context.Load($role.Member)
    $context.ExecuteQuery()

    if($role.Member.Title -like "*Owners*") {
    try {
            #get the role definitions
            $roleDefToAdd = $context.Web.RoleDefinitions.GetByName("Site Admin")
            $roleDefToRemove = $context.Web.RoleDefinitions.GetByName("Full Control")
    
            $role.RoleDefinitionBindings.Add($roleDefToAdd)
            $role.RoleDefinitionBindings.Remove($roleDefToRemove) 
            $role.Update()
            $context.ExecuteQuery() 

            Write-Host "Updated Owners group to Site Admin from Full Control" -ForegroundColor Cyan
        }
    catch {
            Write-Host "Permission already added." 
        }
    }
}
#Write-Host $role.Member.Title" "$role.RoleDefinitionBindings.Name

###########################################################################################

#Delete Calendar and Documents from Pages Library 
try { 
    Remove-PnPListItem -List "Pages" -Identity 2 -Force -Recycle -ErrorAction SilentlyContinue #Calendar 
    Remove-PnPListItem -List "Pages" -Identity 7 -Force -Recycle -ErrorAction SilentlyContinue #Documents   
}
catch {
    Write-Host "Pages already removed" 
}
Write-Host "Calendar and Document pages removed" 

###########################################################################################
Disconnect-PnPOnline
###########################################################################################

#Reconnect to the training site to add the user to the Online training List 
Connect-PnPOnline -Url "https://memorialcare.sharepoint.com/sites/sharepoint/training" -Credentials $credentials

$Ctx = Get-PnPContext

    $item = @{
        "Student_x0020_Name" = $StudentName;
        "URL" = $TrainingSite; 
    }

#Add student and put that student to variable
$student = Add-PnPListItem -List "Online Training Students" -Values $item

#Set Hyperlink field properties   
$Link = New-Object Microsoft.SharePoint.Client.FieldUrlValue
$Link.Url = $trainingSite
$Link.Description = $StudentName

#Update Hyperlink Field
$student["URL"] = [Microsoft.SharePoint.Client.FieldUrlValue]$Link
$student.Update()
$Ctx.ExecuteQuery()
Write-Host "Site is now ready for use. Remember to email user." -ForegroundColor Yellow 

Disconnect-PnPOnline
###########################################################################################