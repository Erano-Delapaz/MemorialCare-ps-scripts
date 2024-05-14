#This script searches a keyword specified by the user in MHSiteLinks and MH QuickLinks. It will return all links that contain the keyword
#as well as what site they live in within SharePoint. 

$rootUrl = "https://memorialcare.sharepoint.com/"
$credentials = Get-Credential
$currentCount = 0

#Adding Header to the Export CSV File. EDIT THIS FILEPATH TO THE LOCATION TO WHERE YOU WANT TO SAVE! 
$filepath = "C:\Users\edelapaz\Documents\Solutions\PowerShell\Great_Catch.csv" 
$headerLine = 'Title' + ',' + 'Url' + ',' + 'Location' 
Add-Content $filepath $headerLine


#Edit this keyword to whatever it is you're searching for
$keyword = "*" + "16455" + "*" 
Write-Host "Keyword we're searching for is: " $keyword -ForegroundColor Yellow

#This function recursively checks the MH SiteLinks and MHQuickLinks on every site and subsite. It returns the number
#of hits against the keyword searched. Gets stored into an Array of $currentCounts
function Get-AllUrlAndSubUrl($url) { #,$count) {
    
    Connect-PnPOnline -Url $url -Credentials $credentials
    
    try {
        #Get-PnPListItem "MH SiteLinks" 
        $MHSiteLinkItems = Get-PnPListItem -List "MH SiteLinks" -ErrorAction Stop
    }
    catch [System.NullReferenceException] {
        Write-Host "`t"$url"/Lists/MHWorkGroupSiteLinks/AllItems.aspx not found!" -ForegroundColor White -BackgroundColor Red
        $MHSiteLinkItems = $null
    }
    catch {
        "An error occurred." 
    }
    
    #Outputs to console and writes to the CSV File 
    Write-Host "MH SiteLinks for: " $url -BackgroundColor Cyan
    foreach($item in $MHSiteLinkItems) { 
        if(($item["MHDepartmentUrl"]).Url -like $keyword) {
        Write-Host "`t" ($item["MHDepartmentUrl"]).Url
        $MHSiteLinksOutputLine = $item["Title"]+','+($item["MHDepartmentUrl"]).Url + ',' + $url
        Add-Content $filepath $MHSiteLinksOutputLine
        $count++
        }
    } 

    try {
    #Get-PnPListItem "MHQuickLInks" 
    $MHQuickLinkItems = Get-PnPListItem -List "MHQuickLinks" -ErrorAction Stop 
    }
    catch [System.NullReferenceException] {
        Write-Host "`t"$url"/Lists/MHQuickLinks/AllItems.aspx not found!" -ForegroundColor White -BackgroundColor Red
        $MHQuickLinkItems = $null
    }
    catch {
        Write-Host "An error occurred." -ForegroundColor Red
    }
    
    #Outputs to console and writes to the CSV File 
    Write-Host "MHQuickLinks for: " $url -BackgroundColor DarkCyan
    foreach($item in $MHQuickLinkItems) { 
        if(($item["URL"]).Url -like $keyword) {
        Write-Host "`t" ($item["URL"]).Url
        $MHQuickLinksOutputLine = $item["URL"].Description+','+($item["URL"]).Url + ',' + $url
        Add-Content $filepath $MHQuickLinksOutputLine
        $count++
        }
    } 

    #Recursive call to function to get links in SubSites
    $subSites = Get-PnPSubWebs
    foreach($site in $subSites) {
        try {
            Write-Host "["$site.Url"] is a subsite of [$url]" -ForegroundColor DarkMagenta
            $currentUrl = $site.Url
            
            if($subSites.count -gt 0) { 
                Get-AllUrlAndSubUrl -url $currentUrl
            }
        }
        catch {
            Write-Host "An error occurred fetching Subsite."-ForegroundColor Red
        }
    }
    return $count
}

Get-Content -Path "C:\Users\edelapaz\Documents\Solutions\PowerShell\urls.txt" | ForEach-Object { Get-AllUrlAndSubUrl($_) }


#This calls our recursive function as well as updates the current hit count
#$currentCount = Get-AllUrlAndSubUrl -url $rootUrl -count $currentCount

#calculates the sum of all recursive counts and displays the final result. Uncomment the block below if you want the count
#$countSum = 0
#$currentCount | foreach{ $countSum += $_ } 
#Write-Host "Current Count: " $countSum

Disconnect-PnPOnline 