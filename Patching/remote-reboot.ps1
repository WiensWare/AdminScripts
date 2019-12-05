# Schedules a task on a remote computer to reboot at a specified time.

$computername = Read-Host "Enter computer name to reboot" 
[DateTime] $when = "11:55pm"

Invoke-Command -ScriptBlock { param ( $when )
    $trigger = New-ScheduledTaskTrigger -at $when -Once
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "Restart-Computer -force"
    $principal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId "LOCALSERVICE" -LogonType ServiceAccount
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
    $scheduled = Register-ScheduledTask -TaskName "Reboot Computer" -InputObject $task -Force
} -ComputerName $computername -ArgumentList $when
