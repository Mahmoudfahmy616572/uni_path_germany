-- Populate program_url from existing DAAD link data
-- The link column already contains DAAD program detail URLs from 005_update_from_daad.sql
UPDATE university_programs
SET program_url = link
WHERE link IS NOT NULL AND link != '' AND program_url IS NULL;

-- Populate website_url for universities based on common German naming patterns.
-- This is a best-effort heuristic — verify and fix manually.
UPDATE universities
SET website_url = CASE
    -- Technische Universität / TU
    WHEN name ILIKE 'technische universität%' OR name ILIKE 'tu %' THEN
        CASE
            WHEN name ILIKE '%münchen%' THEN 'https://www.tum.de'
            WHEN name ILIKE '%berlin%' THEN 'https://www.tu-berlin.de'
            WHEN name ILIKE '%braunschweig%' THEN 'https://www.tu-braunschweig.de'
            WHEN name ILIKE '%chemnitz%' THEN 'https://www.tu-chemnitz.de'
            WHEN name ILIKE '%clausthal%' THEN 'https://www.tu-clausthal.de'
            WHEN name ILIKE '%darmstadt%' THEN 'https://www.tu-darmstadt.de'
            WHEN name ILIKE '%dresden%' THEN 'https://tu-dresden.de'
            WHEN name ILIKE '%bergakademie freiberg%' THEN 'https://tu-freiberg.de'
            WHEN name ILIKE '%hamburg%' THEN 'https://www.tuhh.de'
            WHEN name ILIKE '%harburg%' THEN 'https://www.tuhh.de'
            WHEN name ILIKE '%ilmenau%' THEN 'https://www.tu-ilmenau.de'
            WHEN name ILIKE '%kaiserslautern%' THEN 'https://www.uni-kl.de'
            WHEN name ILIKE '%cottbus%' THEN 'https://www.b-tu.de'
            WHEN name ILIKE '%dortmund%' THEN 'https://www.tu-dortmund.de'
            ELSE 'https://www.' || regexp_replace(lower(name), '[^a-zA-Z0-9]', '-', 'g') || '.de'
        END
    -- Universität
    WHEN name ILIKE 'universität%' OR name ILIKE 'universitaet%' THEN
        CASE
            WHEN name ILIKE '%augsburg%' THEN 'https://www.uni-augsburg.de'
            WHEN name ILIKE '%bamberg%' THEN 'https://www.uni-bamberg.de'
            WHEN name ILIKE '%bayreuth%' THEN 'https://www.uni-bayreuth.de'
            WHEN name ILIKE '%bonn%' THEN 'https://www.uni-bonn.de'
            WHEN name ILIKE '%bremen%' THEN 'https://www.uni-bremen.de'
            WHEN name ILIKE '%köln%' THEN 'https://www.uni-koeln.de'
            WHEN name ILIKE '%düsseldorf%' THEN 'https://www.uni-duesseldorf.de'
            WHEN name ILIKE '%erfurt%' THEN 'https://www.uni-erfurt.de'
            WHEN name ILIKE '%erlangen%' THEN 'https://www.fau.de'
            WHEN name ILIKE '%nürnberg%' THEN 'https://www.fau.de'
            WHEN name ILIKE '%essen%' THEN 'https://www.uni-due.de'
            WHEN name ILIKE '%frankfurt%' THEN 'https://www.uni-frankfurt.de'
            WHEN name ILIKE '%freiburg%' THEN 'https://www.uni-freiburg.de'
            WHEN name ILIKE '%göttingen%' THEN 'https://www.uni-goettingen.de'
            WHEN name ILIKE '%greifswald%' THEN 'https://www.uni-greifswald.de'
            WHEN name ILIKE '%halle%' THEN 'https://www.uni-halle.de'
            WHEN name ILIKE '%hamburg%' AND name ILIKE '%universität%' THEN 'https://www.uni-hamburg.de'
            WHEN name ILIKE '%hannover%' THEN 'https://www.uni-hannover.de'
            WHEN name ILIKE '%heidelberg%' THEN 'https://www.uni-heidelberg.de'
            WHEN name ILIKE '%hohenheim%' THEN 'https://www.uni-hohenheim.de'
            WHEN name ILIKE '%jena%' THEN 'https://www.uni-jena.de'
            WHEN name ILIKE '%kassel%' THEN 'https://www.uni-kassel.de'
            WHEN name ILIKE '%kiel%' THEN 'https://www.uni-kiel.de'
            WHEN name ILIKE '%konstanz%' THEN 'https://www.uni-konstanz.de'
            WHEN name ILIKE '%leipzig%' THEN 'https://www.uni-leipzig.de'
            WHEN name ILIKE '%lübeck%' THEN 'https://www.uni-luebeck.de'
            WHEN name ILIKE '%mainz%' THEN 'https://www.uni-mainz.de'
            WHEN name ILIKE '%mannheim%' THEN 'https://www.uni-mannheim.de'
            WHEN name ILIKE '%marburg%' THEN 'https://www.uni-marburg.de'
            WHEN name ILIKE '%münchen%' AND name ILIKE '%ludwig%' THEN 'https://www.lmu.de'
            WHEN name ILIKE '%münster%' THEN 'https://www.uni-muenster.de'
            WHEN name ILIKE '%oldenburg%' THEN 'https://uol.de'
            WHEN name ILIKE '%osnabrück%' OR name ILIKE '%osnabrueck%' THEN 'https://www.uni-osnabrueck.de'
            WHEN name ILIKE '%paderborn%' THEN 'https://www.uni-paderborn.de'
            WHEN name ILIKE '%passau%' THEN 'https://www.uni-passau.de'
            WHEN name ILIKE '%potsdam%' THEN 'https://www.uni-potsdam.de'
            WHEN name ILIKE '%regensburg%' THEN 'https://www.uni-regensburg.de'
            WHEN name ILIKE '%rostock%' THEN 'https://www.uni-rostock.de'
            WHEN name ILIKE '%saarland%' THEN 'https://www.uni-saarland.de'
            WHEN name ILIKE '%siegen%' THEN 'https://www.uni-siegen.de'
            WHEN name ILIKE '%stuttgart%' THEN 'https://www.uni-stuttgart.de'
            WHEN name ILIKE '%trier%' THEN 'https://www.uni-trier.de'
            WHEN name ILIKE '%tübingen%' OR name ILIKE '%tuebingen%' THEN 'https://uni-tuebingen.de'
            WHEN name ILIKE '%ulm%' THEN 'https://www.uni-ulm.de'
            WHEN name ILIKE '%vechta%' THEN 'https://www.uni-vechta.de'
            WHEN name ILIKE '%würzburg%' THEN 'https://www.uni-wuerzburg.de'
            WHEN name ILIKE '%whu%' THEN 'https://www.whu.edu'
            WHEN name ILIKE '%fernuniversität%' OR name ILIKE '%fernuni%' THEN 'https://www.fernuni-hagen.de'
            WHEN name ILIKE '%witten%' THEN 'https://www.uni-wh.de'
            ELSE 'https://www.' || regexp_replace(lower(name), '[^a-zA-Z0-9]', '-', 'g') || '.de'
        END
    -- Hochschule / Fachhochschule
    WHEN name ILIKE 'hochschule%' OR name ILIKE 'fachhochschule%' THEN
        CASE
            WHEN name ILIKE '%aachen%' THEN 'https://www.fh-aachen.de'
            WHEN name ILIKE '%biberach%' THEN 'https://www.hochschule-bc.de'
            WHEN name ILIKE '%bielefeld%' THEN 'https://www.fh-bielefeld.de'
            WHEN name ILIKE '%bremen%' AND name ILIKE '%hochschule%' THEN 'https://www.hs-bremen.de'
            WHEN name ILIKE '%darmstadt%' THEN 'https://www.h-da.de'
            WHEN name ILIKE '%emden%' THEN 'https://www.hs-emden-leer.de'
            WHEN name ILIKE '%esslingen%' THEN 'https://www.hs-esslingen.de'
            WHEN name ILIKE '%flensburg%' THEN 'https://www.hs-flensburg.de'
            WHEN name ILIKE '%frankfurt%' THEN 'https://www.frankfurt-university.de'
            WHEN name ILIKE '%fresenius%' THEN 'https://www.hs-fresenius.de'
            WHEN name ILIKE '%fulda%' THEN 'https://www.hs-fulda.de'
            WHEN name ILIKE '%giesen%' THEN 'https://www.thm.de'
            WHEN name ILIKE '%hannover%' THEN 'https://www.hs-hannover.de'
            WHEN name ILIKE '%hof%' THEN 'https://www.hof-university.de'
            WHEN name ILIKE '%kempten%' THEN 'https://www.hs-kempten.de'
            WHEN name ILIKE '%kiefer%' THEN 'https://www.hs-koblenz.de'
            WHEN name ILIKE '%koblenz%' THEN 'https://www.hs-koblenz.de'
            WHEN name ILIKE '%konstanz%' THEN 'https://www.htwg-konstanz.de'
            WHEN name ILIKE '%landshut%' THEN 'https://www.haw-landshut.de'
            WHEN name ILIKE '%lübeck%' THEN 'https://www.th-luebeck.de'
            WHEN name ILIKE '%magdeburg%' THEN 'https://www.h2.de'
            WHEN name ILIKE '%mainz%' THEN 'https://www.hs-mainz.de'
            WHEN name ILIKE '%mannheim%' AND (name ILIKE '%hochschule%' OR name ILIKE '%fachhochschule%') THEN 'https://www.hochschule-mannheim.de'
            WHEN name ILIKE '%mittweida%' THEN 'https://www.hs-mittweida.de'
            WHEN name ILIKE '%münchen%' AND (name ILIKE '%hochschule%' OR name ILIKE '%fachhochschule%') THEN 'https://www.hm.edu'
            WHEN name ILIKE '%niederrhein%' THEN 'https://www.hs-niederrhein.de'
            WHEN name ILIKE '%nürtingen%' THEN 'https://www.hfwu.de'
            WHEN name ILIKE '%offenburg%' THEN 'https://www.hs-offenburg.de'
            WHEN name ILIKE '%osnabrück%' OR name ILIKE '%osnabrueck%' THEN 'https://www.hs-osnabrueck.de'
            WHEN name ILIKE '%pforzheim%' THEN 'https://www.hs-pforzheim.de'
            WHEN name ILIKE '%reutlingen%' THEN 'https://www.reutlingen-university.de'
            WHEN name ILIKE '%rosenheim%' THEN 'https://www.th-rosenheim.de'
            WHEN name ILIKE '%schmalkalden%' THEN 'https://www.hs-schmalkalden.de'
            WHEN name ILIKE '%stralsund%' THEN 'https://www.hochschule-stralsund.de'
            WHEN name ILIKE '%stuttgart%' AND name ILIKE '%hochschule%' THEN 'https://www.hft-stuttgart.de'
            WHEN name ILIKE '%trier%' THEN 'https://www.hochschule-trier.de'
            WHEN name ILIKE '%wedel%' THEN 'https://www.fh-wedel.de'
            WHEN name ILIKE '%weihenstephan%' THEN 'https://www.hswt.de'
            WHEN name ILIKE '%wiesbaden%' THEN 'https://www.hs-rm.de'
            WHEN name ILIKE '%würzburg%' AND name ILIKE '%schweinfurt%' THEN 'https://www.thws.de'
            WHEN name ILIKE '%zittau%' THEN 'https://www.hszg.de'
            WHEN name ILIKE '%zweibrücken%' OR name ILIKE '%zweibruecken%' THEN 'https://www.hs-kl.de'
            ELSE 'https://www.' || regexp_replace(lower(name), '[^a-zA-Z0-9]', '-', 'g') || '.de'
        END
    -- Kunst- und Musikhochschulen
    WHEN name ILIKE '%kunst%' OR name ILIKE '%musik%' OR name ILIKE '%film%' THEN
        CASE
            WHEN name ILIKE '%berlin%' AND name ILIKE '%kunst%' THEN 'https://www.udk-berlin.de'
            WHEN name ILIKE '%dresden%' AND name ILIKE '%kunst%' THEN 'https://www.hfbk-dresden.de'
            WHEN name ILIKE '%düsseldorf%' OR name ILIKE '%duesseldorf%' THEN 'https://www.kunstakademie-duesseldorf.de'
            WHEN name ILIKE '%frankfurt%' THEN 'https://www.hfmdk-frankfurt.de'
            WHEN name ILIKE '%hamburg%' THEN 'https://www.hfk-bremen.de'
            WHEN name ILIKE '%hannover%' THEN 'https://www.hmtm-hannover.de'
            WHEN name ILIKE '%karlsruhe%' THEN 'https://www.hfk-karlsruhe.de'
            WHEN name ILIKE '%köln%' OR name ILIKE '%koln%' THEN 'https://www.hfmt-koeln.de'
            WHEN name ILIKE '%leipzig%' THEN 'https://www.hmt-leipzig.de'
            WHEN name ILIKE '%mainz%' THEN 'https://www.kunsthochschule-mainz.de'
            WHEN name ILIKE '%münchen%' OR name ILIKE '%muenchen%' THEN 'https://www.hmtm.de'
            WHEN name ILIKE '%nürnberg%' OR name ILIKE '%nuernberg%' THEN 'https://www.hfm-nuernberg.de'
            WHEN name ILIKE '%stuttgart%' THEN 'https://www.hmdk-stuttgart.de'
            WHEN name ILIKE '%weimar%' THEN 'https://www.hfm-weimar.de'
            WHEN name ILIKE '%würzburg%' OR name ILIKE '%wuerzburg%' THEN 'https://www.hfk-wuerzburg.de'
            ELSE 'https://www.' || regexp_replace(lower(name), '[^a-zA-Z0-9]', '-', 'g') || '.de'
        END
    -- Pädagogische Hochschulen
    WHEN name ILIKE 'pädagogische hochschule%' OR name ILIKE 'paedagogische hochschule%' THEN
        CASE
            WHEN name ILIKE '%freiburg%' THEN 'https://www.ph-freiburg.de'
            WHEN name ILIKE '%heidelberg%' THEN 'https://www.ph-heidelberg.de'
            WHEN name ILIKE '%karlsruhe%' THEN 'https://www.ph-karlsruhe.de'
            WHEN name ILIKE '%ludwigsburg%' THEN 'https://www.ph-ludwigsburg.de'
            WHEN name ILIKE '%schwäbisch%' OR name ILIKE '%schwaebisch%' THEN 'https://www.ph-gmuend.de'
            WHEN name ILIKE '%weingarten%' THEN 'https://www.ph-weingarten.de'
            ELSE 'https://www.' || regexp_replace(lower(name), '[^a-zA-Z0-9]', '-', 'g') || '.de'
        END
    -- Default fallback
    ELSE 'https://www.' || regexp_replace(lower(name), '[^a-zA-Z0-9]', '-', 'g') || '.de'
END
WHERE website_url IS NULL;
