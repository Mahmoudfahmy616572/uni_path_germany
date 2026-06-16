# generate_sql_v2.ps1
# Generates SQL for Supabase using ONLY existing columns
# Maps BA API data into existing schema

$scriptDir = $PSScriptRoot
$outputDir = Join-Path $scriptDir "output"

$universities = Get-Content -Path (Join-Path $outputDir "universities.json") -Encoding UTF8 | ConvertFrom-Json
$programmes = Get-Content -Path (Join-Path $outputDir "programmes.json") -Encoding UTF8 | ConvertFrom-Json

Write-Output "Loaded $($universities.Count) universities, $($programmes.Count) programmes"

function Escape-Sql([string]$s) {
    if ([string]::IsNullOrEmpty($s)) { return "NULL" }
    return "'" + $s.Replace("'", "''") + "'"
}

function Escape-SqlText([string]$s) {
    if ([string]::IsNullOrEmpty($s)) { return "NULL" }
    $plain = $s -replace '<[^>]+>', ' '
    $plain = $plain -replace '&hellip;', '...'
    $plain = $plain -replace '&amp;', '&'
    $plain = $plain -replace '&quot;', '"'
    $plain = $plain -replace '&lt;', '<'
    $plain = $plain -replace '&gt;', '>'
    $plain = $plain -replace '\s+', ' '
    $plain = $plain.Trim()
    if ([string]::IsNullOrEmpty($plain)) { return "NULL" }
    if ($plain.Length -gt 2000) { $plain = $plain.Substring(0, 2000) + "..." }
    return "'" + $plain.Replace("'", "''") + "'"
}

# Migration SQL for new tracking columns
$migration = @()
$migration += "-- Migration: Add BA API tracking columns"
$migration += "ALTER TABLE public.universities ADD COLUMN IF NOT EXISTS ba_ban_id TEXT;"
$migration += "ALTER TABLE public.university_programs ADD COLUMN IF NOT EXISTS ba_program_id TEXT;"
$migration += ""
$migration += "-- Index for faster lookups"
$migration += "CREATE INDEX IF NOT EXISTS idx_universities_ba_ban_id ON public.universities (ba_ban_id);"
$migration += "CREATE INDEX IF NOT EXISTS idx_programs_ba_program_id ON public.university_programs (ba_program_id);"

$migrationPath = Join-Path $outputDir "002_add_ba_tracking_columns.sql"
$migration -join "`r`n" | Set-Content -Path $migrationPath -Encoding UTF8
Write-Output "Migration SQL -> $migrationPath"

# Build banId -> sequential ID mapping
$uniIdMap = @{}
$uniIndex = 0
foreach ($u in $universities) { $uniIndex++; $uniIdMap[$u.banId.ToString()] = $uniIndex }

# Clear old file first (so we can append)
$dataPath = Join-Path $outputDir "002_import_ba_data.sql"

# ============ UNIVERSITIES INSERT ============
$uniLines = @()
$uniLines += "-- BA API import: Universities ($($universities.Count))"
$uniLines += "INSERT INTO public.universities (id, name, country, location, description, logo_url, ba_ban_id) VALUES"

$uniValues = @()
foreach ($u in $universities) {
    $id = $uniIdMap[$u.banId.ToString()]
    $name = Escape-Sql $u.name
    $country = Escape-Sql "Germany"
    $location = Escape-Sql "$($u.city)"
    $description = Escape-Sql $u.type  # store uni type as description
    $logoUrl = if ($u.logoUrl) { Escape-Sql $u.logoUrl } else { "NULL" }
    $banId = Escape-Sql $u.banId.ToString()
    $uniValues += "($id, $name, $country, $location, $description, $logoUrl, $banId)"
}
$uniLines += ($uniValues -join ",") + " ON CONFLICT (id) DO NOTHING;"
$uniLines += ""
$uniLines += "SELECT setval(pg_get_serial_sequence('universities', 'id'), COALESCE((SELECT MAX(id) FROM universities), 0) + 1, false);"
$uniLines += ""

# ============ PROGRAMS INSERT ============
Write-Output "Building programs SQL..." 

# We'll use a batch approach for programs
$allProgLines = @()
$allProgLines += "-- BA API import: Programs ($($programmes.Count))"

$batch = @()
$batchSize = 200
$totalBatches = 0

$progIndex = 0
$skipped = 0

foreach ($p in $programmes) {
    $progIndex++
    $uniId = $uniIdMap[$p.universityBanId.ToString()]
    if (-not $uniId) { $skipped++; continue }
    
    $name = Escape-Sql $p.name
    $degreeType = "Bachelor"
    if ($p.degreeTypeId -eq 10) { $degreeType = "Master" }
    if ($p.degreeTypeId -eq 3) { $degreeType = "Diplom" }
    if ($p.degreeTypeId -eq 12) { $degreeType = "Staatsexamen" }
    $degreeTypeSql = Escape-Sql $degreeType
    $major = if ($p.subjects -and $p.subjects.Count -gt 0) { Escape-Sql $p.subjects[0] } else { "NULL" }
    $desc = Escape-SqlText $p.description
    $baProgId = Escape-Sql $p.id.ToString()
    
    $batch += "($uniId, $name, $degreeTypeSql, $major, $desc, $baProgId)"
    
    if ($batch.Count -ge $batchSize) {
        $totalBatches++
        $allProgLines += "-- Batch $totalBatches"
        $allProgLines += "INSERT INTO public.university_programs (university_id, program_name, degree_type, major, description, ba_program_id) VALUES"
        $allProgLines += ($batch -join ",") + " ON CONFLICT DO NOTHING;"
        $batch = @()
    }
}

if ($batch.Count -gt 0) {
    $totalBatches++
    $allProgLines += "-- Batch $totalBatches"
    $allProgLines += "INSERT INTO public.university_programs (university_id, program_name, degree_type, major, description, ba_program_id) VALUES"
    $allProgLines += ($batch -join ",") + " ON CONFLICT DO NOTHING;"
}

$allProgLines += ""
$allProgLines += "SELECT setval(pg_get_serial_sequence('university_programs', 'id'), COALESCE((SELECT MAX(id) FROM university_programs), 0) + 1, false);"

# Combine and save
$allLines = $uniLines + $allProgLines
$allLines -join "`r`n" | Set-Content -Path $dataPath -Encoding UTF8

Write-Output "Data SQL -> $dataPath"
Write-Output "Universities: $uniIndex"
Write-Output "Programs: $($progIndex - $skipped) (skipped $skipped with no uni mapping)"
Write-Output "Batches: $totalBatches"
Write-Output "File size: $((Get-Item $dataPath).Length / 1MB) MB"
