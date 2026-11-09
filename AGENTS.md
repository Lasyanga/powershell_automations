# powershell_automations

A collection of standalone PowerShell scripts for Windows automation tasks. No build system, package manager, test framework, or CI — each script is self-contained and runs directly.

## Scripts

| Script | Purpose |
|--------|---------|
| `GroupFilesByExtension.ps1` | Sorts files into category folders by extension |
| `CopyModifiedFiles.ps1` | Copies files modified on/after a given date |
| `reset_mariadb_password.ps1` / `.bat` | Resets MariaDB/MySQL root password (requires admin) |
| `UnstuckShiftKey.ps1` | Resets stuck Shift key states via Win32 `keybd_event` |
| `PingMonitor.ps1` | Monitors latency to a host; beeps on timeout |
| `ClearTeams.ps1` | Clears Microsoft Teams cache and restarts the app |
| `CleanupVSCodeCache.ps1` | Deletes VS Code cache folders |
| `ExportPatch/Export-Patch.ps1` | Exports files changed by Git commits into a patch folder |

> **Removed:** `DatabaseTerminal.ps1` — present in `main`/`development` history but deleted from the working tree (the deletion is unstaged). Restore with `git checkout -- DatabaseTerminal.ps1` if it is still wanted.

## Running scripts

All scripts target Windows PowerShell 5.1+ or PowerShell 7+. Run from the repo root:

```powershell
.\ScriptName.ps1
```

`ExportPatch/Export-Patch.ps1` lives in a subdirectory; invoke it by path from the repo root, or `cd ExportPatch` and run it from there:

```powershell
.\ExportPatch\Export-Patch.ps1
```

If execution policy blocks a script:

```powershell
powershell -ExecutionPolicy Bypass -File .\ScriptName.ps1
```

`ExportPatch/Export-Patch.ps1` is interactive and requires a `projects.txt` file (one repo path per line) next to the script or passed via `-ConfigFile`. See `ExportPatch/README.md` for details.

## Conventions

- Scripts are standalone — no shared modules, dot-sourcing, or imports.
- Interactive input uses `Read-Host`. Most scripts that modify state end with `Read-Host` or `$Host.UI.RawUI.ReadKey` to keep the window open; exceptions:
  - `CleanupVSCodeCache.ps1` — exits immediately after reporting completion.
  - `PingMonitor.ps1` — runs an infinite loop; stop with Ctrl+C.
  - `reset_mariadb_password.ps1` and `Export-Patch.ps1` — finish and return to the caller.
- Console output uses `Write-Host -ForegroundColor` for status messages.
- Parameterized scripts: `Export-Patch.ps1` and `reset_mariadb_password.ps1` declare `[CmdletBinding()]` + `param()`. `CopyModifiedFiles.ps1` uses `param()` without `[CmdletBinding()]`. The remainder are parameter-less.
- `reset_mariadb_password.ps1` uses `$ErrorActionPreference = 'Stop'` and section-banner comments.
- Git branches: `main` (stable) and `development` (work-in-progress).

## Pitfalls

- `reset_mariadb_password.ps1` requires Administrator privileges and stops/restarts the database service. The `.bat` wrapper enforces this too.
- `DatabaseTerminal.ps1` (now removed) launched a child PowerShell with `-Verb RunAs` (UAC prompt).
- `ExportPatch/Export-Patch.ps1` shells out to `git -C <repo> log ...` — the target repos must be valid Git working trees.
- `CopyModifiedFiles.ps1` copies files matching `LastWriteTime.Date -ge $filterDate` (on or after), not exactly on that date.
- **Destructive scripts** — `GroupFilesByExtension.ps1` (moves files; irreversible without a backup), `ClearTeams.ps1` and `CleanupVSCodeCache.ps1` (delete cache/data), `reset_mariadb_password.ps1` (stops the DB service) — take a backup or close affected apps before running.
- `GroupFilesByExtension.ps1` skips files whose target name already exists and reports a moved/skipped count at the end.
- `PingMonitor.ps1` runs indefinitely; interrupt with Ctrl+C.
- `ClearTeams.ps1` targets the Teams packaged-app cache path (`MSTeams_8wekyb3d8bbwe`); adjust the path if your Teams installation differs.
- No Pester tests, no PSScriptAnalyzer config, no CI pipeline. Verify changes by running the scripts manually.
