Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W32 {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT r);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hwnd, int X, int Y, int w, int nHeight, bool rp);
  public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@
while ($true) {
  try {
    $p = Get-Process -Name "qemu-system-*" -ErrorAction SilentlyContinue
    if ($p) {
      $h = $p.MainWindowHandle
      if ($h -ne [IntPtr]::Zero) {
        $r = New-Object W32+RECT
        [W32]::GetWindowRect($h, [ref]$r)
        if ($r.Top -lt 0) {
          [W32]::MoveWindow($h, 200, 100, 900, 750, $true)
        }
      }
    }
  } catch {
    # ignore errors - keep running
  }
  Start-Sleep 3
}
