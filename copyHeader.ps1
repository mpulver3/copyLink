#===== Create logfile =====
$LogFile = Join-Path (Get-Location) "copyHeader.log"

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [$Level] $Message"

    Add-Content -Path $LogFile -Value $entry
    Write-Host $entry
}

#===== Navigate files =====
function Get-TargetFiles {
    param ([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Path does not exist."
    }

    if ((Get-Item $Path).PSIsContainer) {
        return Get-ChildItem $Path -Recurse -Include *.htm, *.html
    }

    return Get-Item $Path
}

function New-BookmarkName {
    param ([int]$Number)
    return "bookmark$Number"
}

function Get-RelativeImagePath {
    param ([System.IO.FileInfo]$File)

    # Split the path and find "Content"
    $segments = $File.FullName -split '[\\/]'
    $contentIndex = [Array]::IndexOf($segments, 'Content')

    if ($contentIndex -lt 0) {
        throw "File is not under a Content folder: $($File.FullName)"
    }

    # Count how many folders deep we are *under* Content
    $depthUnderContent = $segments.Length - $contentIndex - 2

    # Build ../ path
    $relativePrefix = if ($depthUnderContent -gt 0) {
        ('../' * $depthUnderContent)
    } else {
        ''
    }

    return "${relativePrefix}Resources/Images/_SystemImages/StylesheetImages/"
}

#===== process functions =====
function Process-Headers {
    param (
        [string]$Content,
        [string]$TagName,
        [string]$IconFile,
        [string]$ImagePath,
        [ref]$BookmarkCounter
    )

    $pattern = "(?s)<$TagName(.*?)>(.*?)</$TagName>"

    return [regex]::Replace($Content, $pattern, {
        param($match)

        # --- 1) Skip if icon already exists in this header ---
        if ($match.Value -match [regex]::Escape($IconFile)) {
            return $match.Value
        }

        # --- 2) Check for an existing bookmark and reuse it ---
        $existingBookmarkMatch = [regex]::Match(
            $match.Value,
            '<a\s+name\s*=\s*"(.*?)"',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ($existingBookmarkMatch.Success) {
            # Reuse existing bookmark value
            $bookmark = $existingBookmarkMatch.Groups[1].Value
            $bookmarkTag = ""   # Don't inject another anchor
        }
        else {
            # Create a new bookmark and increment counter
            $bookmark = New-BookmarkName $BookmarkCounter.Value
            $BookmarkCounter.Value++

            Write-Log "Added bookmark '$bookmark' to <$TagName>"

            $bookmarkTag = "<a name=`"$bookmark`"></a>"
        }

        # --- 3) Build icon link ---
        $icon = "<a href=`"#$bookmark`" target=`"_self`" title=`"copy link to section`" class=`"custom-link`"><img src=`"$ImagePath$IconFile`" class=`"img_noThumbnail`" /></a>"

        # --- 4) Reconstruct the header ---
        return "<$TagName$($match.Groups[1].Value)>$($match.Groups[2].Value) $bookmarkTag$icon</$TagName>"
    })
}


#===== process files =====
function Process-File {
    param ([System.IO.FileInfo]$File)

    Write-Log "Processing file: $($File.FullName)"

    $content = Get-Content $File.FullName -Raw
    $original = $content

    $bookmarkCounter = 1
    $counterRef = [ref]$bookmarkCounter

    $imagePath = Get-RelativeImagePath $File
    Write-Log "Resolved image path: $imagePath"

    # Exact required order and mappings
    $content = Process-Headers -Content $content -TagName "h2" -IconFile "copy.png"    -ImagePath $imagePath -BookmarkCounter $counterRef
    $content = Process-Headers -Content $content -TagName "h3" -IconFile "copy-h3.png" -ImagePath $imagePath -BookmarkCounter $counterRef
    $content = Process-Headers -Content $content -TagName "MadCap:dropDownHead" -IconFile "copy-h3.png" -ImagePath $imagePath -BookmarkCounter $counterRef

    if ($content -ne $original) {
        Set-Content -Path $File.FullName -Value $content -Encoding UTF8
        Write-Log "File updated: $($File.Name)"
    }
    else {
        Write-Log "No changes required: $($File.Name)"
    }
}

#===== main =====
try {
    $path = Read-Host "Enter full path to an HTML file or folder"
    Write-Log "Script started"

    $files = Get-TargetFiles $path

    foreach ($file in $files) {
        if ($file.Extension -notin @('.htm', '.html')) { 
            Write-Log "Skipping non-HTML file: $($file.FullName)" continue 
        }
        Process-File $file
    }

    Write-Log "Script completed successfully"
}
catch {
    Write-Log $_ -Level "ERROR"
}