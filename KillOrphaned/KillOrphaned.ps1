# --- START CHUNK 1 ---
<#
    KillOrphaned.ps1
    Version: 1.1.0
    Author: John + NullByte Systems
    Description:
        Enhanced version of the KillOrphaned utility with:
        - Normal window (1024x768)
        - Resizable UI
        - NullByte mascot centered above warning text
        - Memory before/after reporting
        - Detailed process capture (MemoryMB, CPUSeconds, StartTime, Path, ParentPID)
        - Table-style results display
        - CSV export via "Copy All" button
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
# --- END CHUNK 1 ---
# --- START CHUNK 2 ---
# Reliable EXE/script directory detection
# Determine script directory correctly for both PS1 and EXE
if ($MyInvocation.MyCommand.Path) {
    # Running as a PS1 script
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    # Running as a compiled EXE
    $ScriptDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

$NullByteImage = Join-Path $ScriptDir 'NullByte.png'

if (-not (Test-Path $NullByteImage)) {
    [System.Windows.MessageBox]::Show(
        "NullByte.png not found in:`n$ScriptDir",
        "Missing Image",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit
}
# --- END CHUNK 2 ---
# --- START CHUNK 3 ---
# Create main window (normal window, not fullscreen)
$window                 = New-Object System.Windows.Window
$window.Title           = 'NullByte Purge'
$window.Width           = 1024
$window.Height          = 768
$window.WindowStartupLocation = 'CenterScreen'
$window.ResizeMode      = 'CanResize'
$window.WindowStyle     = 'SingleBorderWindow'
$window.Topmost         = $false
$window.Background      = 'Black'

# Root grid
$grid = New-Object System.Windows.Controls.Grid
$grid.Margin = 0
$window.Content = $grid

# Define rows
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Image
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Text
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Buttons

# ====== IMAGE (CENTERED ABOVE TEXT) ======
$image = New-Object System.Windows.Controls.Image
$image.HorizontalAlignment = 'Center'
$image.VerticalAlignment   = 'Center'
$image.Stretch             = 'Uniform'
$image.MaxHeight           = 300
$image.MaxWidth            = 300

$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.UriSource = New-Object System.Uri($NullByteImage)
$bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$bitmap.EndInit()
$image.Source = $bitmap

[System.Windows.Controls.Grid]::SetRow($image,0)
$grid.Children.Add($image) | Out-Null
# --- END CHUNK 3 ---
# --- START CHUNK 4 ---
# ====== WARNING TEXT ======
$warningText = @"
*WARNING*
**Must read and scroll to the end of this block to continue**

By clicking ""I Understand the Risks,"" all of your Active and Orphaned
MSEdge and Chrome sessions will be NUKED!

Any active work being done in either browser will be gone, destroyed,
obliterated, annihilated, eradicated, or decimated.

In other words: SAVE YOUR WORK NOW.

All Edge and Chrome tabs and windows will be closed. There is no going back.

You may click ""Cancel"" at any time to return to your desktop, and this destructive app will be terminated.
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

# Scrollable container for warning text
$scrollViewer = New-Object System.Windows.Controls.ScrollViewer
$scrollViewer.Content                     = $textBlock
$scrollViewer.VerticalScrollBarVisibility = 'Auto'
$scrollViewer.HorizontalScrollBarVisibility = 'Disabled'
$scrollViewer.Margin                      = '20,10,20,10'

[System.Windows.Controls.Grid]::SetRow($scrollViewer,1)
$grid.Children.Add($scrollViewer) | Out-Null

# Unlock "I Understand the Risks" only when scrolled to bottom
$scrollViewer.Add_ScrollChanged({
    if ($scrollViewer.ScrollableHeight -gt 0 -and
        $scrollViewer.VerticalOffset -ge $scrollViewer.ScrollableHeight) {

        if ($Global:btnUnderstand -ne $null) {
            $Global:btnUnderstand.IsEnabled = $true
        }
    }
})
# --- END CHUNK 4 ---
# --- START CHUNK 5 ---
# ====== BUTTON PANEL ======
$buttonPanel = New-Object System.Windows.Controls.StackPanel
$buttonPanel.Orientation         = 'Horizontal'
$buttonPanel.HorizontalAlignment = 'Center'
$buttonPanel.VerticalAlignment   = 'Center'
$buttonPanel.Margin              = '0,20,0,0'

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

# I Understand button (initially disabled until user scrolls to bottom)
$btnUnderstand = New-Object System.Windows.Controls.Button
$btnUnderstand.Content         = 'I Understand the Risks'
$btnUnderstand.Width           = 260
$btnUnderstand.Height          = 40
$btnUnderstand.FontSize        = 16
$btnUnderstand.Background      = 'DarkRed'
$btnUnderstand.Foreground      = 'White'
$btnUnderstand.Margin          = '10'
$btnUnderstand.IsEnabled       = $false

# Expose globally so Chunk 4's scroll handler can enable it
$Global:btnUnderstand = $btnUnderstand

$buttonPanel.Children.Add($btnCancel)      | Out-Null
$buttonPanel.Children.Add($btnUnderstand)  | Out-Null
# --- END CHUNK 5 ---
# --- START CHUNK 6 ---
# ====== PROCESS ENUMERATION + KILL LOGIC ======

function Get-ProcessDetails {
    param($proc)

    # Safely capture details (some processes may block certain properties)
    $path = $null
    try { $path = $proc.Path } catch {}

    $parent = $null
    try {
        $parent = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)").ParentProcessId
    } catch {}

    return [PSCustomObject]@{
        ProcessName = $proc.ProcessName
        PID         = $proc.Id
        MemoryMB    = [math]::Round(($proc.WorkingSet64 / 1MB),2)
        CPUSeconds  = $proc.CPU
        StartTime   = $proc.StartTime
        Path        = $path
        ParentPID   = $parent
    }
}

function Get-SystemMemoryUsageMB {
    $os = Get-CimInstance Win32_OperatingSystem
    $used = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024
    return [math]::Round($used,2)
}

# Storage for results
$Global:ProcessResults = @()
$Global:BeforeMemoryMB = 0
$Global:AfterMemoryMB  = 0
# --- END CHUNK 6 ---
# --- START CHUNK 7 ---
# Kill routine
function Invoke-Nuke {

    # Capture memory BEFORE
    $Global:BeforeMemoryMB = Get-SystemMemoryUsageMB

    # Target processes
    $targets = @("msedge","chrome")

    # Take a snapshot BEFORE killing anything
    $snapshot = @()
    foreach ($name in $targets) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($p in $procs) {
                # Capture details BEFORE kill
                $snapshot += Get-ProcessDetails -proc $p
            }
        }
    }

    # Now kill using the snapshot PIDs
    foreach ($item in $snapshot) {
        try {
            Stop-Process -Id $item.PID -Force -ErrorAction Stop
        } catch {}
    }

    # Store snapshot as final results (no duplicates, no nulls)
    $Global:ProcessResults = $snapshot

    # Capture memory AFTER
    $Global:AfterMemoryMB = Get-SystemMemoryUsageMB
}
# --- END CHUNK 7 ---
# --- START CHUNK 8 ---
function Show-ResultsWindow {

    $reportWindow                 = New-Object System.Windows.Window
    $reportWindow.Title           = "NullByte Purge Results"
    $reportWindow.Width           = 1024
    $reportWindow.Height          = 768
    $reportWindow.WindowStartupLocation = 'CenterScreen'
    $reportWindow.ResizeMode      = 'CanResize'
    $reportWindow.WindowStyle     = 'SingleBorderWindow'
    $reportWindow.Topmost         = $false
    $reportWindow.Background      = 'Black'

    # Root grid
    $rGrid = New-Object System.Windows.Controls.Grid
    $reportWindow.Content = $rGrid

    # Define rows
    $rGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Header
    $rGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Table
    $rGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition)) | Out-Null  # Buttons

    # ====== HEADER TEXT ======
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Foreground          = 'Lime'
    $header.FontSize            = 22
    $header.TextAlignment       = 'Center'
    $header.Margin              = '10'
    $header.Text = @"
NUKE COMPLETE

Processes Killed: $($Global:ProcessResults.Count)
Memory Before: $($Global:BeforeMemoryMB) MB
Memory After:  $($Global:AfterMemoryMB) MB
Memory Freed:  $([math]::Round(($Global:BeforeMemoryMB - $Global:AfterMemoryMB),2)) MB
"@

    [System.Windows.Controls.Grid]::SetRow($header,0)
    $rGrid.Children.Add($header) | Out-Null

    # ====== TABLE DISPLAY (MONOSPACE TEXTBOX) ======
    $textBox = New-Object System.Windows.Controls.TextBox
    $textBox.FontFamily          = 'Consolas'
    $textBox.FontSize            = 14
    $textBox.IsReadOnly          = $true
    $textBox.TextWrapping        = 'NoWrap'
    $textBox.VerticalScrollBarVisibility   = 'Auto'
    $textBox.HorizontalScrollBarVisibility = 'Auto'
    $textBox.Background          = 'Black'
    $textBox.Foreground          = 'White'
    $textBox.Margin              = '10'

    # Build table header
    $table = "ProcessName        PID     MemoryMB   CPUSeconds   StartTime              Path                          ParentPID`r`n"
    $table += "---------------------------------------------------------------------------------------------------------------`r`n"

    foreach ($item in $Global:ProcessResults) {

        # ====== NULL-SAFE FIELDS ======

        # StartTime
        if ($item.StartTime) {
            $start = $item.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
        } else {
            $start = ""
        }

        # Path
        if ($item.Path) {
            $path = $item.Path
        } else {
            $path = ""
        }

        # ParentPID
        if ($item.ParentPID) {
            $parent = $item.ParentPID
        } else {
            $parent = ""
        }

        # ====== BUILD FORMATTED LINE ======
        $line = "{0,-18} {1,-7} {2,-10} {3,-12} {4,-20} {5,-30} {6}" -f `
            $item.ProcessName,
            $item.PID,
            $item.MemoryMB,
            $item.CPUSeconds,
            $start,
            $path,
            $parent

        $table += $line + "`r`n"
    }

    $textBox.Text = $table

    [System.Windows.Controls.Grid]::SetRow($textBox,1)
    $rGrid.Children.Add($textBox) | Out-Null
# --- END CHUNK 8 ---

# --- START CHUNK 9 ---
    # ====== COPY ALL BUTTON ======
    $btnCopy = New-Object System.Windows.Controls.Button
    $btnCopy.Content             = "Copy All (CSV)"
    $btnCopy.Width               = 200
    $btnCopy.Height              = 40
    $btnCopy.FontSize            = 16
    $btnCopy.Margin              = '10'
    $btnCopy.HorizontalAlignment = 'Center'

    # CSV builder (now matches table EXACTLY)
    $btnCopy.Add_Click({
        $csv = "ProcessName,PID,MemoryMB,CPUSeconds,StartTime,Path,ParentPID`r`n"

        foreach ($item in $Global:ProcessResults) {

            # Format StartTime exactly like the table
            $start = ""
            if ($item.StartTime) {
                $start = $item.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
            }

            # Escape commas in paths if needed
            $path = $item.Path
            if ($path -and $path.Contains(",")) {
                $path = '"' + $path + '"'
            }

            $csv += "$($item.ProcessName),$($item.PID),$($item.MemoryMB),$($item.CPUSeconds),$start,$path,$($item.ParentPID)`r`n"
        }

        [System.Windows.Forms.Clipboard]::SetText($csv)
        [System.Windows.MessageBox]::Show("CSV copied to clipboard.","Copied") | Out-Null
    })

    [System.Windows.Controls.Grid]::SetRow($btnCopy,2)
    $rGrid.Children.Add($btnCopy) | Out-Null

    $reportWindow.ShowDialog() | Out-Null
}
# --- END CHUNK 9 ---
# --- START CHUNK 10 ---
# ====== BUTTON EVENT HANDLERS ======

# Cancel button closes the app immediately
$btnCancel.Add_Click({
    $window.Close()
})

# "I Understand" triggers the nuke, closes main window, opens results
$btnUnderstand.Add_Click({
    try {
        Invoke-Nuke
    } catch {
        [System.Windows.MessageBox]::Show(
            "An error occurred during the purge.`n$_",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }

    # Close main window
    $window.Close()

    # Show results window
    Show-ResultsWindow
})
# --- END CHUNK 10 ---
# --- START CHUNK 11 ---
# ====== RUN THE MAIN WINDOW ======
$window.ShowDialog() | Out-Null
# --- END CHUNK 11 ---
