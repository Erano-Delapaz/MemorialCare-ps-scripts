#This script searches all content editor webparts for a keyword that you choose. The keyword can
#be edited at ~line 46. It will recursively call all sites and subsites of the root site. It will 
#output a report to the file path that you choose in CSV format. 
$rootUrl = "https://memorialcare.sharepoint.com/"

#Adding Header to the Export CSV File 
$filePath = "C:\Users\edelapaz\Documents\Solutions\PowerShell\PagesContainingMHSSF.csv" 
$headerLink = $headerLine = 'Title' + ',' + 'Url' + ',' + 'Location' 
Add-Content $filepath $headerLine

$credentials = Get-Credential



function htmlParser($url) {
    Connect-PnPOnline -Url $url -Credentials $credentials

    Write-Host "Retrieving from..." $url -ForegroundColor Yellow
    
    try { 
        $pages = Get-PnPListItem -List "Pages" -ErrorAction Stop
    }
    catch [System.NullReferenceException] {
        Write-Host "Couldn't find the 'Pages' Library for " $url -ForegroundColor Red
        $pages = $null
    }
    catch {
        "An error has occurred." 
    }

    foreach($page in $pages) {
        
        #Write-Progress -Id 0 $page["Title"] #Displays status bar
        Write-Host "PAGE: " $page["Title"] -ForegroundColor Cyan
        $pageHTML = New-Object -ComObject "HTMLFile" 
        $pageHTML.IHTMLDocument2_write($page["PublishingPageContent"])
        $itemURL = $pageHTML.all.tags("a") | % ie8_attributes | where {$_.nodeName -like "href"} | % textContent 
        
        $itemURL

        #location of where to find the link 
        $locationUrl = "https://memorialcare.sharepoint.com" + $page["FileRef"]  
        
        #Output to CSV File, COMMENT OUT IF BLOCK IF YOU WANT TO UNFILTER!!!
        #EDIT THE IF STATEMENT FOR THE KEYWORD YOU'RE SEARCHING FOR. Include asterisks*
        if($itemURL -like "*google*") {
        $pageInfoOutputLine = $page["Title"] + "," + $itemURL + "," + $locationUrl
        Add-Content $filepath $pageInfoOutputLine
        }

        Write-Host "------------------------------------------------------------------`n"        
    }

    #Recursive call to function to get links in SubSites
        $subSites = Get-PnPSubWebs 
        foreach($site in $subSites) {
            try {
                #Write-Progress -Id 1 -ParentId 0  $site.Url #Displays status bar
                Write-Host "["$site.Url"] is a subsite of [$url]" -ForegroundColor DarkMagenta
                $currentUrl = $site.Url
            
                if($subSites.count -gt 0) { 
                    htmlParser -url $currentUrl
                }
            }
            catch {
                Write-Host "An error occurred fetching Subsite."-ForegroundColor Red
            }
        }
}

#This part includes a list of site collection urls contained in a plain text file "urls.txt". I will include this in the PowerShell Scripts Doc Lib
#Edit this path to include where you saved the urls.txt file. 
Get-Content -Path "C:\Users\edelapaz\Documents\Solutions\PowerShell\urls.txt" | ForEach-Object { htmlParser($_) }
#htmlParser($rootUrl)  
Disconnect-PnPOnline
