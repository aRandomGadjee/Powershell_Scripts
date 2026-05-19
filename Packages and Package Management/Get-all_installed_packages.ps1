function Get-AllPackages {
    $results = @()

    # WinGet
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try {
            $raw = winget list --accept-source-agreements 2>$null |
                   Select-String '^\S'
            # Skip header lines (no version column structure)
            $wingetLines = winget list --accept-source-agreements --disable-interactivity 2>$null
            $dataStart = ($wingetLines | Select-String '^-+').LineNumber
            if ($dataStart) {
                $wingetLines | Select-Object -Skip $dataStart | ForEach-Object {
                    $parts = $_ -split '\s{2,}'
                    if ($parts.Count -ge 2) {
                        $results += [PSCustomObject]@{
                            Name        = $parts[0].Trim()
                            Id          = if ($parts.Count -ge 2) { $parts[1].Trim() } else { '' }
                            Version     = if ($parts.Count -ge 3) { $parts[2].Trim() } else { '' }
                            Source      = if ($parts.Count -ge 4) { $parts[3].Trim() } else { 'winget' }
                            ManagerName = 'WinGet'
                        }
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
                '*PSGallery*'                             { 'PSGallery' }
                '*\WindowsPowerShell\Modules*'            { 'WindowsPowerShell' }
                '*\PowerShell\Modules*'                   { 'PowerShell' }
                default                                   { 'System/Other' }
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
            # cargo install --list gives "pkg v1.2.3:" lines
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

    return $results
}

# Output
$packages = Get-AllPackages

# Display in table
$packages | Format-Table -AutoSize -Property ManagerName, Name, Id, Version, Source

# export to CSV
$packages | Export-Csv -Path "$env:USERPROFILE\Desktop\installed_packages.csv" -NoTypeInformation

Write-Host "`nTotal: $($packages.Count) packages across $( ($packages | Select-Object -ExpandProperty ManagerName -Unique).Count ) managers"