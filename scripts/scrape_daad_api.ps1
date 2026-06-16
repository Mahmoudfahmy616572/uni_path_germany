# scrape_daad_api.ps1
# Fetches all degree programs from DAAD International Programmes API

$apiBase = "https://www2.daad.de/deutschland/studienangebote/international-programmes/api/solr/en/search.json"
$outputDir = Join-Path $PSScriptRoot "output"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$allPrograms = @{}
$totalApiCalls = 0

$degreeTypes = @(
    @{id=1; name="Bachelor"},
    @{id=2; name="Master"},
    @{id=3; name="PhD"}
)

foreach ($deg in $degreeTypes) {
    $name = $deg.name
    Write-Output ("Fetching " + $name + "...")
    $offset = 0
    $page = 1
    
    do {
        $params = "limit=100&offset=$offset&degree[]=" + $deg.id + "&display=list"
        $url = $apiBase + "?" + $params
        
        try {
            $resp = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json"
            $totalApiCalls++
            
            if ($resp.courses.Count -gt 0) {
                foreach ($course in $resp.courses) {
                    $key = $course.id
                    if (-not $allPrograms.ContainsKey($key)) {
                        $allPrograms[$key] = $course
                    }
                }
                $cnt = $resp.courses.Count
                $total = $allPrograms.Count
                Write-Output ("  Page " + $page + ": +" + $cnt + " programs (" + $total + " total)")
                $offset += $resp.courses.Count
                $page++
                Start-Sleep -Milliseconds 300
            } else {
                break
            }
        } catch {
            Write-Warning ("  Error at offset " + $offset + " : " + $_)
            break
        }
    } while ($offset -lt $resp.numResults)
}

$total = $allPrograms.Count
Write-Output ("`nTotal programs fetched: " + $total)
Write-Output ("API calls: " + $totalApiCalls)

$progList = $allPrograms.Values | ForEach-Object {
    $p = $_
    [PSCustomObject]@{
        id = $p.id
        courseName = $p.courseName
        academy = $p.academy
        city = $p.city
        languages = $p.languages
        languageLevelGerman = $p.languageLevelGerman
        languageLevelEnglish = $p.languageLevelEnglish
        beginning = $p.beginning
        programmeDuration = $p.programmeDuration
        tuitionFees = $p.tuitionFees
        applicationDeadline = $p.applicationDeadline
        courseType = $p.courseType
        subject = $p.subject
        link = $p.link
        costString = $p.costString
        financialSupport = $p.financialSupport
    }
}

$outFile = Join-Path $outputDir "daad_programs.json"
$progList | ConvertTo-Json -Depth 5 | Set-Content -Path $outFile -Encoding UTF8
$saved = @($progList).Count
Write-Output ("Saved " + $saved + " programs to output/daad_programs.json")
Write-Output "Done!"
