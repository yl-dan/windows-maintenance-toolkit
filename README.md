# Windows Maintenance Toolkit

An interactive batch menu for routine Windows workstation maintenance and
network diagnostics.

Built to give non-technical users a single entry point for the checks a
support technician would otherwise walk them through over the phone.

## Design constraint

Every option wraps a utility that ships with Windows. Nothing is downloaded,
nothing is piped from a remote URL into an interpreter, and no third-party
binary is executed. A maintenance script that pulls remote code is a supply
chain risk on every machine it touches.

## Options

| # | Action | Underlying tool |
|---|---|---|
| 1 | Clean temporary files | `del` on `%TEMP%`, `%WINDIR%\Temp`, Recent |
| 2 | Disk Cleanup | `cleanmgr` |
| 3 | Malicious Software Removal Tool | `mrt` |
| 4 | Memory Diagnostics | `mdsched` |
| 5 | System File Checker | `sfc /scannow` |
| 6 | Show local IP addresses | `ipconfig` |
| 7 | Restart a network adapter | `netsh interface` |
| 8 | Check network connectivity | `ping` (IP and DNS separately) |
| 9 | Open Windows Update | `ms-settings:windowsupdate` |

## Usage

Right-click `maintenance-toolkit.bat` and choose **Run as administrator**.

The script checks for elevation on start and exits with a clear message if it
is missing. Several options (`sfc`, `mdsched`, system-wide temp cleanup) fail
silently without it, which is harder to diagnose than an upfront refusal.

## Implementation notes

A few decisions worth explaining:

- **Prefetch is deliberately not cleared.** Clearing it is a common step in
  "PC cleaner" scripts, but Windows manages the folder itself, removing it
  degrades application start times, and Prefetch is a useful forensic artifact
  during incident response.
- **Network adapter is selected, not hardcoded.** The script lists available
  interfaces and prompts for the name, rather than assuming `"Wi-Fi"`, which
  breaks on any machine with a renamed or wired adapter.
- **IP and DNS are tested separately.** A single ping to a hostname cannot
  distinguish a dead link from a name-resolution failure. The script tests an
  IP literal and a hostname, then says which layer failed.
- **Menu input is quoted.** Comparing `if "%choice%"=="1"` rather than
  `if %choice% equ 1` avoids a syntax error on empty or unexpected input.
- **`timeout` replaces `ping` as a delay.** `ping localhost -n 2.5` is invalid;
  the count parameter is an integer, and `timeout` is the correct tool.

## Status

v1: the options above are implemented and tested on Windows 10 and 11.

Planned:
- PowerShell rewrite for structured output and error handling
- Optional logging of each action to a timestamped file
- Disk health check via `wmic diskdrive get status`

## License

MIT: see [LICENSE](LICENSE).
