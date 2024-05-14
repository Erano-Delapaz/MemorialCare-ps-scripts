#Load SharePoint Online CSOM Assemblies
#Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
#Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#[system.reflection.assembly]::loadwithpartialname("Microsoft.SharePoint.Client")
#[system.reflection.assembly]::loadwithpartialname("Microsoft.SharePoint.Client.Runtime")

#Function to Enable Feature in SharePoint Online
Function Enable-SPOFeature
{
    param ($SiteCollURL,$UserName,$Password,$FeatureGuid)
    Try
    {    
        #Setup the context
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteCollURL)
        $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $Password)
        $Ctx.Credentials = $Credentials
        $Site=$Ctx.Site
 
        #Check the Feature Status
        $FeatureStatus =  $Site.Features.GetById($FeatureGuid)
        $FeatureStatus.Retrieve("DefinitionId")
        $Ctx.Load($FeatureStatus)
        $Ctx.ExecuteQuery()
 
        #sharepoint online activate feature using powershell (if its not enabled already)
        if($FeatureStatus.DefinitionId -eq $null)
        {
            Write-Host "Enabling Feature $FeatureGuid..." -ForegroundColor Yellow
            $Site.Features.Add($FeatureGuid, $true, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None) | Out-Null
            $Ctx.ExecuteQuery()
            Write-Host "Feature Enabled on site $SiteCollURL!" -ForegroundColor Green
        }
        else
        {
            Write-host "Feature is Already Active on the Site collection!" -ForegroundColor Red
        }
    }
    Catch
    {
        write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
    }
}
  
#Parameters to Activate Feature
$SiteCollURL = "https://memorialcare.sharepoint.com/sites/07a"
$Credentials = Get-Credential
$UserName = $Credentials.UserName
$Password = $Credentials.Password
$FeatureGuid= [System.Guid] ("7c637b23-06c4-472d-9a9a-7c175762c5c4") #Publishing Feature


$SecurePassword= ConvertTo-SecureString $Password -asplaintext -force 
 
#sharepoint online enable feature powershell
Enable-SPOFeature -SiteCollURL $SiteCollURL -UserName $UserName -Password $Password -FeatureGuid $FeatureGuid
