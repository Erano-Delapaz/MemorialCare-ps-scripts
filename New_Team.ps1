#This script automates the process of creating a Team. It also addes a primary 
#and secondary owner. It also adds them as members. 

$Credential = Get-Credential
Write-Host "Creating Team..." -ForegroundColor Yellow
Connect-MicrosoftTeams -Credential $Credential

#################################################################
#EDIT THESE ARGUMENTS PRIOR TO RUNNING THE SCRIPT

#choices: LBMC/MCWHLB, MCMF, MCSS, OCMC, SMC 
$Entity = "MCSS" 

#choices: AFF, Cedars, LBMC/MCWHLB, MCMF, MCSHP, MCSS, OCMC, SMC 
$PrimaryCampus = "MCSS" 

$NameOfTeam = "IS VP Huddle" 

$MailNickName = "MCSS_IS_VP_Huddle" 

#in the form of an email address
$PrimaryOwner = "ehalbasch@memorialcare.org" 

#in the form of an email address
$SecondaryOwner = "sbeal@memorialcare.org" 

#################################################################

$DisplayName = $PrimaryCampus + " " + $NameOfTeam

$group = New-Team -MailNickName $MailNickName -DisplayName $DisplayName -Visibility "private" -Owner $PrimaryOwner

Add-TeamUser -GroupId $group.GroupID -User $PrimaryOwner -Role "Owner"
Add-TeamUser -GroupId $group.GroupID -User $PrimaryOwner -Role "Member"
Add-TeamUser -GroupId $group.GroupID -User $SecondaryOwner -Role "Owner" 
Add-TeamUser -GroupId $group.GroupID -User $SecondaryOwner -Role "Member"

Write-Host "Team " $DisplayName " created. Don't forget to email users." -ForegroundColor Yellow 
