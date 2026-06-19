Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Get script folder and image path
#$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
#$NullByteImage = Join-Path $ScriptDir 'NullByte.png'

#if (-not (Test-Path $NullByteImage)) {
#    [System.Windows.MessageBox]::Show("NullByte.png not found in:`n$ScriptDir","Missing Image",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
#    exit
#}

# Reliable EXE directory detection
$ScriptDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
$NullByteImage = Join-Path $ScriptDir 'NullByte.png'

if (-not (Test-Path $NullByteImage)) {
    [System.Windows.MessageBox]::Show("NullByte.png not found in:`n$ScriptDir","Missing Image",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
        exit
        }

# Create main window
$window                 = New-Object System.Windows.Window
$window.WindowStyle     = 'None'
$window.WindowState     = 'Maximized'
$window.ResizeMode      = 'NoResize'
$window.Background      = 'Black'
$window.Topmost         = $true
$window.Title           = 'NullByte Purge'

# Root grid
$grid = New-Object System.Windows.Controls.Grid
$grid.Margin = 0
$window.Content = $grid

# Define rows
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Image
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Text
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Buttons

# ====== IMAGE (CENTERED) ======
$image = New-Object System.Windows.Controls.Image
$image.HorizontalAlignment = 'Center'
$image.VerticalAlignment   = 'Center'
$image.Stretch             = 'Uniform'
$image.MaxHeight           = 400
$image.MaxWidth            = 400

$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.UriSource = New-Object System.Uri($NullByteImage)
$bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$bitmap.EndInit()
$image.Source = $bitmap

[System.Windows.Controls.Grid]::SetRow($image,0)
$grid.Children.Add($image) | Out-Null

# ====== WARNING TEXT ======
$warningText = @"
*WARNING*

By clicking ""I Understand the Risks,"" all of your Active and Orphaned
MSEdge and Chrome sessions will be NUKED!

Any active work being done in either browser will be gone, destroyed,
obliterated, annihilated, eradicated, or decimated.

In other words: SAVE YOUR WORK NOW.

All Edge and Chrome tabs and windows will be closed. There is no going back.

You may click ""Cancel"" at any time to return to your desktop, and the destructive app will be terminated.
"@

$textBlock = New-Object System.Windows.Controls.TextBlock
$textBlock.Text                = $warningText
$textBlock.Foreground          = 'Red'
$textBlock.FontSize            = 20
$textBlock.TextAlignment       = 'Center'
$textBlock.HorizontalAlignment = 'Center'
$textBlock.VerticalAlignment   = 'Top'
$textBlock.Margin              = '40,10,40,10'
$textBlock.TextWrapping        = 'Wrap'

[System.Windows.Controls.Grid]::SetRow($textBlock,1)
$grid.Children.Add($textBlock) | Out-Null

# ====== BUTTON PANEL ======
$buttonPanel = New-Object System.Windows.Controls.StackPanel
$buttonPanel.Orientation        = 'Horizontal'
$buttonPanel.HorizontalAlignment = 'Center'
$buttonPanel.VerticalAlignment   = 'Center'
$buttonPanel.Margin              = '0,20,0,0'
#$buttonPanel.Spacing             = 20

[System.Windows.Controls.Grid]::SetRow($buttonPanel,2)
$grid.Children.Add($buttonPanel) | Out-Null

# Cancel button
$btnCancel = New-Object System.Windows.Controls.Button
$btnCancel.Content             = 'Cancel'
$btnCancel.Width               = 160
$btnCancel.Height              = 40
$btnCancel.FontSize            = 16
$btnCancel.Background          = 'Gray'
$btnCancel.Foreground          = 'White'
$btnCancel.Margin              = '10'

# I Understand button
$btnUnderstand = New-Object System.Windows.Controls.Button
$btnUnderstand.Content         = 'I Understand the Risks'
$btnUnderstand.Width           = 260
$btnUnderstand.Height          = 40
$btnUnderstand.FontSize        = 16
$btnUnderstand.Background      = 'DarkRed'
$btnUnderstand.Foreground      = 'White'
$btnUnderstand.Margin          = '10'

$buttonPanel.Children.Add($btnCancel)      | Out-Null
$buttonPanel.Children.Add($btnUnderstand)  | Out-Null

# ====== KILL LOGIC ======
function Invoke-NullByteKill {
    $killed = @()

    $targets = @(
        'msedge',
        'msedgewebview2',
        'chrome'
    )

    foreach ($name in $targets) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            try {
                $info = [PSCustomObject]@{
                    Name = $p.ProcessName
                    Id   = $p.Id
                }
                $p.Kill()
                $killed += $info
            } catch {}
        }
    }

    return $killed
}

# ====== KILL REPORT WINDOW ======
function Show-KillReportWindow {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable]$Killed
    )

    $reportWindow                 = New-Object System.Windows.Window
    $reportWindow.Title           = 'NullByte Purge Report'
    $reportWindow.WindowStartupLocation = 'CenterScreen'
    $reportWindow.Width           = 800
    $reportWindow.Height          = 600
    $reportWindow.Background      = 'Black'
    $reportWindow.Foreground      = 'White'
    $reportWindow.Topmost         = $true
    $reportWindow.ResizeMode      = 'NoResize'

    $root = New-Object System.Windows.Controls.Grid
    $root.Margin = 20
    $reportWindow.Content = $root

    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null # summary
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null # list
    $root.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null # button

    # Summary
    $edgeCount   = ($Killed | Where-Object { $_.Name -like 'msedge*' }).Count
    $chromeCount = ($Killed | Where-Object { $_.Name -eq 'chrome' }).Count
    $totalCount  = $Killed.Count

    $summaryText = @"
NUKE COMPLETE

Total Processes Terminated: $totalCount

- Edge (msedge / msedgewebview2): $edgeCount
- Chrome: $chromeCount
"@

    $summaryBlock = New-Object System.Windows.Controls.TextBlock
    $summaryBlock.Text                = $summaryText
    $summaryBlock.FontSize            = 20
    $summaryBlock.TextAlignment       = 'Left'
    $summaryBlock.Margin              = '0,0,0,10'
    $summaryBlock.TextWrapping        = 'Wrap'
    [System.Windows.Controls.Grid]::SetRow($summaryBlock,0)
    $root.Children.Add($summaryBlock) | Out-Null

    # Detailed list
    $listBox = New-Object System.Windows.Controls.ListBox
    $listBox.Background = 'Black'
    $listBox.Foreground = 'White'
    $listBox.BorderBrush = 'Gray'
    $listBox.FontFamily = 'Consolas'
    $listBox.FontSize = 14

    foreach ($item in $Killed) {
        [void]$listBox.Items.Add(("{0,-20} PID {1}" -f $item.Name, $item.Id))
    }

    [System.Windows.Controls.Grid]::SetRow($listBox,1)
    $root.Children.Add($listBox) | Out-Null

    # Close button
    $closePanel = New-Object System.Windows.Controls.StackPanel
    $closePanel.Orientation = 'Horizontal'
    $closePanel.HorizontalAlignment = 'Center'
    $closePanel.Margin = '0,10,0,0'
    [System.Windows.Controls.Grid]::SetRow($closePanel,2)
    $root.Children.Add($closePanel) | Out-Null

    $btnClose = New-Object System.Windows.Controls.Button
    $btnClose.Content        = 'Close'
    $btnClose.Width          = 160
    $btnClose.Height         = 40
    $btnClose.FontSize       = 16
    $btnClose.Background     = 'DarkRed'
    $btnClose.Foreground     = 'White'
    $btnClose.Margin         = '10'
    $closePanel.Children.Add($btnClose) | Out-Null

    $btnClose.Add_Click({
        $reportWindow.Close()
    })

    $reportWindow.ShowDialog() | Out-Null
}

# ====== BUTTON EVENTS ======
$btnCancel.Add_Click({
    $window.Close()
})

$btnUnderstand.Add_Click({
    # Disable buttons to prevent double-clicks
    $btnUnderstand.IsEnabled = $false
    $btnCancel.IsEnabled     = $false

    # Perform kills
    $killed = Invoke-NullByteKill

    # Close main window and show report
    $window.Hide()
    Show-KillReportWindow -Killed $killed
    $window.Close()
})

# Run
$window.ShowDialog() | Out-Null
