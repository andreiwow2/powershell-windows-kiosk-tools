Add-Type -AssemblyName System.Windows.Forms

Function EnableKioskModeForUser {
	param (
		[Parameter(Mandatory=$true)]
		[string]$user,
		
		[Parameter(Mandatory=$true)]
		[string]$website,
		
		[Parameter(Mandatory=$true)]
		[string]$Sid
	)
	
	Write-Host "Enable kiosk for $user with website $website and Sid $Sid"
	
	$version = (Get-ComputerInfo | Select-Object OsBuildNumber).OsBuildNumber

	if ($version -gt 19041)
	{
		$AUMID = "Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe!App"
		Set-AssignedAccess -UserName $user -AppUserModelId $AUMID
		$profile = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows\AssignedAccessConfiguration\Configs\$Sid" -Name DefaultProfileId
		#New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\AssignedAccessConfiguration\Profiles\$profile\AllowedApps\App0" -ItemType Directory -Force
		$regpath = "HKLM:\SOFTWARE\Microsoft\Windows\AssignedAccessConfiguration\Profiles\$profile\AllowedApps\App0"
		Set-ItemProperty -Path $regpath -Name "AppId" -Value "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
		Set-ItemProperty -Path $regpath -Name "Arguments" -Value "--no-first-run --kiosk $website --kiosk-idle-timeout-minutes=0 --edge-kiosk-type=fullscreen"
		Set-ItemProperty -Path $regpath -Name "AppType" -Value 0x00000003
		Set-ItemProperty -Path $regpath -Name "AutoLaunch" -Value 0x00000001
	}
	else
	{
		$AUMID = "Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge"

		Set-AssignedAccess -UserName $user -AppUserModelId $AUMID

		New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\" -Name $Sid
		New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\$Sid" -Name "Browser"
		$regpath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\$Sid\Browser"
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureHomeButton" -Value 2
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureHomeButton_ProviderSet" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "ConfigureHomeButton_WinningProvider" -Value "476830E9-5AE5-4794-A472-DF53C27AC1BC"
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskMode" -Value 0
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskMode_ProviderSet" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "ConfigureKioskMode_WinningProvider" -Value "476830E9-5AE5-4794-A472-DF53C27AC1BC"
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskResetAfterIdleTimeout" -Value 5
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskResetAfterIdleTimeout_ProviderSet" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "ConfigureKioskResetAfterIdleTimeout_WinningProvider" -Value "476830E9-5AE5-4794-A472-DF53C27AC1BC"

		New-ItemProperty -Path $regpath -PropertyType "String" -Name "Homepages" -Value "<$website>"
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "Homepages_ProviderSet" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "Homepages_WinningProvider" -Value "476830E9-5AE5-4794-A472-DF53C27AC1BC"
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "SetHomeButtonURL" -Value $website
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "SetHomeButtonURL_ProviderSet" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "SetHomeButtonURL_WinningProvider" -Value "476830E9-5AE5-4794-A472-DF53C27AC1BC"
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "SetNewTabPageURL" -Value $website
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "SetNewTabPageURL_ProviderSet" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "SetNewTabPageURL_WinningProvider" -Value "476830E9-5AE5-4794-A472-DF53C27AC1BC"

		#Create a new settings provider
		New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\" -Name "476830E9-5AE5-4794-A472-DF53C27AC1BC"
		New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\476830E9-5AE5-4794-A472-DF53C27AC1BC\" -Name "default"
		New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\476830E9-5AE5-4794-A472-DF53C27AC1BC\default\" -Name $Sid
		New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\476830E9-5AE5-4794-A472-DF53C27AC1BC\default\$Sid\" -Name "Browser"

		$regpath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\Providers\476830E9-5AE5-4794-A472-DF53C27AC1BC\default\$Sid\Browser"
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureHomeButton" -Value 2
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureHomeButton_LastWrite" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskMode" -Value 0
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskMode_LastWrite" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskResetAfterIdleTimeout" -Value 5
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "ConfigureKioskResetAfterIdleTimeout_LastWrite" -Value 1

		New-ItemProperty -Path $regpath -PropertyType "String" -Name "Homepages" -Value "<$website>"
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "Homepages_LastWrite" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "SetHomeButtonURL" -Value $website
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "SetHomeButtonURL_LastWrite" -Value 1
		New-ItemProperty -Path $regpath -PropertyType "String" -Name "SetNewTabPageURL" -Value $website
		New-ItemProperty -Path $regpath -PropertyType "DWord" -Name "SetNewTabPageURL_LastWrite" -Value 1

	}
}


# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Kiosk Tools'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

# Define the action for User Setup
$handler_UserSetup = {
	$regPath = "HKLM:\Software\KareKioskTools"
    $regName = "KioskUser"
	
	Function CreateKioskUser {
		# Show an input box with a prompt to enter the password
		$passwordBox = New-Object System.Windows.Forms.Form
		$passwordBox.Text = 'Enter Password'
		$passwordBox.Size = New-Object System.Drawing.Size(300, 150)
		$passwordBox.StartPosition = 'CenterScreen'
		
		 # Add a label
		$label = New-Object System.Windows.Forms.Label
		$label.Text = 'Please enter a password:'
		$label.Location = New-Object System.Drawing.Point(10, 20)
		$label.Size = New-Object System.Drawing.Size(280, 20)
		$passwordBox.Controls.Add($label)
		
		# Add a textbox for password input
		$textBox = New-Object System.Windows.Forms.TextBox
		$textBox.Location = New-Object System.Drawing.Point(10, 40)
		$textBox.Size = New-Object System.Drawing.Size(260, 20)
		$textBox.UseSystemPasswordChar = $true # Mask the password input
		$passwordBox.Controls.Add($textBox)

		# Add an OK button
		$okButton = New-Object System.Windows.Forms.Button
		$okButton.Text = 'OK'
		$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
		$okButton.Location = New-Object System.Drawing.Point(210, 70)
		$passwordBox.Controls.Add($okButton)
		$passwordBox.AcceptButton = $okButton # Allow the user to press Enter to submit
		
		# Show the password dialog as a modal window
		$result = $passwordBox.ShowDialog()
		
		if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
			# Get the password from the TextBox
			$password = $textBox.Text
			$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

			# Close the password prompt
			$passwordBox.Close()

			# Prompt for the username
			$username = Read-Host "Please enter the username for the new user"
		}
		
		# Create the local user with the specified password
		try {
			$userInfo = New-LocalUser -Name $username -Password $securePassword -AccountNeverExpires:$false -UserMayNotChangePassword:$false -PasswordNeverExpires:$false -FullName "$username" -Description "Kiosk User"
			$userNameValue = $userInfo.Name
			Add-LocalGroupMember -SID S-1-5-32-545 -Member $userNameValue
			
			EnableKioskModeForUser -user $userNameValue -website "kare.de" -Sid (Get-LocalUser -Name $userNameValue).SID.Value
			
			# Check if the registry path exists, if not, create it
			if (-not (Test-Path $regPath)) {
				New-Item -Path $regPath -Force | Out-Null
			}
			
			# Store the username in the registry
			Set-ItemProperty -Path $regPath -Name $regName -Value $userNameValue
			
			Write-Host "User '$userNameValue' created and added to registry."
		} catch {
			Write-Error "Failed to create user. Error: $_"
		}
	}
	
	if (Test-Path $regPath) {
		$kioskUserExists = (Get-Item $regPath -EA Ignore).Property -contains $regName
		
		if ($kioskUserExists) {
			$kioskUser = (Get-ItemProperty -Path $regPath -Name $regName).$regName
			
			# Create the user management form
			$kioskUserForm = New-Object System.Windows.Forms.Form
			$kioskUserForm.Text = 'Kiosk User Management'
			$kioskUserForm.Size = New-Object System.Drawing.Size(300,200)
			$kioskUserForm.StartPosition = 'CenterScreen'
			
			$handler_KioskUserForm = {
				try {
					Remove-LocalUser -Name $kioskUser
					Remove-ItemProperty -Path $regPath -Name $regName
					Write-Host "Registry entry for the user '$kioskUser' has been removed."
					Write-Host "User '$kioskUser' has been removed from this computer."
					$kioskUserForm.Hide()
				} catch {
					Write-Error "Failed to remove the user '$kioskUser'. Error: $_"
				}
			}
			
			# Create a button for User Setup
			$buttonDeleteKioskUser = New-Object System.Windows.Forms.Button
			$buttonDeleteKioskUser.Size = New-Object System.Drawing.Size(100,40)
			$buttonDeleteKioskUser.Location = New-Object System.Drawing.Point(30,30)
			$buttonDeleteKioskUser.Text = 'Delete User'
			$buttonDeleteKioskUser.Add_Click($handler_KioskUserForm)
			
			# Create a label for your form
			$label = New-Object System.Windows.Forms.Label
			$label.Text = "Delete user $kioskUser"
			$label.AutoSize = $true  # This makes the label automatically size to the text
			$label.Location = New-Object System.Drawing.Point(30, $buttonDeleteKioskUser.Location.Y - 30)
			
			# Add the buttons to the form
			$kioskUserForm.Controls.Add($buttonDeleteKioskUser)
			$kioskUserForm.Controls.Add($label)
			
			# Show the form
			$kioskUserForm.ShowDialog()
		} else {
			CreateKioskUser
		}
	} else {
		CreateKioskUser
	}
}

# Define the action for Option 2
$handler_Option2 = {
    Write-Host 'Option 2 selected'
    # You can also call other scripts or commands here
}

# Create a button for User Setup
$buttonUserSetup = New-Object System.Windows.Forms.Button
$buttonUserSetup.Size = New-Object System.Drawing.Size(100,40)
$buttonUserSetup.Location = New-Object System.Drawing.Point(30,30)
$buttonUserSetup.Text = 'User Setup'
$buttonUserSetup.Add_Click($handler_UserSetup)

# Create a button for Option 2
$button2 = New-Object System.Windows.Forms.Button
$button2.Size = New-Object System.Drawing.Size(100,40)
$button2.Location = New-Object System.Drawing.Point(30,80)
$button2.Text = 'Websites Setup'
$button2.Add_Click($handler_Option2)

# Add the buttons to the form
$form.Controls.Add($buttonUserSetup)
$form.Controls.Add($button2)

# Show the form
$form.ShowDialog()
