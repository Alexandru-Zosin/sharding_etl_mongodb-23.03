-- ============================================================
-- QUERY-URI SQL ADAPTATE PE SCHEMA CURENTA SYNTHIA
-- Structura: Bianca / Andreea / Alex
-- Fiecare query contine: comentariu + interogarea SQL
-- ============================================================

-- ============================================================
-- BIANCA
-- ============================================================

-- 1. Top 5 proceduri efectuate cel mai des.
SELECT
    pr.description,
    COUNT(*) AS total
FROM procedures pr
GROUP BY pr.description
ORDER BY total DESC, pr.description ASC
LIMIT 5;


-- 2. Cati pacienti distincti are fiecare payer.
SELECT
    py.name AS payer_name,
    COUNT(DISTINCT e.patient) AS nr_pacienti
FROM encounters e
JOIN payers py ON py.id = e.payer
GROUP BY py.name
ORDER BY nr_pacienti DESC, py.name ASC;


-- 3. Conditiile medicale pe gen.
SELECT
    p.gender,
    c.description AS condition_description,
    COUNT(*) AS total
FROM conditions c
JOIN patients p ON p.id = c.patient
GROUP BY p.gender, c.description
ORDER BY p.gender ASC, total DESC, c.description ASC;


-- 4. Ce payers acopera cele mai mari costuri totale ale encounter-urilor.
SELECT
    py.name AS payer_name,
    SUM(e.payer_coverage) AS total_covered,
    SUM(e.total_claim_cost) AS total_claim_cost
FROM encounters e
JOIN payers py ON py.id = e.payer
GROUP BY py.name
ORDER BY total_covered DESC, total_claim_cost DESC, py.name ASC;


-- ============================================================
-- ANDREEA
-- ============================================================

-- 1. Top 5 pacienti cu cele mai multe proceduri efectuate.
SELECT
    pr.patient AS patient_id,
    COUNT(*) AS total_proceduri
FROM procedures pr
GROUP BY pr.patient
ORDER BY total_proceduri DESC, pr.patient ASC
LIMIT 5;


-- 2. Numarul de encounter-uri per organizatie.
SELECT
    o.name AS organization_name,
    COUNT(*) AS total_encounters
FROM encounters e
JOIN organizations o ON o.id = e.organization
GROUP BY o.name
ORDER BY total_encounters DESC, o.name ASC;


-- 3. Costul total al procedurilor per pacient, doar pentru pacientii cu total > 1000.
SELECT
    pr.patient AS patient_id,
    SUM(pr.base_cost) AS total_cost
FROM procedures pr
GROUP BY pr.patient
HAVING SUM(pr.base_cost) > 1000
ORDER BY total_cost DESC, pr.patient ASC;


-- 4. Cele mai frecvente conditii pentru pacientii care au avut cel putin o procedura.
SELECT
    c.description,
    COUNT(*) AS total
FROM conditions c
WHERE EXISTS (
    SELECT 1
    FROM procedures pr
    WHERE pr.patient = c.patient
)
GROUP BY c.description
ORDER BY total DESC, c.description ASC;


-- ============================================================
-- ALEX
-- 5 query-uri noi, in acelasi stil cu exemplele din 01-04 / 01-05
-- ============================================================

-- 1. Numarul de encounter-uri pentru fiecare clasa de encounter.
SELECT
    e.encounter_class,
    COUNT(*) AS total_encounters
FROM encounters e
GROUP BY e.encounter_class
ORDER BY total_encounters DESC, e.encounter_class ASC;


-- 2. Top 10 observatii cel mai des inregistrate.
SELECT
    o.description,
    COUNT(*) AS total_observations
FROM observations o
GROUP BY o.description
ORDER BY total_observations DESC, o.description ASC
LIMIT 10;


-- 3. Pacientii care au cel putin doua alergii distincte.
SELECT
    a.patient AS patient_id,
    COUNT(*) AS total_allergies
FROM allergies a
GROUP BY a.patient
HAVING COUNT(*) >= 2
ORDER BY total_allergies DESC, a.patient ASC;


-- 4. Costul mediu al encounter-urilor pentru fiecare payer.
SELECT
    py.name AS payer_name,
    AVG(e.total_claim_cost) AS avg_claim_cost,
    COUNT(*) AS total_encounters
FROM encounters e
JOIN payers py ON py.id = e.payer
GROUP BY py.name
ORDER BY avg_claim_cost DESC, py.name ASC;


-- 5. Furnizorii cu cele mai multe encounter-uri, impreuna cu organizatia lor.
SELECT
    p.name AS provider_name,
    o.name AS organization_name,
    p.encounters AS total_encounters
FROM providers p
JOIN organizations o ON o.id = p.organization
ORDER BY p.encounters DESC, p.name ASC
LIMIT 10;
