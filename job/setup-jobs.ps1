$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptFile =  "$scriptRoot\run-all-in-one-with-es.ps1"
$startUpJobParams = @("$scriptRoot", 0, 1)
$reIndexJobParams = @("$scriptRoot", 1, 0)

$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Trigger $trigger -Name TracingPoC -FilePath $scriptFile -ArgumentList $startUpJobParams

$trigger = New-JobTrigger -Daily -At "4:00 AM" -DaysInterval 1
Register-ScheduledJob -Trigger $trigger -Name ReIndexDependencies -FilePath $scriptFile -ArgumentList $reIndexJobParams