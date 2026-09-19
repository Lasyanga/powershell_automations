# Export-Patch.ps1

Exports files changed by a Git commit (or a set of commits) from one of your project repositories into a patch folder on your Desktop, preserving the original directory tree. Optionally packages the result into a `.zip` archive.

The script is interactive: it prompts you to select a repository, a search mode, a search term, and a destination folder.

## Requirements

- **Windows** with PowerShell 5.1+ (or PowerShell 7+)
- **[Git](https://git-scm.com/)** available on `PATH`
- A configuration file listing one repository path per line (see [Configuration](#configuration))
- Optional: [7-Zip](https://www.7-zip.org/) — used for compression if installed; otherwise the script falls back to the built-in `Compress-Archive` cmdlet

## Configuration

By default the script looks for a `projects.txt` file next to the script. Create it with **one repository path per line**:

```
D:\Work_related\lstv_xampp\htdocs\lstv_workspace\onedb_release2
D:\Work_related\lstv_xampp\htdocs\lstv_workspace\onedb_development2
```

- Blank lines and lines with whitespace only are ignored.
- Lines pointing to paths that don't exist are skipped.
- If no valid project directories remain, the script exits with an error.

## Usage

```powershell
# Run with the default configuration file (projects.txt in the current directory)
.\Export-Patch.ps1

# Point to a different configuration file
.\Export-Patch.ps1 -ConfigFile "C:\path\to\my-projects.txt"

# Run with execution policy bypass for the current session (if needed)
powershell -ExecutionPolicy Bypass -File .\Export-Patch.ps1
```

### Parameters

| Parameter     | Type   | Default        | Description                                        |
| ------------- | ------ | -------------- | -------------------------------------------------- |
| `-ConfigFile` | string | `projects.txt` | Path to the file listing repository paths to choose from. |

## Interactive Flow

The script walks you through these steps:

1. **Select Project Repository** — shows the numbered list of repositories from the config file; enter the number of the repository to export from.
2. **Select Git Search Mode** — choose one of:
   - **`[1] Search Commit Message (--grep)`** — finds commits whose message contains the term (e.g., a ticket number like `B3814`); exports all files changed by matching commits.
   - **`[2] Specific Commit Hash or Range`** — exports files changed by a single commit (e.g., `7a8f9b2`) or a revision range (e.g., `HEAD~1..HEAD` or `main..feature`).
3. **Destination Folder** — press **Enter** to use the default
   `%USERPROFILE%\Desktop\hosting_patch\<search-term>`, or type a custom path.
   The search term is sanitized for use in the folder name (invalid filename characters are replaced with `_`).
4. **Compression** — after files are copied, answer `y`/`yes` to create a `.zip` next to the destination folder.

## Example

```
PS> .\Export-Patch.ps1

--- Select Project Repository ---
[1]D:\Work_related\...\onedb_release2
[2]D:\Work_related\...\onedb_development2
Select project number (1-2): 1

--- Select Git Search Mode ---
[1] Search Commit Message (--grep)
[2] Specific Commit Hash or Range (e.g., a1b2c3d or HEAD~1..HEAD)
Select mode (1-2): 1
Enter grep term (e.g., B3814): B3814

Default Destination: C:\Users\Gil\Desktop\hosting_patch\B3814
Press ENTER to use default, or enter custom destination path: 

Querying Git repository...
Copied: app/controllers/orders.php
Copied: app/views/reports/orders.php

--- Compression ---
Compress 'B3814' to a .zip file? (y/n): y
Using 7-Zip: C:\Program Files\7-Zip\7z.exe
Archive created: C:\Users\Gil\Desktop\hosting_patch\B3814.zip

--- Summary ---
Destination : C:\Users\Gil\Desktop\hosting_patch\B3814
Copied      : 2 file(s)
Skipped     : 0 file(s)
Archive     : C:\Users\Gil\Desktop\hosting_patch\B3814.zip
```

## How It Works

1. Loads and validates the repository list from the config file.
2. Asks which repository, search mode, and search term/commit to use.
3. Runs `git log --name-only --pretty=format:` with `--grep=<term>` (mode 1) or the commit/range argument (mode 2) to list changed files. Duplicates are removed.
4. Copies each changed file into the destination folder, recreating the relative directory structure (`<dest>\<relative-path>`).
   - Files that were **deleted** in the commits (or are otherwise missing on disk) are skipped and counted in the summary.
5. Optionally creates a `.zip` archive:
   - Uses **7-Zip** (`7z` on `PATH`, or installed at the standard 7-Zip locations) when available.
   - Falls back to the native `Compress-Archive` cmdlet otherwise.

## Notes

- The Git query is scoped to the **working directory** of the selected repository (`git -C <repo> ...`); uncommitted changes are not included.
- Deleted files are reported as *Skipped* since there is nothing to copy — the summary shows the count so you can review them.
- If no files are found, the script warns and exits without creating anything.