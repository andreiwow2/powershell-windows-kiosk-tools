Add-Type -AssemblyName System.Windows.Forms

$blockListReg = @{
    regPath = "HKLM:\Software\Policies\Microsoft\Edge\URLBlocklist"
    regName = "1"
    regValue = "*"
}

$allowListReg = @{
    regPath = "HKLM:\Software\Policies\Microsoft\Edge\URLAllowlist"
}

Function Check-Module($ModuleName) {
    $module = Get-Module -ListAvailable -Name $ModuleName
    return $module -ne $null
}

$notificationModule = "BurntToast"

# Check if BurntToast module is installed, if not, install it
if (-not (Check-Module -ModuleName $notificationModule)) {
    try {
        # Use -Force -SkipPublisherCheck to suppress prompts during the installation
        Install-Module -Name $notificationModule -Force -SkipPublisherCheck
    } catch {
        Write-Error "Could not install the module '$notificationModule'. Error: $_"
        exit
    }
}

Import-Module $notificationModule

if (-not (Test-Path $blockListReg.regPath)) {
   try {
        New-Item -Path $blockListReg.regPath -Force
   } catch {
        Write-Host "Error removing registry item: $_"
        exit
   }
}

if (-not (Test-Path $allowListReg.regPath)) {
   try {
        New-Item -Path $allowListReg.regPath -Force
   } catch {
        Write-Host "Error removing registry item: $_"
        exit
   }
}


$blockListRegExists = (Get-Item $blockListReg.regPath -EA Ignore).Property -contains $blockListReg.regName

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Edge website whitelist'
$form.Size = New-Object System.Drawing.Size(300,300)
$form.StartPosition = 'CenterScreen'

# Add a label
$label = New-Object System.Windows.Forms.Label
$label.Text = 'Whitelisted websites will be displayed here'
$label.Location = New-Object System.Drawing.Point(10, 110)
$label.Size = New-Object System.Drawing.Size(280, 20)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 130)
$listBox.Size = New-Object System.Drawing.Size(260, 100)
$form.Controls.Add($listBox)

$toggleBtn = New-Object System.Windows.Forms.Button
$toggleBtn.Size = New-Object System.Drawing.Size(100,40)
$toggleBtn.Location = New-Object System.Drawing.Point(30,20)
$toggleBtn.Text = if ($blockListRegExists) { 'Disable' } else { 'Enable' }

$whitelistWebsiteBtn = New-Object System.Windows.Forms.Button
$whitelistWebsiteBtn.Size = New-Object System.Drawing.Size(100,40)
$whitelistWebsiteBtn.Location = New-Object System.Drawing.Point(170,20)
$whitelistWebsiteBtn.Text = 'Allow Website'


$allowedWebsites = @()
Function UpdateAllowedWebsitesListUI {
    $website = Get-ItemProperty -Path $allowListReg.regPath -ErrorAction SilentlyContinue
    $allowedWebsites = @()

    if ($website) {
        foreach ($prop in ($website.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' })) {
            $allowedWebsites += $prop.Name + '=' + $prop.Value
        }
    }

    $listBox.Items.Clear()
    foreach ($item in $allowedWebsites) {
        $listBox.Items.Add($item)
    }
}


Function InsertAllowedWebsite {
    # Create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Insert allowed website'
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'

	$textBox = New-Object System.Windows.Forms.TextBox
	$textBox.Location = New-Object System.Drawing.Point(10, 40)
	$textBox.Size = New-Object System.Drawing.Size(260, 20)
	$form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
	$okButton.Text = 'OK'
	$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$okButton.Location = New-Object System.Drawing.Point(210, 70)
	$form.Controls.Add($okButton)
	$form.AcceptButton = $okButton # Allow the user to press Enter to submit

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $newRegistryValue = $textBox.Text

        $allowedUrlProperties = Get-ItemProperty -Path $allowListReg.regPath -ErrorAction SilentlyContinue
        $propertyCount = ($allowedUrlProperties.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }).Count
        Write-Host "Props before: $propertyCount"
        $propertyCount = $propertyCount + 1

        try {
            New-ItemProperty -Path $allowListReg.regPath -Name $propertyCount -Value $newRegistryValue -ErrorAction Stop
            New-BurntToastNotification -Text "Microsoft Edge Whitelist", "Added $newRegistryValue to allowed websites"
            UpdateAllowedWebsitesListUI
        } catch {
            Write-Host "Error creating registry item: $_"
            exit
        }
    }
}
$whitelistWebsiteBtn.Add_Click({ InsertAllowedWebsite })

$handle_DeleteSelectedWebsite = {
    $selectedItem = $listBox.SelectedItem
    $propName = $selectedItem -split "=" | Select-Object -First 1
    $website = $selectedItem -split "=" | Select-Object -Last 1

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Delete selected website'
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'

    # Add a label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'Do you want to delete website: ' + $website + '?'
    $label.Location = New-Object System.Drawing.Point(10, 110)
    $label.Size = New-Object System.Drawing.Size(280, 20)

    $form.Controls.Add($label)

    $okButton = New-Object System.Windows.Forms.Button
	$okButton.Text = 'OK'
	$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$okButton.Location = New-Object System.Drawing.Point(210, 70)
	$form.Controls.Add($okButton)
	$form.AcceptButton = $okButton # Allow the user to press Enter to submit

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            Remove-ItemProperty -Path $allowListReg.regPath -Name $propName -Force -ErrorAction Ignore
            New-BurntToastNotification -Text "Microsoft Edge Whitelist", "Deleted the website $website"
            UpdateAllowedWebsitesListUI
        } catch {
            Write-Host "Error removing registry item: $_"
            exit
        }
    }
}
$listBox.Add_SelectedIndexChanged($handle_DeleteSelectedWebsite)

$handle_ToggleWhitelisting = {
    $blockListRegExists = (Get-Item $blockListReg.regPath -EA Ignore).Property -contains $blockListReg.regName
    if ($blockListRegExists) {
        # Remove the BlockList registry value indicating that whitelisting is disabled
        try {
            Remove-ItemProperty -Path $blockListReg.regPath -Name $blockListReg.regName -Force -ErrorAction Ignore
            New-BurntToastNotification -Text "Microsoft Edge Whitelist", "Disabled website whitelist"
        } catch {
            Write-Host "Error removing registry item: $_"
            exit
        }
    } else {
        # Add the BlockList registry value indicating that whitelisting is enabled
        try {
            New-ItemProperty -Path $blockListReg.regPath -Name $blockListReg.regName -Value $blockListReg.regValue -ErrorAction Stop
            New-BurntToastNotification -Text "Microsoft Edge Whitelist", "Enabled website whitelist"
        } catch {
            Write-Host "Error creating registry item: $_"
            exit
        }
    }

    $blockListRegExists = (Get-Item $blockListReg.regPath -EA Ignore).Property -contains $blockListReg.regName
    $toggleBtn.Text = if ($blockListRegExists) { 'Disable' } else { 'Enable' }
}
$toggleBtn.Add_Click($handle_ToggleWhitelisting)

$form.Controls.Add($label)
$form.Controls.add($toggleBtn)
$form.Controls.add($whitelistWebsiteBtn)

UpdateAllowedWebsitesListUI

# Show the form
$form.ShowDialog()
