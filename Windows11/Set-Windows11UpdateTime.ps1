#This script is to be run as logged in user
function Show-Windows11ScheduleDialog {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Windows 11 Upgrade Schedule'
    $form.Size = New-Object System.Drawing.Size(600,400)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = [System.Drawing.Color]::White
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)

    # Create header panel
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(600,80)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
    $form.Controls.Add($headerPanel)

    # Add header text
    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = "Windows 11 Upgrade Required"
    $headerLabel.ForeColor = [System.Drawing.Color]::White
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $headerLabel.Size = New-Object System.Drawing.Size(550,30)
    $headerLabel.Location = New-Object System.Drawing.Point(20,25)
    $headerPanel.Controls.Add($headerLabel)

    # Add description text
    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = "Your system is ready to upgrade to Windows 11. Please select your preferred date and time for the upgrade to begin. The process may take 1-2 hours to complete."
    $descLabel.Size = New-Object System.Drawing.Size(540,40)
    $descLabel.Location = New-Object System.Drawing.Point(30,100)
    $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($descLabel)

    # Create date/time selection group
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Text = "Schedule Upgrade"
    $groupBox.Size = New-Object System.Drawing.Size(540,140)
    $groupBox.Location = New-Object System.Drawing.Point(30,160)
    $form.Controls.Add($groupBox)

    # Date picker label
    $dateLabel = New-Object System.Windows.Forms.Label
    $dateLabel.Text = "Date:"
    $dateLabel.Size = New-Object System.Drawing.Size(100,20)
    $dateLabel.Location = New-Object System.Drawing.Point(20,35)
    $groupBox.Controls.Add($dateLabel)

    # Create date picker
    $datePicker = New-Object System.Windows.Forms.DateTimePicker
    $datePicker.Location = New-Object System.Drawing.Point(120,32)
    $datePicker.Width = 200
    $datePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
    $datePicker.MinDate = (Get-Date).AddDays(1)
    $groupBox.Controls.Add($datePicker)

    # Time picker label
    $timeLabel = New-Object System.Windows.Forms.Label
    $timeLabel.Text = "Time:"
    $timeLabel.Size = New-Object System.Drawing.Size(100,20)
    $timeLabel.Location = New-Object System.Drawing.Point(20,75)
    $groupBox.Controls.Add($timeLabel)

    # Create time picker
    $timePicker = New-Object System.Windows.Forms.DateTimePicker
    $timePicker.Location = New-Object System.Drawing.Point(120,72)
    $timePicker.Width = 200
    $timePicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Time
    $timePicker.ShowUpDown = $true
    $groupBox.Controls.Add($timePicker)

    # Create schedule button
    $scheduleButton = New-Object System.Windows.Forms.Button
    $scheduleButton.Location = New-Object System.Drawing.Point(400,320)
    $scheduleButton.Size = New-Object System.Drawing.Size(170,35)
    $scheduleButton.Text = 'Schedule Upgrade'
    $scheduleButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $scheduleButton.ForeColor = [System.Drawing.Color]::White
    $scheduleButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $scheduleButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $scheduleButton.Add_Click({
        $selectedDate = $datePicker.Value.Date
        $selectedTime = $timePicker.Value.TimeOfDay
        $scheduledDateTime = $selectedDate.Add($selectedTime)
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Your Windows 11 upgrade has been scheduled for: $scheduledDateTime`n`nPlease save all work and keep your computer plugged in at the scheduled time.`n`nIs this the correct date and time? Click No to choose again.",
            "Confirm Upgrade Schedule",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question)

        if ($result -eq [System.Windows.Forms.DialogResult]::No) {
            return
        }
        
        # Store the datetime before closing the form
        $script:chosenDateTime = $scheduledDateTime
        $form.Close()
    })
    $form.Controls.Add($scheduleButton)

    # Create cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(290,320)
    $cancelButton.Size = New-Object System.Drawing.Size(100,35)
    $cancelButton.Text = 'Cancel'
    $cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancelButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $cancelButton.Add_Click({ $form.Close() })
    $form.Controls.Add($cancelButton)

    # Create a timer for auto-close
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 2700000  # 45 minutes
    $timer.Add_Tick({ 
        Write-Host "No user Input"
        $form.Close() 
    })
    $timer.Start()

    # Add event handlers for user interaction
    $form.Add_MouseMove({ $timer.Start() })
    $form.Add_KeyPress({ $timer.Start() })
    $datePicker.Add_ValueChanged({ $timer.Start() })
    $timePicker.Add_ValueChanged({ $timer.Start() })
    $scheduleButton.Add_MouseMove({ $timer.Start() })
    $cancelButton.Add_MouseMove({ $timer.Start() })

    # Show the form and get the result
    $form.ShowDialog()

    # Process and return the result
    if ($chosenDateTime) {
        $utcDateTime = $chosenDateTime.ToUniversalTime()
        # Debug line to verify EPOCH time
        Write-Host "Debug: EPOCH time = " ([DateTimeOffset]$utcDateTime).ToUnixTimeSeconds()
        $isoDateTime = $utcDateTime.ToString("yyyy-MM-ddTHH:mm:ss")
        #Ninja-Property-Set windows11upgradeschedule $isoDateTime
        $isoDateTime | ConvertTo-Json -Depth 2 | Out-File $env:systemdrive\temp\windows11upgradeschedule.json
    }
    
    return $null
}

function Get-Windows11UpgradeSchedule {
    $schedulePath = "$env:systemdrive\temp\windows11upgradeschedule.json"
    if (Test-Path $schedulePath) {
        try {
            $scheduleJson = Get-Content $schedulePath | ConvertFrom-Json
            $scheduledTime = Get-Date $scheduleJson
            return $scheduledTime
        }
        catch {
            Write-Host "Error reading schedule from JSON file"
            return $null
        }
    }
    return $null
}

$currentSchedule = Get-Windows11UpgradeSchedule
$currentTime = Get-Date

# If there's a current schedule, check if it's expired (more than 4 hours past scheduled time)
if ($currentSchedule) {
    $scheduleEnd = $currentSchedule.AddHours(4)
    if ($scheduleEnd -lt $currentTime) {
        # Schedule has expired, show dialog to reschedule
        Write-Host "Previous schedule expired, requesting new schedule"
        Show-Windows11ScheduleDialog
    } else {
        Write-Host "Valid schedule exists for: $currentSchedule"
    }
} else {
    # No schedule exists, show dialog to create one
    Write-Host "No schedule found, requesting initial schedule"
    Show-Windows11ScheduleDialog
}

