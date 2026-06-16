# scrape_ba_api.ps1
# Fetches all study programmes from Bundesagentur für Arbeit API
# Outputs: universities.json, programmes.json

$apiBase = "https://rest.arbeitsagentur.de/infosysbub/studisu/pc/v1"
$headers = @{ "X-API-Key" = "infosysbub-studisu" }

# All study field dkzIds (field group ID;field ID)
$fields = @(
    @{ name = "Agrarwissenschaften"; dkzIds = "93986;93802" }
    @{ name = "Ernährungswissenschaften"; dkzIds = "94163;94014" }
    @{ name = "Forstwissenschaften"; dkzIds = "93858;94010" }
    @{ name = "Architektur"; dkzIds = "93936;93958" }
    @{ name = "Automatisierungstechnik"; dkzIds = "94030;93598" }
    @{ name = "Bautechnik"; dkzIds = "93819;93690" }
    @{ name = "Elektrotechnik"; dkzIds = "93970;93853" }
    @{ name = "Fahrzeugtechnik"; dkzIds = "94324;94394" }
    @{ name = "Maschinenbau"; dkzIds = "94114;93999" }
    @{ name = "Mechatronik"; dkzIds = "93896;94237" }
    @{ name = "Medizintechnik"; dkzIds = "93584;94187" }
    @{ name = "Umwelttechnik"; dkzIds = "94256;93861" }
    @{ name = "Wirtschaftsingenieurwesen"; dkzIds = "93814;93581" }
    @{ name = "Informatik"; dkzIds = "94116;93995" }
    @{ name = "Mathematik"; dkzIds = "94144;94403" }
    @{ name = "Physik"; dkzIds = "93825;93651" }
    @{ name = "Medizin"; dkzIds = "93698;93575" }
    @{ name = "Biologie"; dkzIds = "93901;93935" }
    @{ name = "Chemie"; dkzIds = "94374;93928" }
    @{ name = "Betriebswirtschaft"; dkzIds = "94008;94158" }
    @{ name = "Management"; dkzIds = "94000;93719" }
    @{ name = "Wirtschaftsinformatik"; dkzIds = "130048;130047" }
    @{ name = "Sozialwissenschaften"; dkzIds = "94348;93694" }
    @{ name = "Rechtswissenschaften"; dkzIds = "94352;94358" }
    @{ name = "Psychologie"; dkzIds = "94393;93804" }
    @{ name = "Anglistik"; dkzIds = "93638;94412" }
    @{ name = "Germanistik"; dkzIds = "94322;94253" }
    @{ name = "Geschichte"; dkzIds = "93911;94041" }
    @{ name = "Kulturwissenschaften"; dkzIds = "93699;94398" }
    @{ name = "Design"; dkzIds = "93733;94379" }
    @{ name = "Kunst"; dkzIds = "94230;94299" }
    @{ name = "Musik"; dkzIds = "94065;93774" }
)

# Degree type IDs: 2=Bachelor, 10=Master, 3=Diplom, 12=Staatsexamen
$degreeTypes = @(
    @{ id = 2;  label = "Bachelor" }
    @{ id = 10; label = "Master" }
)

$allProgrammes = @{}
$allUniversities = @{}
$totalApiCalls = 0
$totalResults = 0

Write-Output "Starting scrape from Bundesagentur für Arbeit API..."
Write-Output "Fields: $($fields.Count), Degree Types: $($degreeTypes.Count)"

foreach ($field in $fields) {
    foreach ($deg in $degreeTypes) {
        $page = 1
        $hasMore = $true
        
        while ($hasMore) {
            $url = "$apiBase/studienangebote?sfe=$($field.dkzIds)&abg=$($deg.id)&pg=$page"
            
            try {
                $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ContentType "application/json"
                $totalApiCalls++
                
                if ($response.maxErgebnisse -gt 0 -and $response.items.Count -gt 0) {
                    $totalResults += $response.items.Count
                    
                    foreach ($item in $response.items) {
                        $prog = $item.studienangebot
                        $id = $prog.id
                        
                        if (-not $allProgrammes.ContainsKey($id)) {
                            $allProgrammes[$id] = $prog
                            
                            # Track unique university
                            $banId = $prog.studienanbieter.banId
                            if ($banId -and -not $allUniversities.ContainsKey($banId)) {
                                $allUniversities[$banId] = @{
                                    banId = $banId
                                    name = $prog.studienanbieter.name
                                    logoUrl = $prog.studienanbieter.logo.externalURL
                                    type = $prog.hochschulart.label
                                    typeId = $prog.hochschulart.id
                                    street = $prog.studienort.strasse
                                    city = $prog.studienort.ort
                                    postalCode = $prog.studienort.postleitzahl
                                    state = $prog.region.label
                                    stateKey = $prog.region.Key
                                    country = $prog.studienort.staat
                                    lat = $prog.studienort.location.lat
                                    lon = $prog.studienort.location.lon
                                }
                            }
                        }
                    }
                    
                    # Pagination: check if more pages
                    $pageSize = if ($response.items.Count -gt 0) { $response.items.Count } else { 20 }
                    $maxPages = [Math]::Ceiling($response.maxErgebnisse / $pageSize)
                    $hasMore = $page -lt $maxPages
                    $page++
                    
                    Write-Output "  $($field.name) / $($deg.label): page $($page-1)/$maxPages ($($allProgrammes.Count) unique)"
                } else {
                    $hasMore = $false
                }
            } catch {
                Write-Warning "  Error: $($field.name) / $($deg.label) page $page : $_"
                $hasMore = $false
            }
            
            # Rate limit: small delay between requests
            Start-Sleep -Milliseconds 200
        }
    }
}

Write-Output ""
Write-Output "=== Summary ==="
Write-Output "API calls: $totalApiCalls"
Write-Output "Total results fetched: $totalResults"
Write-Output "Unique programmes: $($allProgrammes.Count)"
Write-Output "Unique universities: $($allUniversities.Count)"

# Build output data
$outputDir = Join-Path $PSScriptRoot "output"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Convert universities hashtable to array and save
$uniList = $allUniversities.Values | Sort-Object name
$uniList | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outputDir "universities.json") -Encoding UTF8
Write-Output "Saved $(@($uniList).Count) universities to output/universities.json"

# Convert programmes hashtable to array, add degree type field
$progList = $allProgrammes.Values | ForEach-Object {
    $p = $_
    [PSCustomObject]@{
        id = $p.id
        name = $p.studiBezeichnung
        degreeTypeId = $p.abschlussgrad.id
        degreeType = $p.abschlussgrad.label
        universityBanId = $p.studienanbieter.banId
        universityName = $p.studienanbieter.name
        subjects = $p.studienfaecher
        description = $p.studiInhalt
        studyModeId = $p.studienform.id
        studyMode = $p.studienform.label
        studyTypeId = $p.studientyp.id
        studyType = $p.studientyp.label
        startInfo = $p.studiBeginn
        city = $p.studienort.ort
        state = $p.region.label
        stateKey = $p.region.Key
        lat = $p.studienort.location.lat
        lon = $p.studienort.location.lon
        hasDualOption = if ($p.studienmodelle.Count -gt 0) { $true } else { $false }
    }
} | Sort-Object name

$progList | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $outputDir "programmes.json") -Encoding UTF8
Write-Output "Saved $(@($progList).Count) programmes to output/programmes.json"

Write-Output ""
Write-Output "Done! Files saved to: $outputDir"
