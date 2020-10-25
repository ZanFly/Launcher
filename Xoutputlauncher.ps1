param([switch]$Elevated)

# Programnma di automatizzazione apertura xoutput, 
# riconoscimento del PID xoutput.exe ed inserimento nella
# chiave di registro whitelist di hidguardian del PID
# Script by Zander

# Chiusura immediata finestra console (DA FAR DIVENTARE COMMENTO IN CASO DI DEBUG)

$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $t -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)



#Permessi amministrativi

function Check-Admin {
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
if ((Check-Admin) -eq $false)  {
if ($elevated)
{
# could not elevate, quit
}
 
else {
 
Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}
exit
}


#Creazione chiave Whitelist
$PresenzaChiave = Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\HidGuardian\Parameters\Whitelist'
if ($PresenzaChiave -eq "False") {}
else {
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HidGuardian\Parameters\" -name "Whitelist"  | Out-Null
}

# apertura Xoutput
Start-Process "$PSScriptRoot\Xoutput.exe" -WindowStyle Minimized
Start-Sleep 3

# Creare le  variabili:
$XPID = "0"
$XPidOld = "0"

# cnoscere il PID di Xoutput
$XPID = (Get-Process -name XOutput).ID


## conoscere la chiave attualmente presente e modificarla in base al risultato

# conoscere la chiave:
$XPidOld = Get-Childitem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HidGuardian\Parameters\Whitelist\*" -name

#Se gia avviato xoptput e chiave corretta comunica che è gia attiva la whitelist
if ($XPID -eq $XPidOld) {
New-BurntToastNotification -Text "Xoutput", 'XInput già avviato!' -AppLogo C:\XOutput\icon.png
exit}

# Verificare esistenza chiave e quindi modificarla, altrimenti crearla
if ($XPidOld -eq $null) { New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HidGuardian\Parameters\Whitelist" -name $XPID  | Out-Null} else 
{
Rename-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HidGuardian\Parameters\Whitelist\$XPidOld" $XPID | Out-Null
}
$OK='Avviato con PID:',$XPID
New-BurntToastNotification -Text "XInput", $OK -AppLogo C:\XOutput\icon.png
exit
