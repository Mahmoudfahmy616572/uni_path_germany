# match_daad_to_ba.ps1 - Generate UPDATE SQL from DAAD matches
# Strategy: strict matching by normalized name forms

$outDir = Join-Path $PSScriptRoot "output"
$baFile = Join-Path $outDir "programmes.json"
$daadFile = Join-Path $outDir "daad_programs.json"
$outputSql = Join-Path $outDir "005_update_from_daad.sql"

$baData = Get-Content -Raw $baFile -Encoding UTF8 | ConvertFrom-Json
$daadData = Get-Content -Raw $daadFile -Encoding UTF8 | ConvertFrom-Json

# Build BA university lookup by banId
$baUnis = @{}
foreach ($p in $baData) {
    if (-not $baUnis.ContainsKey($p.universityBanId)) {
        $baUnis[$p.universityBanId] = @{
            banId = $p.universityBanId
            name = $p.universityName
            city = ($p.city -split ',')[0].Trim()
        }
    }
}

# Build DAAD university lookup
$daadUnis = @{}
foreach ($p in $daadData) {
    $norm = $p.academy
    if (-not $daadUnis.ContainsKey($norm)) {
        $daadUnis[$norm] = @{
            name = $norm
            programs = @()
        }
    }
    $daadUnis[$norm].programs += $p
}

# Shared normalization
function Norm {
    param([string]$n)
    $n = $n.ToLower() -replace '[^\w\s]', ' ' -replace '\s+', ' ' -replace ' gmbh| e\.v\.| e v', ''
    $n = $n.Trim()
    $n = $n -replace 'universität', 'university'
    $n = $n -replace 'universitaet', 'university'
    $n = $n -replace 'hochschule', 'university'
    $n = $n -replace 'fachhochschule', 'university'
    $n = $n -replace 'technische universität', 'technical university'
    $n = $n -replace 'technische', 'technical'
    $n = $n -replace 'freie universität', 'free university'
    $n = $n -replace 'pädagogische', 'educational'
    return $n.Trim()
}

# Generate multiple forms for matching
function Forms {
    param([string]$n)
    $f = @()
    $f += $n.ToLower()
    $norm = Norm $n
    $f += $norm
    # Remove "university of applied sciences"
    $short = $norm -replace 'university of applied sciences', ''
    $short = $short -replace 'university of ', ''
    $short = $short -replace 'technical university', ''
    $short = $short -replace 'free university', ''
    $short = $short -replace '\s+', ' '; $short = $short.Trim()
    if ($short -and $short -ne $norm) { $f += $short }
    # Just city
    $f += ($n -split ',')[0].Trim().ToLower()
    return $f | Where-Object { $_ -ne '' } | Select-Object -Unique
}

# Pre-compute DAAD forms
$daadForms = @{}
foreach ($k in $daadUnis.Keys) {
    $daadForms[$k] = Forms $k
}

# Manual name mappings (BA name -> DAAD name)
$manualMap = @{
    "Universität Jena" = "Friedrich Schiller University Jena"
    "TU Berlin" = "Technische Universität Berlin"
    "TU Braunschweig" = "Technische Universität Braunschweig"
    "TU Clausthal" = "Clausthal University of Technology"
    "TU Darmstadt" = "Technische Universität Darmstadt"
    "TU Dresden" = "Technische Universität Dresden"
    "TU Hamburg" = "Technische Universität Hamburg"
    "TU Ilmenau" = "Technische Universität Ilmenau"
    "TU München" = "Technical University of Munich"
    "TU Dortmund" = "Technical University of Dortmund"
    "FH Aachen" = "FH Aachen University of Applied Sciences"
    "Universität Hamburg" = "University of Hamburg"
    "Universität zu Köln" = "University of Cologne"
    "Universität Leipzig" = "University of Leipzig"
    "Universität Bonn" = "University of Bonn"
    "Universität Frankfurt am Main" = "Goethe University Frankfurt"
    "Universität Freiburg" = "University of Freiburg"
    "Universität Heidelberg" = "Heidelberg University"
    "Universität Tübingen" = "Eberhard Karls Universität Tübingen"
    "Universität Mannheim" = "University of Mannheim"
    "Universität Bielefeld" = "Bielefeld University"
    "Universität Bremen" = "University of Bremen"
    "Universität Kassel" = "University of Kassel"
    "Universität Duisburg-Essen" = "University of Duisburg-Essen"
    "Universität Potsdam" = "University of Potsdam"
    "Universität Bayreuth" = "University of Bayreuth"
    "Universität Regensburg" = "University of Regensburg"
    "Universität Erlangen-Nürnberg" = "Friedrich-Alexander-Universität Erlangen-Nürnberg"
    "Universität Würzburg" = "Julius-Maximilians-Universität Würzburg"
    "Universität Ulm" = "Ulm University"
    "Universität Konstanz" = "University of Konstanz"
    "Universität Düsseldorf" = "Heinrich Heine University Düsseldorf"
    "Universität Mainz" = "Johannes Gutenberg University Mainz"
    "Universität Göttingen" = "University of Göttingen"
    "Universität Marburg" = "Philipps-Universität Marburg"
    "Universität Gießen" = "Justus Liebig University Giessen"
    "Universität Kiel" = "Kiel University"
    "Universität Greifswald" = "University of Greifswald"
    "Universität Halle-Wittenberg" = "Martin Luther University Halle-Wittenberg"
    "Universität zu Lübeck" = "University of Lübeck"
    "Universität Oldenburg" = "Carl von Ossietzky University of Oldenburg"
    "Universität Hildesheim" = "University of Hildesheim"
    "Universität Koblenz" = "University of Koblenz"
    "Universität Trier" = "University of Trier"
    "Universität des Saarlandes" = "Saarland University"
    "Universität der Bundeswehr München" = "Universität der Bundeswehr München"
    "Universität der Künste Berlin" = "Berlin University of the Arts"
    "Universität Flensburg" = "Europa-Universität Flensburg"
    "Humboldt-Universität zu Berlin" = "Humboldt-Universität zu Berlin"
    "Freie Universität Berlin" = "Freie Universität Berlin"
    "RWTH Aachen" = "RWTH Aachen University"
    "KIT Karlsruhe" = "Karlsruhe Institute of Technology"
    "Universität Stuttgart" = "University of Stuttgart"
    "Universität Hannover" = "Leibniz University Hannover"
    "Universität Hohenheim" = "University of Hohenheim"
    "Universität Osnabrück" = "University of Osnabrück"
    "Universität Passau" = "University of Passau"
    "Universität Wuppertal" = "Bergische Universität Wuppertal"
    "Universität Paderborn" = "Paderborn University"
    "Universität Siegen" = "University of Siegen"
    "Universität Erfurt" = "University of Erfurt"
    "Universität Weimar" = "Bauhaus-Universität Weimar"
    "Universität Kaiserslautern" = "RPTU University Kaiserslautern-Landau"
    "Universität Magdeburg" = "Otto von Guericke University Magdeburg"
    "Universität Rostock" = "University of Rostock"
    "Universität Chemnitz" = "Chemnitz University of Technology"
    "Universität Cottbus" = "Brandenburg University of Technology Cottbus-Senftenberg"
    "Universität Bamberg" = "Otto-Friedrich-Universität Bamberg"
    "BTU Cottbus-Senftenberg" = "Brandenburg University of Technology Cottbus-Senftenberg"
    "HTW Berlin" = "Berliner Hochschule für Technik"
    "HAW Hamburg" = "Hamburg University of Applied Sciences"
    "Hochschule München" = "Munich University of Applied Sciences"
    "Hochschule Bremen" = "Bremen University of Applied Sciences"
    "Hochschule Darmstadt" = "Darmstadt University of Applied Sciences"
    "Hochschule Frankfurt" = "Frankfurt University of Applied Sciences"
    "Hochschule RheinMain" = "RheinMain University of Applied Sciences"
    "Hochschule Bonn-Rhein-Sieg" = "Bonn-Rhein-Sieg University of Applied Sciences"
    "Hochschule Furtwangen" = "Furtwangen University"
    "Hochschule Reutlingen" = "Reutlingen University"
    "Hochschule Esslingen" = "Esslingen University of Applied Sciences"
    "Hochschule Ulm" = "Ulm University of Applied Sciences"
    "Hochschule Pforzheim" = "Pforzheim University"
    "Hochschule Mannheim" = "Mannheim University of Applied Sciences"
    "Hochschule Karlsruhe" = "Karlsruhe University of Applied Sciences"
    "Hochschule Offenburg" = "Offenburg University of Applied Sciences"
    "Hochschule Ravensburg-Weingarten" = "Weingarten University of Applied Sciences"
    "Hochschule Konstanz" = "Konstanz University of Applied Sciences"
    "Hochschule Augsburg" = "Augsburg University of Applied Sciences"
    "Hochschule Nürnberg" = "Technische Hochschule Nürnberg Georg Simon Ohm"
    "Hochschule Regensburg" = "Regensburg University of Applied Sciences"
    "Hochschule Landshut" = "Landshut University of Applied Sciences"
    "Hochschule Hof" = "Hof University of Applied Sciences"
    "Hochschule Coburg" = "Coburg University of Applied Sciences and Arts"
    "Hochschule Würzburg-Schweinfurt" = "Würzburg-Schweinfurt University of Applied Sciences"
    "Hochschule Aschaffenburg" = "Aschaffenburg University of Applied Sciences"
    "Hochschule Deggendorf" = "Deggendorf Institute of Technology"
    "Hochschule Kempten" = "Kempten University of Applied Sciences"
    "Hochschule Neu-Ulm" = "Neu-Ulm University of Applied Sciences"
    "Hochschule Rosenheim" = "Rosenheim University of Applied Sciences"
    "Hochschule Weihenstephan-Triesdorf" = "Weihenstephan-Triesdorf University of Applied Sciences"
    "Hochschule Amberg-Weiden" = "Amberg-Weiden University of Applied Sciences"
    "Hochschule Niederrhein" = "Niederrhein University of Applied Sciences"
    "Hochschule Düsseldorf" = "Düsseldorf University of Applied Sciences"
    "Hochschule Bochum" = "Bochum University of Applied Sciences"
    "Hochschule Ruhr West" = "Ruhr West University of Applied Sciences"
    "Hochschule Hamm-Lippstadt" = "Hamm-Lippstadt University of Applied Sciences"
    "Hochschule Ostwestfalen-Lippe" = "OWL University of Applied Sciences"
    "Hochschule Bielefeld" = "Bielefeld University of Applied Sciences"
    "Hochschule Münster" = "Münster University of Applied Sciences"
    "Fachhochschule Aachen" = "FH Aachen University of Applied Sciences"
    "Fachhochschule Dortmund" = "Dortmund University of Applied Sciences and Arts"
    "Fachhochschule Erfurt" = "Erfurt University of Applied Sciences"
    "Fachhochschule Jena" = "Ernst-Abbe-Hochschule Jena"
    "Fachhochschule Kiel" = "Kiel University of Applied Sciences"
    "Fachhochschule Lübeck" = "Lübeck University of Applied Sciences"
    "Fachhochschule Osnabrück" = "Osnabrück University of Applied Sciences"
    "Fachhochschule Potsdam" = "Fachhochschule Potsdam"
    "Fachhochschule Münster" = "Münster University of Applied Sciences"
    "Fachhochschule Südwestfalen" = "Südwestfalen University of Applied Sciences"
    "Fachhochschule Westküste" = "West Coast University of Applied Sciences"
    "Fachhochschule Flensburg" = "Flensburg University of Applied Sciences"
    "Fachhochschule Wedel" = "Fachhochschule Wedel"
    "Fachhochschule des Mittelstands" = "Fachhochschule des Mittelstands (FHM)"
    "Medizinische Hochschule Hannover" = "Hannover Medical School"
    "Staatliche Hochschule für Musik und Darstellende Kunst Stuttgart" = "State University of Music and Performing Arts Stuttgart"
    "Hochschule für Musik und Theater Leipzig" = "Leipzig University of Music and Theatre"
    "Hochschule für Musik, Theater und Medien Hannover" = "Hanover University of Music, Drama and Media"
    "Hochschule für Musik und Theater München" = "University of Music and Performing Arts Munich"
    "Hochschule für Musik und Theater Rostock" = "Rostock University of Music and Theatre"
    "Hochschule für Musik Weimar" = "Weimar Music School"
    "Hochschule für Bildende Künste Dresden" = "Dresden Academy of Fine Arts"
    "Hochschule für Bildende Künste Braunschweig" = "Braunschweig University of Art"
    "Hochschule für Grafik und Buchkunst Leipzig" = "Leipzig Academy of Visual Arts"
    "Hochschule für Künste Bremen" = "University of the Arts Bremen"
    "Hochschule für Künste im Sozialen, Ottersberg" = "Hochschule für Künste im Sozialen, Ottersberg"
    "Hochschule für Schauspielkunst Ernst Busch" = "Ernst Busch Academy of Dramatic Arts"
    "Hochschule für Musik Detmold" = "Detmold University of Music"
    "Hochschule für Musik Nürnberg" = "Nuremberg University of Music"
    "Hochschule für Evangelische Kirchenmusik Bayreuth" = "University of Bayreuth"
    "Hochschule für Katholische Kirchenmusik und Musikpädagogik Regensburg" = "University of Regensburg"
    "Hochschule der Bildenden Künste Saar" = "Saar University of Fine Arts"
    "Kunsthochschule Kassel" = "University of Kassel"
    "Kunstakademie Düsseldorf" = "Kunstakademie Düsseldorf"
    "Akademie der Bildenden Künste München" = "Akademie der Bildenden Künste München"
    "Akademie der Bildenden Künste Nürnberg" = "Akademie der Bildenden Künste Nürnberg"
    "Filmuniversität Babelsberg" = "Film University Babelsberg KONRAD WOLF"
    "Deutsche Film- und Fernsehakademie Berlin" = "German Film and Television Academy Berlin"
    "Pädagogische Hochschule Freiburg" = "University of Education Freiburg"
    "Pädagogische Hochschule Heidelberg" = "University of Education Heidelberg"
    "Pädagogische Hochschule Karlsruhe" = "University of Education Karlsruhe"
    "Pädagogische Hochschule Ludwigsburg" = "Ludwigsburg University of Education"
    "Pädagogische Hochschule Schwäbisch Gmünd" = "University of Education Schwäbisch Gmünd"
    "Pädagogische Hochschule Weingarten" = "Weingarten University of Education"
    "Pädagogische Hochschule Thurgau" = "University of Education Thurgau"
    "Pädagogische Hochschule Zürich" = "Zurich University of Teacher Education"
    "Theologische Hochschule Friedensau" = "Friedensau Adventist University"
    "Theologische Hochschule Reutlingen" = "Reutlingen School of Theology"
    "Kirchliche Hochschule Wuppertal" = "Kirchliche Hochschule Wuppertal/Bethel"
    "Philosophisch-Theologische Hochschule Münster" = "Philosophisch-Theologische Hochschule Münster"
    "Philosophisch-Theologische Hochschule Sankt Georgen" = "Sankt Georgen Graduate School of Philosophy and Theology"
    "Augustana-Hochschule Neuendettelsau" = "Augustana-Hochschule Neuendettelsau"
    "Hochschule für Philosophie München" = "Munich School of Philosophy"
    "DIPLOMA Hochschule" = "DIPLOMA University of Applied Sciences"
    "FOM Hochschule" = "FOM University of Applied Sciences"
    "HSB Hochschule Bremen" = "Bremen University of Applied Sciences"
    "Hochschule Fresenius" = "Hochschule Fresenius"
    "Hochschule Fresenius Heidelberg" = "Hochschule Fresenius"
    "Hochschule Fresenius Idstein" = "Hochschule Fresenius"
    "Hochschule Fresenius München" = "Hochschule Fresenius"
    "Hochschule Fresenius Berlin" = "Hochschule Fresenius"
    "Hochschule Fresenius Hamburg" = "Hochschule Fresenius"
    "Hochschule Fresenius Köln" = "Hochschule Fresenius"
    "Hochschule Fresenius Düsseldorf" = "Hochschule Fresenius"
    "SRH Hochschule Berlin" = "SRH Berlin University of Applied Sciences"
    "SRH Hochschule Heidelberg" = "SRH Heidelberg University"
    "SRH Hochschule Nordrhein-Westfalen" = "SRH University of Applied Sciences North Rhine-Westphalia"
    "SRH Hochschule in Nordrhein-Westfalen" = "SRH University of Applied Sciences North Rhine-Westphalia"
    "Frankfurt University of Applied Sciences" = "Frankfurt University of Applied Sciences"
    "IST-Hochschule für Management" = "IST University of Applied Sciences"
    "IST Studieninstitut" = "IST University of Applied Sciences"
    "Bard College Berlin" = "Bard College Berlin"
    "Berlin International University of Applied Sciences" = "Berlin International University of Applied Sciences"
    "Constructor University" = "Constructor University"
    "Munich Business School" = "Munich Business School"
    "Gisma University of Applied Sciences" = "Gisma University of Applied Sciences"
    "GISMA Business School" = "Gisma University of Applied Sciences"
    "Hertie School" = "Hertie School"
    "EU|FH" = "EU|FH University of Applied Sciences"
    "EU FH" = "EU|FH University of Applied Sciences"
    "UE University of Applied Sciences Europe" = "University of Applied Sciences Europe"
    "Hochschule für Wirtschaft und Umwelt Nürtingen-Geislingen" = "Nürtingen-Geislingen University of Applied Sciences"
    "Hochschule Geisenheim" = "Hochschule Geisenheim University"
    "Hochschule Harz" = "Harz University of Applied Sciences"
    "Hochschule Merseburg" = "Merseburg University of Applied Sciences"
    "Hochschule Nordhausen" = "Nordhausen University of Applied Sciences"
    "Hochschule Schmalkalden" = "Schmalkalden University of Applied Sciences"
    "Hochschule Zittau/Görlitz" = "Zittau/Görlitz University of Applied Sciences"
    "Hochschule Mittweida" = "Mittweida University of Applied Sciences"
    "Hochschule für Technik und Wirtschaft Dresden" = "Dresden University of Applied Sciences"
    "Hochschule für Technik und Wirtschaft Berlin" = "Berlin University of Applied Sciences and Technology"
    "Hochschule für Technik und Wirtschaft des Saarlandes" = "htw saar - University of Applied Sciences"
    "Hochschule für Wirtschaft und Recht Berlin" = "Berlin School of Economics and Law"
    "Hochschule für Technik Stuttgart" = "Stuttgart University of Applied Sciences"
    "Hochschule für Wirtschaft und Gesellschaft Ludwigshafen" = "Ludwigshafen University of Business and Society"
    "Hochschule für angewandte Wissenschaften Ansbach" = "Ansbach University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Würzburg-Schweinfurt" = "Würzburg-Schweinfurt University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Hof" = "Hof University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Kempten" = "Kempten University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Neu-Ulm" = "Neu-Ulm University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften München" = "Munich University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Hamburg" = "Hamburg University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Augsburg" = "Augsburg University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Landshut" = "Landshut University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Weihenstephan-Triesdorf" = "Weihenstephan-Triesdorf University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Coburg" = "Coburg University of Applied Sciences and Arts"
    "Hochschule für angewandte Wissenschaften Regensburg" = "Regensburg University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Rosenheim" = "Rosenheim University of Applied Sciences"
    "Hochschule für angewandte Wissenschaften Amberg-Weiden" = "Amberg-Weiden University of Applied Sciences"
    "Wilhelm Büchner Hochschule" = "Wilhelm Büchner University of Technology"
    "accadis Hochschule" = "accadis Hochschule Bad Homburg"
    "accadis Hochschule GmbH" = "accadis Hochschule Bad Homburg"
    "Steinbeis Hochschule" = "Steinbeis University Berlin"
    "EU Business School" = "EU Business School"
    "HHL Leipzig Graduate School of Management" = "HHL Leipzig Graduate School of Management"
    "WHU - Otto Beisheim School of Management" = "WHU - Otto Beisheim School of Management"
    "ESCP Business School" = "ESCP Business School"
    "EBS Universität" = "EBS University"
    "Frankfurt School of Finance & Management" = "Frankfurt School of Finance & Management"
    "International Psychoanalytic University" = "International Psychoanalytic University Berlin"
    "International Psychoanalytic University Berlin" = "International Psychoanalytic University Berlin"
    "Psychologische Hochschule Berlin" = "Psychologische Hochschule Berlin"
    "Leuphana Universität Lüneburg" = "Leuphana University Lüneburg"
    "Zeppelin Universität" = "Zeppelin University"
    "Quadriga Hochschule Berlin" = "Quadriga University of Applied Sciences"
    "Viadrina" = "European University Viadrina"
    "Europa-Universität Viadrina" = "European University Viadrina"

}

Write-Output ("Manual map entries: " + $manualMap.Count)

# Do matching
$uniMatches = @{}  # banId -> DAAD uni name

# Strategy 1: Exact normalized form match
$banForms = @{}
foreach ($banId in $baUnis.Keys) {
    $banForms[$banId] = Forms $baUnis[$banId].name
}

foreach ($banId in $baUnis.Keys) {
    $bestMatch = $null
    $bestScore = -1
    
    foreach ($daadKey in $daadUnis.Keys) {
        $score = 0
        $baF = $banForms[$banId]
        $daadF = $daadForms[$daadKey]
        
        # Check all combinations
        :outer foreach ($bf in $baF) {
            foreach ($df in $daadF) {
                if ($bf -eq $df) {
                    $score = 100
                    break outer
                }
            }
        }
        
        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = $daadKey
        }
    }
    
    if ($bestScore -ge 100) {
        $uniMatches[$banId] = $bestMatch
    }
}
Write-Output ("Exact norm matches: " + $uniMatches.Count)

# Strategy 2: Manual map
$remaining = $baUnis.Keys | Where-Object { -not $uniMatches.ContainsKey($_) }
foreach ($banId in $remaining) {
    $baName = $baUnis[$banId].name
    if ($manualMap.ContainsKey($baName)) {
        $daadTarget = $manualMap[$baName]
        # Find the DAAD key that matches the target
        foreach ($daadKey in $daadUnis.Keys) {
            if ($daadUnis[$daadKey].name -eq $daadTarget -or $daadForms[$daadKey] -contains $daadTarget.ToLower()) {
                # Double check: if this daadKey was already matched to a different BA uni, check if it's truly the same
                $uniMatches[$banId] = $daadKey
                break
            }
        }
        # If no exact match, try contains
        if (-not $uniMatches.ContainsKey($banId)) {
            foreach ($daadKey in $daadUnis.Keys) {
                $daadName = $daadUnis[$daadKey].name.ToLower()
                $target = $daadTarget.ToLower()
                if ($daadName -eq $target -or $daadName -like "*$target*" -or $target -like "*$daadName*") {
                    $uniMatches[$banId] = $daadKey
                    break
                }
            }
        }
    }
}
Write-Output ("After manual map: " + $uniMatches.Count)

# Now match programs: for each BA program, find DAAD counterpart
$matchedCount = 0
$programUpdates = @()  # List of hashtables with banId, programName, update fields

foreach ($baProg in $baData) {
    $banId = $baProg.universityBanId
    if (-not $uniMatches.ContainsKey($banId)) { continue }
    
    $daadKey = $uniMatches[$banId]
    $daadProgs = $daadUnis[$daadKey].programs
    
    # Try to match program by name
    $baName = $baProg.name.ToLower() -replace '[^\w\s]', '' -replace '\s+', ' '
    # Filter out generic words that don't help matching
    $genericWords = @('master', 'bachelor', 'of', 'science', 'arts', 'und', 'der', 'die', 'das', 'for', 'the', 'and', 'mit', 'von', 'im', 'am', 'in', 'msc', 'ma', 'mba', 'ba', 'bsc', 'llm', 'meng', 'phd', 'dr', 'rer', 'nat', 'phil')
    $baWords = $baName -split ' ' | Where-Object { $_.Length -gt 2 -and $_ -notin $genericWords }
    
    # Skip programs with generic names (less than 2 substantive words)
    # e.g. "Management Master" -> only "management" is substantive
    if ($baWords.Count -lt 2) { continue }
    
    $bestMatchProg = $null
    $bestProgScore = 0
    
    foreach ($dp in $daadProgs) {
        $dpName = $dp.courseName.ToLower() -replace '[^\w\s]', '' -replace '\s+', ' '
        $dpWords = $dpName -split ' ' | Where-Object { $_.Length -gt 2 -and $_ -notin $genericWords }
        
        # Skip DAAD programs with very generic names too
        if ($dpWords.Count -lt 2) { continue }
        
        $common = $baWords | Where-Object { $_ -in $dpWords }
        $union = ($baWords + $dpWords) | Select-Object -Unique
        $jaccard = if ($union.Count -gt 0) { [double]$common.Count / $union.Count } else { 0 }
        $baRatio = if ($baWords.Count -gt 0) { [double]$common.Count / $baWords.Count } else { 0 }
        
        # Score: Jaccard similarity, require at least half of BA words to match
        $score = $jaccard
        if ($baRatio -lt 0.5) { $score = 0 }
        
        # Bonus: one name contains the other (common words removed comparison)
        $baCompact = $baWords -join ''
        $dpCompact = $dpWords -join ''
        if ($baCompact -eq $dpCompact) {
            $score = 1.0
        } elseif ($baCompact -like "*$dpCompact*" -or $dpCompact -like "*$baCompact*") {
            $score = [math]::Max($score, 0.85)
        }
        
        if ($score -gt $bestProgScore) {
            $bestProgScore = $score
            $bestMatchProg = $dp
        }
    }
    
    if ($bestProgScore -ge 0.7 -and $bestMatchProg -ne $null) {
        $matchedCount++
        $programUpdates += @{
            banId = $banId
            baProgramName = $baProg.name
            daadProgram = $bestMatchProg
            score = $bestProgScore
            baUniName = $baUnis[$banId].name
        }
    }
}

Write-Output ("`nProgram matches: " + $matchedCount + " / " + $baData.Count)

# Show some matched examples
Write-Output "`nSample matched programs:"
$programUpdates | Sort-Object -Property score -Descending | Select-Object -First 20 | ForEach-Object {
    Write-Output ("  [" + [math]::Round($_.score,2) + "] " + $_.baUniName + " | " + $_.baProgramName + " -> " + $_.daadProgram.courseName)
}

# Now generate the SQL
$sqlLines = @()
$sqlLines += "-- Generated by match_daad_to_ba.ps1"
$sqlLines += "-- Matches " + $matchedCount + " BA programs to DAAD programs"
$sqlLines += ""
$sqlLines += "BEGIN;"
$sqlLines += ""

# Helper to escape SQL strings
function SqlVal {
    param([string]$s)
    if ([string]::IsNullOrEmpty($s)) { return 'NULL' }
    return "'" + $s.Replace("'", "''") + "'"
}

function Get-Tuition {
    param([string]$val)
    if ([string]::IsNullOrEmpty($val) -or $val -eq 'none') { return '0' }
    if ($val -eq 'varied') { return '0' }
    $num = [regex]::Match($val, '\d[\d,]*').Value
    if ($num) { return $num.Replace(',', '') }
    return '0'
}

function Get-Deadline {
    param([string]$val)
    if ([string]::IsNullOrEmpty($val)) { return 'NULL' }
    # Clean HTML tags
    $clean = $val -replace '<[^>]*>', ' '
    $clean = $clean -replace '\s+', ' '
    $clean = $clean.Trim()
    # If too long, extract key date phrases
    if ($clean.Length -gt 200) {
        # Try to find date patterns
        $dates = [regex]::Matches($clean, '\d{1,2}\s+(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)')
        if ($dates.Count -gt 0) {
            $dateStr = ($dates.Value | Select-Object -Unique) -join ' / '
            return (SqlVal $dateStr)
        }
        if ($clean -match 'deadline.*?\d') { $clean = $matches[0] }
        if ($clean.Length -gt 200) { $clean = $clean.Substring(0, 200) + '...' }
    }
    return (SqlVal $clean)
}

function Get-Language {
    param([string]$val)
    if ([string]::IsNullOrEmpty($val)) { return 'NULL' }
    if ($val -match 'German.*English|English.*German') { return "'Both'" }
    if ($val -match 'English') { return "'English'" }
    if ($val -match 'German') { return "'German'" }
    return (SqlVal $val)
}

function Get-RequiresIelts {
    param([string]$lang)
    if ([string]::IsNullOrEmpty($lang)) { return 'false' }
    if ($lang -match 'English') { return 'true' }
    return 'false'
}

function Get-Duration {
    param([string]$val)
    if ([string]::IsNullOrEmpty($val)) { return 'NULL' }
    $nums = [regex]::Matches($val, '\d+')
    if ($nums.Count -gt 0) { return (SqlVal ($nums[0].Value + ' semesters')) }
    return (SqlVal $val)
}

$updateCount = 0
foreach ($pu in $programUpdates) {
    $dp = $pu.daadProgram
    
    $daadLink = "https://www2.daad.de/deutschland/studienangebote/international-programmes/en/detail/" + $dp.id + "/"
    $banIdQuoted = SqlVal $pu.banId
    $progNameQuoted = SqlVal $pu.baProgramName
    $daadLinkQuoted = SqlVal $daadLink
    
    $sql = "UPDATE public.university_programs SET"
    $sql += "`n    tuition_fee_per_year = $(Get-Tuition $dp.tuitionFees),"
    $sql += "`n    deadline = $(Get-Deadline $dp.applicationDeadline),"
    $sql += "`n    instruction_language = $(Get-Language $dp.languages),"
    $sql += "`n    requires_ielts = $(Get-RequiresIelts $dp.languages),"
    $sql += "`n    duration = $(Get-Duration $dp.programmeDuration),"
    $sql += "`n    data_source = 'daad_api',"
    $sql += "`n    link = $daadLinkQuoted"
    $sql += "`nWHERE"
    $sql += "`n    university_id = (SELECT id FROM public.universities WHERE ba_ban_id = $banIdQuoted LIMIT 1)"
    $sql += "`n    AND program_name = $progNameQuoted;"
    
    $sqlLines += $sql
    $updateCount++
    
    if ($updateCount % 1000 -eq 0) {
        Write-Output ("  Generated " + $updateCount + " UPDATE statements...")
    }
}

$sqlLines += ""
$sqlLines += "COMMIT;"

# Write SQL file
Set-Content -Path $outputSql -Value ($sqlLines -join "`n") -Encoding UTF8
Write-Output ("`nSaved " + $updateCount + " UPDATE statements to 005_update_from_daad.sql")
Write-Output "Done!"
