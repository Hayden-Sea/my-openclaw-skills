# Windows Screen Capture Tool - Fast with Focus and Correct Scale

param(
    [string]$WindowName,
    [switch]$FullScreen
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$workspaceRoot = $env:OPENCLAW_WORKSPACE
if ([string]::IsNullOrEmpty($workspaceRoot)) {
    $workspaceRoot = "E:\Code\Test\openclaw\workspace"
}
$outputDir = Join-Path $workspaceRoot "outputs\screenshots"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}
$outputPath = Join-Path $outputDir "screenshot_$timestamp.png"

Add-Type -AssemblyName "System.Windows.Forms"
$primary = [System.Windows.Forms.Screen]::PrimaryScreen
$logW = $primary.Bounds.Width
$logH = $primary.Bounds.Height
$physW = 2560
$physH = 1600
$scaleX = $physW / $logW
$scaleY = $physH / $logH

# Fast Win32 APIs
Add-Type -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out int left, out int top, out int right, out int bottom);
[DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr hWnd);
[DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
[DllImport("user32.dll")] public static extern IntPtr GetDesktopWindow();
[DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hWnd);
[DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
[DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth, int nHeight);
[DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleDC(IntPtr hDC);
[DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
[DllImport("gdi32.dll")] public static extern bool BitBlt(IntPtr hDestDC, int xDest, int yDest, int wDest, int hDest, IntPtr hSrcDC, int xSrc, int ySrc, uint rasterOp);
[DllImport("gdi32.dll")] public static extern bool DeleteDC(IntPtr hDC);
[DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
"@ -Namespace 'Win32' -Name 'API'

if ($FullScreen) {
    $x = 0; $y = 0; $w = $physW; $h = $physH
    $title = "Full Screen"
}
else {
    $handle = [IntPtr]::Zero
    $title = $WindowName
    $l = $t = $r = $b = 0
    
    # Try MainWindowHandle first
    $p = Get-Process -Name $WindowName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($null -ne $p) {
        $handle = $p.MainWindowHandle
        $title = $p.MainWindowTitle
        $null = [Win32.API]::GetWindowRect($handle, [ref]$l, [ref]$t, [ref]$r, [ref]$b)
        Write-Host "MainWindowHandle: $handle"
    }
    
    # If invalid, search for window
    if ($handle -eq [IntPtr]::Zero -or $r -le $l -or $b -le $t -or $l -lt 0) {
        Write-Host "Searching for window..."
        
        $code = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WinFinder {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc lp, IntPtr p);
    [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out int pid);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    public static int TargetPid;
    public static IntPtr FoundHandle;
    public static int FoundL, FoundT, FoundR, FoundB;
    public static string FoundTitle;
    
    public static bool Callback(IntPtr h, IntPtr p) {
        int pid;
        GetWindowThreadProcessId(h, out pid);
        if (pid == TargetPid) {
            int len = GetWindowTextLength(h);
            var sb = new StringBuilder(len + 1);
            GetWindowText(h, sb, sb.Capacity);
            RECT rect;
            GetWindowRect(h, out rect);
            
            int ww = rect.Right - rect.Left;
            int hh = rect.Bottom - rect.Top;
            
            // Find largest valid window
            if (ww > 100 && hh > 100 && rect.Left >= 0 && rect.Top >= 0) {
                if (FoundHandle == IntPtr.Zero || (ww * hh) > ((FoundR - FoundL) * (FoundB - FoundT))) {
                    FoundHandle = h;
                    FoundL = rect.Left;
                    FoundT = rect.Top;
                    FoundR = rect.Right;
                    FoundB = rect.Bottom;
                    FoundTitle = sb.ToString();
                }
            }
        }
        return true;
    }
    
    public static void Scan(int pid) { TargetPid = pid; FoundHandle = IntPtr.Zero; EnumWindows(Callback, IntPtr.Zero); }
}
"@
        Add-Type -TypeDefinition $code -OutputAssembly "$env:TEMP\WinFinder.dll" -ErrorAction SilentlyContinue | Out-Null
        if (Test-Path "$env:TEMP\WinFinder.dll") {
            Add-Type -Path "$env:TEMP\WinFinder.dll" -ErrorAction SilentlyContinue | Out-Null
            
            $allProcs = Get-Process -Name $WindowName -ErrorAction SilentlyContinue
            foreach ($proc in $allProcs) {
                [WinFinder]::Scan($proc.Id)
                if ([WinFinder]::FoundHandle -ne [IntPtr]::Zero) {
                    $handle = [WinFinder]::FoundHandle
                    $l = [WinFinder]::FoundL
                    $t = [WinFinder]::FoundT
                    $r = [WinFinder]::FoundR
                    $b = [WinFinder]::FoundB
                    $title = [WinFinder]::FoundTitle
                    Write-Host "Found: $title at ($l, $t)"
                    break
                }
            }
        }
    }
    
    if ($handle -eq [IntPtr]::Zero -or $r -le $l -or $b -le $t) {
        Write-Host "ERROR: Cannot find valid window"
        exit 1
    }
    
    # Focus
    Write-Host "Focusing: $title"
    $null = [Win32.API]::SetForegroundWindow($handle)
    Start-Sleep -Milliseconds 50
    
    # Scale
    $x = [int]($l * $scaleX)
    $y = [int]($t * $scaleY)
    $w = [int](($r - $l) * $scaleX)
    $h = [int](($b - $t) * $scaleY)
    
    Write-Host "Logical: ($l, $t) size=$($r-$l) x $($b-$t)"
    Write-Host "Physical: ($x, $y) size=$w x $h"
}

# Capture
$desktopDC = [Win32.API]::GetDC([Win32.API]::GetDesktopWindow())
$memDC = [Win32.API]::CreateCompatibleDC($desktopDC)
$hBitmap = [Win32.API]::CreateCompatibleBitmap($desktopDC, $w, $h)
[Win32.API]::SelectObject($memDC, $hBitmap)

$result = [Win32.API]::BitBlt($memDC, 0, 0, $w, $h, $desktopDC, $x, $y, 0x00CC0020)

if ($result) {
    $bmp = [System.Drawing.Image]::FromHbitmap($hBitmap)
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "SUCCESS: $outputPath"
    Write-Host "WINDOW_TITLE: $title"
}

[Win32.API]::DeleteObject($hBitmap)
[Win32.API]::DeleteDC($memDC)
[Win32.API]::ReleaseDC([Win32.API]::GetDesktopWindow(), $desktopDC)
