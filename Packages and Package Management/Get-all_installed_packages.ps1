# Force UTF-8 encoding for all external commands
$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8

function Get-AllPackages {
    $results = @()

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            $wingetLines = winget list --accept-source-agreements --disable-interactivity 2>$null

            # Find FIRST header and separator by content
            $headerIdx = -1
            $sepIdx    = -1
            for ($i = 0; $i -lt $wingetLines.Count; $i++) {
                if ($headerIdx -lt 0 -and $wingetLines[$i] -match '^\s*Name\s+Id\s+Version') {
                    $headerIdx = $i
                }
                if ($headerIdx -ge 0 -and $sepIdx -lt 0 -and $wingetLines[$i] -match '^-{10,}') {
                    $sepIdx = $i
                    break  # stop at first separator after header
                }
            }

            if ($headerIdx -ge 0 -and $sepIdx -ge 0) {
                $header = $wingetLines[$headerIdx]

                $colName    = $header.IndexOf('Name')
                $colId      = $header.IndexOf('Id')
                $colVersion = $header.IndexOf('Version')
                $colSource  = $header.IndexOf('Source')

                $wingetLines | Select-Object -Skip ($sepIdx + 1) | ForEach-Object {
                    $line = $_
                    if ($line.Trim() -eq '' -or $line -match '^-{10,}' -or $line -match '^\s*Name\s+Id') { return }

                    function Get-Col($start, $end) {
                        if ($start -lt 0 -or $start -ge $line.Length) { return '' }
                        $len = if ($end -gt 0 -and $end -le $line.Length) { $end - $start } else { $line.Length - $start }
                        $line.Substring($start, [Math]::Max(0, $len)).Trim()
                    }

                    $results += [PSCustomObject]@{
                        Name        = Get-Col $colName    $colId
                        Id          = Get-Col $colId      $colVersion
                        Version     = Get-Col $colVersion $colSource
                        Source      = if ($colSource -gt 0) { Get-Col $colSource -1 } else { 'ARP' }
                        ManagerName = 'WinGet'
                    }
                }
            }
        } catch {}
    }

    # Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        try {
            choco list --local-only --limit-output 2>$null | ForEach-Object {
                $parts = $_ -split '\|'
                if ($parts.Count -ge 2) {
                    $results += [PSCustomObject]@{
                        Name        = $parts[0].Trim()
                        Id          = $parts[0].Trim()
                        Version     = $parts[1].Trim()
                        Source      = 'chocolatey'
                        ManagerName = 'Chocolatey'
                    }
                }
            }
        } catch {}
    }

    # npm (global)
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            $npmJson = npm list -g --json 2>$null | ConvertFrom-Json
            if ($npmJson.dependencies) {
                $npmJson.dependencies.PSObject.Properties | ForEach-Object {
                    $results += [PSCustomObject]@{
                        Name        = $_.Name
                        Id          = $_.Name
                        Version     = $_.Value.version
                        Source      = 'npm'
                        ManagerName = 'npm'
                    }
                }
            }
        } catch {}
    }

    # PowerShell Modules (all PSModulePath locations)
    Get-Module -ListAvailable | Select-Object Name, Version, ModuleBase |
        Sort-Object Name, Version -Unique | ForEach-Object {
            $source = switch -Wildcard ($_.ModuleBase) {
                '*PSGallery*'                  { 'PSGallery' }
                '*\WindowsPowerShell\Modules*' { 'WindowsPowerShell' }
                '*\PowerShell\Modules*'        { 'PowerShell' }
                default                        { 'System/Other' }
            }
            $results += [PSCustomObject]@{
                Name        = $_.Name
                Id          = $_.Name
                Version     = $_.Version.ToString()
                Source      = $source
                ManagerName = 'PowerShell'
            }
        }

    # pip (Python)
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        try {
            pip list --format=json 2>$null | ConvertFrom-Json | ForEach-Object {
                $results += [PSCustomObject]@{
                    Name        = $_.name
                    Id          = $_.name
                    Version     = $_.version
                    Source      = 'pypi'
                    ManagerName = 'pip'
                }
            }
        } catch {}
    }

    # Scoop
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        try {
            scoop list 2>$null | Where-Object { $_ -match '\S' } |
                Select-Object -Skip 2 | ForEach-Object {
                    $parts = ($_ -split '\s+').Where({ $_ })
                    if ($parts.Count -ge 2) {
                        $results += [PSCustomObject]@{
                            Name        = $parts[0]
                            Id          = $parts[0]
                            Version     = $parts[1]
                            Source      = if ($parts.Count -ge 3) { $parts[2] } else { 'scoop' }
                            ManagerName = 'Scoop'
                        }
                    }
                }
        } catch {}
    }

    # dotnet tools (global)
    if (Get-Command dotnet -ErrorAction SilentlyContinue) {
        try {
            dotnet tool list -g 2>$null | Select-Object -Skip 2 | ForEach-Object {
                $parts = ($_ -split '\s+').Where({ $_ })
                if ($parts.Count -ge 2) {
                    $results += [PSCustomObject]@{
                        Name        = $parts[0]
                        Id          = $parts[0]
                        Version     = $parts[1]
                        Source      = 'nuget'
                        ManagerName = 'dotnet'
                    }
                }
            }
        } catch {}
    }

    # Cargo (Rust)
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        try {
            cargo install --list 2>$null | Where-Object { $_ -match '^(\S+) v([\d.]+)' } |
                ForEach-Object {
                    $m = [regex]::Match($_, '^(\S+) v([\d.]+)')
                    $results += [PSCustomObject]@{
                        Name        = $m.Groups[1].Value
                        Id          = $m.Groups[1].Value
                        Version     = $m.Groups[2].Value
                        Source      = 'crates.io'
                        ManagerName = 'Cargo'
                    }
                }
        } catch {}
    }

    # git (heuristic: PATH entries inside git repos - **Vomits**)
    $env:PATH -split ';' | Where-Object { $_ -and (Test-Path $_) } | ForEach-Object {
        $dir = $_
        $gitDir = Join-Path (Split-Path $dir -Parent) '.git'
        if (Test-Path $gitDir) {
            $repoRoot = Split-Path $dir -Parent
            $remote  = git -C $repoRoot remote get-url origin 2>$null
            $tag     = git -C $repoRoot describe --tags 2>$null
            $results += [PSCustomObject]@{
                Name        = Split-Path $dir -Leaf
                Id          = $remote
                Version     = if ($tag) { $tag } else { 'unknown' }
                Source      = $remote
                ManagerName = 'git'
            }
        }
    }

    return $results
}

# Output
$packages = Get-AllPackages

$packages | Format-Table -AutoSize -Property ManagerName, Name, Id, Version, Source

$savepath = "`Desktop\$($env:COMPUTERNAME)_installed_packages_($((Get-Date).ToString("dd-MM-yyyy"))).csv"

$packages | Export-Csv -Path "$env:USERPROFILE\$($savepath)" -NoTypeInformation -Encoding UTF8

Write-Host "`nTotal: $($packages.Count) packages across $(($packages | Select-Object -ExpandProperty ManagerName -Unique).Count) managers"

Write-Host "`File saved to path: $($savepath)"