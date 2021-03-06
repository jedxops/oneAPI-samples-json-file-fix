# Copyright (c) 2020, Intel Corporation. All rights reserved.<BR>
# SPDX-License-Identifier: BSD-2-Clause-Patent


#Following code taken off https://docs.microsoft.com/en-us/archive/blogs/virtual_pc_guy/a-self-elevating-powershell-script
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
 # Check to see if we are currently running "as Administrator"
 if (-Not $myWindowsPrincipal.IsInRole($adminRole))
    {
    # We are not running "as Administrator" - so relaunch as administrator
    
    # Create a new process object that starts PowerShell
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    
    # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition + $args;
    
    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";
    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);    
    # Exit from the current, unelevated, process
    exit
    }


Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Title = 'Select EFI Application to flash'
}
$null = $FileBrowser.ShowDialog()

$EFI = $FileBrowser.FileName;

if ([string]::IsNullOrWhitespace($EFI)) {
    Write-Error "Error: no file selected"
    exit
} 
$Results = Get-Disk |
Where-Object BusType -eq USB |
Out-GridView -Title 'Select USB Drive to Format' -OutputMode Single |
Clear-Disk -RemoveData -PassThru |
New-Partition -UseMaximumSize -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -AssignDriveLetter |
Format-Volume -NewFileSystemLabel "EFI" -FileSystem FAT32 -Force

if ([string]::IsNullOrWhitespace($Results.DriveLetter)) {
    Write-Error "Error: no file selected"
    exit
} 
$USBDrive = ($Results.DriveLetter + ':\')

$RelativePath = "\\EFI\\Boot"
$DestPath = $USBDrive + $RelativePath
New-Item -ItemType Directory -Path $DestPath -Force
Copy-Item $EFI -Destination $DestPath\\bootx64.efi
if(-not $?) {
    Write-Warning "Copy Failed"
}
else {
    Write-Host "Operation has Completed Successfully"
}

# SIG # Begin signature block
# MIIfZQYJKoZIhvcNAQcCoIIfVjCCH1ICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDsfhbAQztu4CX8
# Idbfo0oY+iGN5brAUXdHD8z4Qvppi6CCDTkwggXoMIID0KADAgECAhNWAAAJIdwC
# 4/0t9Fa0AAAAAAkhMA0GCSqGSIb3DQEBCwUAMHMxCzAJBgNVBAYTAlVTMQswCQYD
# VQQIEwJDQTEUMBIGA1UEBxMLU2FudGEgQ2xhcmExGjAYBgNVBAoTEUludGVsIENv
# cnBvcmF0aW9uMSUwIwYDVQQDExxJbnRlbCBFeHRlcm5hbCBJc3N1aW5nIENBIDdC
# MB4XDTE4MTIxOTA5MjA1MVoXDTIwMTIxODA5MjA1MVowfTELMAkGA1UEBhMCVVMx
# CzAJBgNVBAgTAkNBMRQwEgYDVQQHEwtTYW50YSBDbGFyYTEaMBgGA1UEChMRSW50
# ZWwgQ29ycG9yYXRpb24xLzAtBgNVBAMTJkludGVsKFIpIFNvZnR3YXJlIERldmVs
# b3BtZW50IFByb2R1Y3RzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# yb/NhyZN/3zLWQsssxL/Mfqd6DNJQ+9X3BUmrRL2RMctOaE0fCn6CinPerwnHFW3
# N4MC1SINebBQKkhlMiIuQaE7jS7UMPMVunIMrd44uPzMbZH3PK/Mfzw22s8l8g1T
# LAXCAgTpySmaT14PGQdz+HDqhNut7LHQsYCWFh3Iz+aZdPD62iOOvMUcvlS95Q1C
# mTfwESqH+71hGzFhAfImtM+SRIHwIN7c3QGgWK+19qwAwFpYSw9DHrXajxnIAUsl
# ABp6uFWspiXlCavtAxutYdKnEYXnOmFGHLYJ7eEmyLpXT+EAK/qaNY8f4Uuxiitl
# l7n79Lv1hnKGJX15h+sYUwIDAQABo4IBaTCCAWUwHQYDVR0OBBYEFBNAKriKAkX3
# TahxdigrzDjdsNhIMB8GA1UdIwQYMBaAFLLAZ6ZWjSd5EHTD9cWliWbW8S42MDcG
# A1UdHwQwMC4wLKAqoCiGJmh0dHA6Ly9wa2kuaW50ZWwuY29tL2NybC9JbnRlbENB
# N0IuY3JsMGYGCCsGAQUFBwEBBFowWDAyBggrBgEFBQcwAoYmaHR0cDovL3BraS5p
# bnRlbC5jb20vY3J0L0ludGVsQ0E3Qi5jcnQwIgYIKwYBBQUHMAGGFmh0dHA6Ly9P
# Q1NQLmludGVsLmNvbS8wDAYDVR0TAQH/BAIwADALBgNVHQ8EBAMCB4AwPQYJKwYB
# BAGCNxUHBDAwLgYmKwYBBAGCNxUIhsOMdYSZ5VGD/YEohY6fU4KRwAlnhYn2ZIXp
# klACAWQCARIwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEwYDVR0gBAwwCjAIBgZngQwB
# BAEwDQYJKoZIhvcNAQELBQADggIBAA5KFG1jv7XNqTmif06C/PeRKLM2H/Fa07tv
# R8xwN/yp5aNQ5D2gsWVngsNAfrA2dvbfzq9ZJxKpa03DxDnWbbdzc7G5EtuPPEL4
# lGKikBE6lqOORp8hZ+BHpjhDtq8EZlNU94t8g+YbiSGl0OdVtMLJHuZBLX1pmM46
# 9cPV2U3jS+tEXvFsuzL7BKvOKOhY8koKGGGPSCHw/OslH0tGmMa1+NKdpPbKE/Yt
# bh9x4dzxi7glaeLjoMmjbNPNhANxWQosSZmq0uly3T67PDlYNVbJ6eelAIUYRHEs
# qmVBRXiFURDwy4F7H8xZAJHyRGCrXaX++EF3mVMZ/goscQ6+oezLNdxugwNqh0jS
# jDu7dsmAQzoX0tR09aGqEIeFWr0O3yXsbDNFfM1Yj/+WYJQWYFGJEUwWqwelepEJ
# NH9Z6DmHPQwF1clOQ9e7qgxm2RzeTQrt2Wj7D4kYVnAlNVdjUjL6q/J42N3mJtiO
# pAiGuRUxSYspzeLrATQoB9QBMwFHSyh5SFfl2jZuJfTI7ar1fC3IWVtnUnMIa3zV
# yjk1FlSFrwXq1rX71kzDIRR+pRH8pjM1sT0xOvC1b1iI/9OHHSJxWDWQiAsq3gs/
# eca3yQYxNML+RSy/983r6Tcmqd0+oZ5P4mifSqTQ8dBticMuzufKm34JMFCYKW6+
# NjnxHpN+MIIHSTCCBTGgAwIBAgIQBptemSdyhMh2fxNop96w8zANBgkqhkiG9w0B
# AQwFADCBhTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3Rl
# cjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQx
# KzApBgNVBAMTIkNPTU9ETyBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcN
# MTUxMDI4MDAwMDAwWhcNMjEwNjE3MjM1OTU5WjBzMQswCQYDVQQGEwJVUzELMAkG
# A1UECBMCQ0ExFDASBgNVBAcTC1NhbnRhIENsYXJhMRowGAYDVQQKExFJbnRlbCBD
# b3Jwb3JhdGlvbjElMCMGA1UEAxMcSW50ZWwgRXh0ZXJuYWwgSXNzdWluZyBDQSA3
# QjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALpab/FfGgtUEBK6kNai
# 6w5erD3OFYWaShHKZH8iimkWV88gOiSA17vgU9ypS89sgbG+GqIB4EV7bAxm1E+P
# biLt81KYono1N4ps7LgxhklnKce0s4hw0JkeK8QS9+4e87wkjhGGA5PSeQvnrtxa
# Mami54AJ+lqSUWcw7zux9LH9TqsaaCXn21Vgc3sVvwBMkEKeKWYPejzjfaBCmZCe
# NVyDHOVI30F8s57plyrD+gNGI6kmwmXxleJXTaaqgLOJUbcylkMl9C+Q+A7Mz3h0
# dQ2uL52hoAv8HU0jxoa23WHHpr+XEe0VDEDj/eUQLZ2zwe/t62R5F4wGrmmS60YD
# KtQh0Vn6/DbplxZGeSgzo1krGfQV5nA8SomyyT6Nd0jUCnysReVEKVwT88hNjiae
# 8FSFAO2f6+7P4hPBuq3TqtVErbR0HqsA3QdyXpymtJDj9kahAFRXyCYX40hz0Zho
# 0ZGsrDp27EvjNoWTGWLAIUhoC4rFlCUdKNUC1Afp/lBTg5ETbGEAB/xA95fNjzJ7
# DXo3DAij++xe+o1z47rEktBx9PscYZVtV1seZi1qIH5VMLusiV/Kce1cE44GhSBy
# Rswh/Q5jEN8cRz8S0vlQSwQb32/SzJuOVwUgla9jVoshUAnPle+fNvcre/+AcVCv
# fUuantD3RBiwYBqUo4owCJ7rAgMBAAGjggHEMIIBwDAfBgNVHSMEGDAWgBS7r34C
# Pfqm8TyEjq3uOJjs2TIy1DAdBgNVHQ4EFgQUssBnplaNJ3kQdMP1xaWJZtbxLjYw
# DgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwPgYDVR0lBDcwNQYI
# KwYBBQUHAwMGCCsGAQUFBwMEBggrBgEFBQcDCAYKKwYBBAGCNwoDDAYJKwYBBAGC
# NxUFMCIGA1UdIAQbMBkwDQYLKoZIhvhNAQUBaQEwCAYGZ4EMAQQBMEwGA1UdHwRF
# MEMwQaA/oD2GO2h0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNlcnRp
# ZmljYXRpb25BdXRob3JpdHkuY3JsMHEGCCsGAQUFBwEBBGUwYzA7BggrBgEFBQcw
# AoYvaHR0cDovL2NydC5jb21vZG9jYS5jb20vQ09NT0RPUlNBQWRkVHJ1c3RDQS5j
# cnQwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNvbW9kb2NhLmNvbTA1BgNVHR4E
# LjAsoCowC4EJaW50ZWwuY29tMBugGQYKKwYBBAGCNxQCA6ALDAlpbnRlbC5jb20w
# DQYJKoZIhvcNAQEMBQADggIBADW7A+rMm2AaE9B1Uo6AlUVOnr9uwLtkqsNusQId
# Rl4v6C9IzIQQ962ZO//6hWgpsNN8MeIatHvBZuKlO8cpGJg1rmMBqEUglWHbEE25
# DWvTmWTOX4u4bBNGoG5aDT7nkOu3MaEh9Y3eO3tpNvEIALmqvxxWYVbXzJI/KdTZ
# a9giLw5W9WrRRuiAjzl6kjxnSLfi+hkPN2fi3yktAqpDKC6uLEZCJL5tu2qISaZM
# IN/lZU/64cG+cdX4XvWdZpKyO2Th6K6smVUXvdsb36CTTz9W8juD1dK3wQhaUkBC
# 4z6RIPc1tJHwTeE0aUh5wO0wyZMahNVyGY9tgDn0WasgFtj5/3AmI3vsxQAzInw9
# IDrttCi8eoEM5wvBP3wwDE5QuGcP12QXt8PFIIXKj87VJioSVLn/IvioJzzKDoU3
# FO4C5S9mFWJjh2pezynTuJF4t2FyF3vBGaYYCCLa0JEl9gYJCSawLayAiHQzX8fg
# RMEwmXbYd7FHAe9pkivtrlgpY6A1juQdtwTx2jqyMoCxyLzw5w9xAHozOgbopNh5
# 2dlTzZv+smhbiISFawdx0E+TCgdgAzQI0nO/FBrf48cEGy2ZnpMclbOHmEJaHJFj
# UjmKj0oqwkx7cGk6PPH7L/8OCoeU5AFqz5u0H6MOqeoq3K8rjEQB/TpYfTJ4ohnV
# yXTFMYIRgjCCEX4CAQEwgYowczELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRQw
# EgYDVQQHEwtTYW50YSBDbGFyYTEaMBgGA1UEChMRSW50ZWwgQ29ycG9yYXRpb24x
# JTAjBgNVBAMTHEludGVsIEV4dGVybmFsIElzc3VpbmcgQ0EgN0ICE1YAAAkh3ALj
# /S30VrQAAAAACSEwDQYJYIZIAWUDBAIBBQCgajAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFjAvBgkqhkiG9w0B
# CQQxIgQg+1U0WfodECdhX2oJ0GFyzWaiS5BsVWhaMh/RBluQzQkwDQYJKoZIhvcN
# AQEBBQAEggEAdqrhD9r0F2Lvw5b/7mwOTeL3uaiYdvK5RKbZXPGa/OQvsjjLUVsN
# ATyfALPvMQbmladtV8W+yUebNefAHKjzqFryyycGWjECpSlyQ3RqgS1TK+mJJu9k
# 8sHRMX/bJfvk99VRS08NOouaTUx2gBH3zj15FiH+0EJd9V9kI06Xy1Qdj6YPLz0G
# +M00Uo14pqKTonrEunHk5mCPHPpDuFgArX/BfwVD3Oz3XYtAWkOpzWysh/qtED+z
# U3XrZEd0UiI9G1uPgfe9aMsvNRl17V8s+6IIS8bxWP5FJShQ+Lp59PpGniTQzVhQ
# exq7NVzsdcqNv+mqnFizpYV5VDm/0//KvaGCD1wwgg9YBgorBgEEAYI3AwMBMYIP
# SDCCD0QGCSqGSIb3DQEHAqCCDzUwgg8xAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggEj
# BgsqhkiG9w0BCRABBKCCARIEggEOMIIBCgIBAQYKKwYBBAGEWQoDATAxMA0GCWCG
# SAFlAwQCAQUABCBfv+b5mHqCfxKFJ2btyNyKziPoHVM/ncjKwA5rJKOdNQIGXp8X
# zWTbGBMyMDIwMDUxMTE0MTIwMi43ODdaMASAAgH0AggWEIxvwIrVaKCBmKSBlTCB
# kjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRQwEgYDVQQHEwtTYW50YSBDbGFy
# YTEaMBgGA1UEChMRSW50ZWwgQ29ycG9yYXRpb24xJjAkBgNVBAsTHVRoYWxlcyBU
# U1MgRVNOOjBFMzctOTY0OS0wOEM1MRwwGgYDVQQDExN0aW1lc3RhbXAuaW50ZWwu
# Y29toIILYjCCBYAwggRooAMCAQICFGmy0czwLiDcyVxiiU9/nl9fwFe/MA0GCSqG
# SIb3DQEBCwUAMH8xCzAJBgNVBAYTAkJNMRkwFwYDVQQKExBRdW9WYWRpcyBMaW1p
# dGVkMSUwIwYDVQQLExxSb290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MS4wLAYD
# VQQDEyVRdW9WYWRpcyBSb290IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTE0
# MDUzMDE2MzU1NVoXDTIxMDMxNzE4MzMzM1owSTELMAkGA1UEBhMCQk0xGTAXBgNV
# BAoTEFF1b1ZhZGlzIExpbWl0ZWQxHzAdBgNVBAMTFlF1b1ZhZGlzIElzc3Vpbmcg
# Q0EgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDEUaj9L/gZXOiZ
# ejGaRpNiTOdiWyWkl8tAAxD3mTzZ1nHM84Em3NU/WWimnmR5pSfAQcyY9sgkQInE
# oSpbRyAJEvD/zI5kvu7RAV/HoPz8nFYZulFdvDrFzw+q6uDt6h5k3fMZk6FL51GQ
# WzICtAW7WVzwwhekyImStVdE2rwIPEoTM3LPBNonb+12yShSSThhy663cIotiFio
# EWMDgYwyotMgwiq7YChyARvC0/jL+h48O3VmO4iPT2I+bTqpcLeLZpJNjeqc4eT8
# hFwRsYUxp3RtpJd0to89i3zv/MGYz7zYqiFMkknH4sej9zSUtxQvHAnkut7U02c4
# LQI/sjjm4PQ4hBkPlaDvDHDuOMyDZWd5G0Ccu8TJSpC5xgQKEtHFkTgcRwFVDEpV
# rjRKiKhIQBBZyAnMnmeACyC6U2mhXwCKnYVsybZyosMVU/vTjKxuTD0BWhJ1GjXu
# sftEDkM4zyFUn/VKAx/hxmvXjGubPSvHb/AVivHApPYl6lszLdMmjEV6FhJs5ZQX
# KbhBYDPaSWA1j5f+gjGyi7QjZIQ09mRWG6JXiWKsQjmsB6n8aOH8PhZd8cRvCClS
# 069Ki/N8gNO7Volp9loqw7MsSMu334uvBB0tQbY513lB08Z2GlA5joeEnU580zVw
# 5WKv6qrHU1BxOz1FUmH/ucHXOhm7TQIDAQABo4IBKDCCASQwEgYDVR0TAQH/BAgw
# BgEB/wIBADARBgNVHSAECjAIMAYGBFUdIAAwcQYIKwYBBQUHAQEEZTBjMCoGCCsG
# AQUFBzABhh5odHRwOi8vb2NzcC5xdW92YWRpc2dsb2JhbC5jb20wNQYIKwYBBQUH
# MAKGKWh0dHA6Ly90cnVzdC5xdW92YWRpc2dsb2JhbC5jb20vcXZyY2EuY3J0MA4G
# A1UdDwEB/wQEAwIBBjAfBgNVHSMEGDAWgBSLS23t0ym5BhnsOTmp8JeEasvv3zA4
# BgNVHR8EMTAvMC2gK6AphidodHRwOi8vY3JsLnF1b3ZhZGlzZ2xvYmFsLmNvbS9x
# dnJjYS5jcmwwHQYDVR0OBBYEFPM0EhHxjMb2sqe0mUtwispgoctFMA0GCSqGSIb3
# DQEBCwUAA4IBAQC59hNStRenKk2Ed0MJpNugZ7RgDkL0A73E/yxaD5AueMVjyErs
# J/Z85CnQz2AY+mgi2gJSdg3yF1TG9ggeocyC5MM6bZkifMTAd7TmBSBHk0A5z9xV
# rcNGrylNeZxkTCBfihxW/EagX8uY3ZF6ObSvxHeZa56s3m8teep/1xMkmFIc/Wk+
# 7XKsP9C0ARkU7bDwy/OcURQjjMfcaX0ygZbkHUePAXaUgz6IjZJbGFiYaQPH9dPy
# YVJQ6zSg/SYwMA+1/XDnJyw3Cxzz5x6mLAdDtkuIXpcfwTB9YGQq8wxwaERRY1mf
# 21fCH/+A5cIRktgv79UXQ/9kLWSEXFIaY8JnMIIF2jCCA8KgAwIBAgIUPKXVJR91
# KaW6PHO0SW+iwbDFbJ8wDQYJKoZIhvcNAQELBQAwSTELMAkGA1UEBhMCQk0xGTAX
# BgNVBAoTEFF1b1ZhZGlzIExpbWl0ZWQxHzAdBgNVBAMTFlF1b1ZhZGlzIElzc3Vp
# bmcgQ0EgRzQwHhcNMTgwNDIwMTY1MjQxWhcNMjEwMzE3MTgzMzMzWjCBkjELMAkG
# A1UEBhMCVVMxCzAJBgNVBAgTAkNBMRQwEgYDVQQHEwtTYW50YSBDbGFyYTEaMBgG
# A1UEChMRSW50ZWwgQ29ycG9yYXRpb24xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNO
# OjBFMzctOTY0OS0wOEM1MRwwGgYDVQQDExN0aW1lc3RhbXAuaW50ZWwuY29tMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA52dtRZm66ZrxoCP0i+ZDZJse
# Jw8eKTD56QmR3bOl8dyq/rRqvg4z1ZycTygGQDiUchY94ICqKvwiMkgFWPk6379L
# wutyx1/MFDD9LULI0H9VMfEjL5eXjpk/478s9/NmzE3k7nQDLrIjQiwMWFdSn3Dw
# fJSathyDX9Lxk2CnGhcNNayYamQxd86MsIAWuIOJ6LBresd1ZfFHlNEeEBfvzAci
# IX/DXA39uSPcp8sVXj/x3BHDvQnUbNhL+3QH0kyVyEbMaVJa9fxz8pb/+FpWknc2
# RbkorBjwiu0QewiG7cxHWW8fIzlRLbYQIrdM1T0ZH3tA26uvBZb5xRZ5GlplSwID
# AQABo4IBbjCCAWowcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRwOi8v
# b2NzcC5xdW92YWRpc2dsb2JhbC5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90cnVz
# dC5xdW92YWRpc2dsb2JhbC5jb20vcXZpY2FnNC5jcnQwTwYDVR0gBEgwRjBEBgor
# BgEEAb5YAYRYMDYwNAYIKwYBBQUHAgEWKGh0dHA6Ly93d3cucXVvdmFkaXNnbG9i
# YWwuY29tL3JlcG9zaXRvcnkwDgYDVR0PAQH/BAQDAgbAMBYGA1UdJQEB/wQMMAoG
# CCsGAQUFBwMIMB8GA1UdIwQYMBaAFPM0EhHxjMb2sqe0mUtwispgoctFMDoGA1Ud
# HwQzMDEwL6AtoCuGKWh0dHA6Ly9jcmwucXVvdmFkaXNnbG9iYWwuY29tL3F2aWNh
# ZzQuY3JsMB0GA1UdDgQWBBS5a4HQxx1xdf9LHJgTC+dAi3nl1DANBgkqhkiG9w0B
# AQsFAAOCAgEApCyR6/8OdDnQHPUH7hKswd0XpE95ke+a647wrlcM4xylfFPpWnIF
# N5PF+P1wrLxLopA9mAtnjV4N7KcH2jB1jKACNko5xLms75KM+DLt0YTOfjyQCgaw
# Ft9ri0qvwiQfrVi5BsVf2ePRjnQQYiyCUrDg8urTUz0wXSZmQ+qc80POW8UqRcYt
# 7lhffGf2j43sZJJZmunokNvKt7nmgibb/zSFpMHGDWS7FSwW+xeB4j+1ykJYsmJA
# u31x5tP9P6IoxKNNzsaf8NrPYFKZuEUIWv8SqkodOoLYNiQ+i84kX+BrP1JeIH8y
# aOpKGStoLlVXkhPmmC39Gx31DSeMKdFJb5yY4zi4PWAbea46X0Sn070bTXf5vcRC
# LbKfU+AijJ1Zx/D4J4Sgrzp9G3lCB6M8msnfwtSTBKxGMu6Yh2nIrhH5BcVMV/qd
# cl7qypke6RLZQi3C3F+WYNH3lopR6gYj4ONvicp90f6U7jFi7yOaTJ9ZdjwF9UgR
# NNhUYuFdDESGA1m5nz24RAG1oIerrdaZvq0xfxNlSdDlhnlWPpoxGFE34ThtQjTl
# /J6qoBejm6EA9QqdLiOu9EeXBQk9Y4C1JNq5H9I7KB1YrN6zFczVdZx14tpacuX4
# WN6ELuVqrHVZHWVHEn++RcwPI3m8KMg4rGAFo09zoQATQMqdDcq8ikUxggKMMIIC
# iAIBATBhMEkxCzAJBgNVBAYTAkJNMRkwFwYDVQQKExBRdW9WYWRpcyBMaW1pdGVk
# MR8wHQYDVQQDExZRdW9WYWRpcyBJc3N1aW5nIENBIEc0AhQ8pdUlH3Uppbo8c7RJ
# b6LBsMVsnzANBglghkgBZQMEAgEFAKCB/TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
# AQkQAQQwLwYJKoZIhvcNAQkEMSIEIERbhHs1jPvDq+kXwBHLyZ6EIhovMmLJHyYX
# tXPshLliMIGtBgsqhkiG9w0BCRACDDGBnTCBmjCBlzB9BBQrOk5rc3hf3J1zb7PN
# 1RpQkZ834jBlME2kSzBJMQswCQYDVQQGEwJCTTEZMBcGA1UEChMQUXVvVmFkaXMg
# TGltaXRlZDEfMB0GA1UEAxMWUXVvVmFkaXMgSXNzdWluZyBDQSBHNAIUPKXVJR91
# KaW6PHO0SW+iwbDFbJ8wFgQUGOjbsorXDJxSM4B/YbEdSPzHhbEwDQYJKoZIhvcN
# AQEBBQAEggEAFbMKlVahi9kvTWPC+T4m39f1mOKB5yASrttre6Me6sY6K609fwoT
# VDlQN4oYHXLJjCkEnPcFmeW0rB31nSJZlLo6v5Un+Wi9xXZkoVhNMMSZ8bLb75TB
# x0EF1JewlBFpHw1LtnM+7Wn+x3PIhfRNe8oYuDwB6dqCzhT4Cpd8g4uQFlcwqJET
# ZwPFsSk/EmthzbtNOudHjcIcc4Jp5jg4IrdQ8Jw2khVDwyLg+XO7QTiqHl6jJeoX
# FpuvOUVXfpL2dsQZMXVjByLGDBFkM0a136QGiZEK8wzId+kwDLCWz9SbD1Dg/scl
# tvwzvgRNqlJhTzwwT8LFKz+uCHZYse2PcA==
# SIG # End signature block
