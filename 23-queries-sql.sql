/* =============================================================================
   BIANCA
   ========================================================================== */

/* -----------------------------------------------------------------------------
1. Top 5 afectiuni dupa costul total al encounter-urilor in care au aparut.
   Ideea: nu doar numaram conditiile, ci vedem ce afectiuni apar in encounter-uri
   care au generat costuri mari totale.
----------------------------------------------------------------------------- */
SELECT
    c.description AS conditie,
    COUNT(*) AS nr_aparitii,
    SUM(e.total_claim_cost) AS cost_total_encounteruri,
    ROUND(AVG(e.total_claim_cost), 2) AS cost_mediu_per_aparitie
FROM conditions c
JOIN encounters e
    ON e.id = c.encounter
GROUP BY c.description
HAVING COUNT(*) >= 5
ORDER BY cost_total_encounteruri DESC, nr_aparitii DESC
LIMIT 5;


/* -----------------------------------------------------------------------------
2. Top payers dupa numar de pacienti distincti si cost mediu acoperit per pacient.
   Ideea: nu doar popularitate, ci si cat acopera, in medie, pentru pacientii lor.
----------------------------------------------------------------------------- */
WITH payer_patient_costs AS (
    SELECT
        e.payer,
        e.patient,
        SUM(e.payer_coverage) AS total_coverage_per_patient
    FROM encounters e
    GROUP BY e.payer, e.patient
)
SELECT
    py.name AS payer_name,
    COUNT(*) AS nr_pacienti_distincti,
    ROUND(AVG(ppc.total_coverage_per_patient), 2) AS medie_acoperire_per_pacient,
    SUM(ppc.total_coverage_per_patient) AS total_acoperit
FROM payer_patient_costs ppc
JOIN payers py
    ON py.id = ppc.payer
GROUP BY py.name
ORDER BY nr_pacienti_distincti DESC, total_acoperit DESC;


/* -----------------------------------------------------------------------------
3. Pentru fiecare gen, top 3 conditii medicale dupa numar de aparitii.
   Ideea: folosim ranking ca sa nu afisam toate conditiile, ci doar cele mai
   relevante pe fiecare gen.
----------------------------------------------------------------------------- */
WITH condition_counts AS (
    SELECT
        p.gender,
        c.description AS conditie,
        COUNT(*) AS total
    FROM conditions c
JOIN patients p
        ON p.id = c.patient
    GROUP BY p.gender, c.description
),
ranked_conditions AS (
    SELECT
        gender,
        conditie,
        total,
        DENSE_RANK() OVER (
            PARTITION BY gender
            ORDER BY total DESC, conditie ASC
        ) AS pozitie
    FROM condition_counts
)
SELECT
    gender,
    conditie,
    total,
    pozitie
FROM ranked_conditions
WHERE pozitie <= 3
ORDER BY gender, pozitie, conditie;


/* -----------------------------------------------------------------------------
4. Asiguratorii care au cea mai mare diferenta intre costul total al claim-urilor
   si suma acoperita.
   Ideea: indicator mai realist pentru "presiunea financiara" ramasa neacoperita.
----------------------------------------------------------------------------- */
SELECT
    py.name AS payer_name,
    COUNT(*) AS nr_encounteruri,
    SUM(e.total_claim_cost) AS total_claim_cost,
    SUM(e.payer_coverage) AS total_acoperit,
    SUM(e.total_claim_cost - e.payer_coverage) AS total_neacoperit,
    ROUND(AVG(e.total_claim_cost - e.payer_coverage), 2) AS medie_neacoperit
FROM encounters e
JOIN payers py
    ON py.id = e.payer
GROUP BY py.name
HAVING COUNT(*) >= 10
ORDER BY total_neacoperit DESC, total_claim_cost DESC;


/* =============================================================================
   ANDREEA
   ========================================================================== */

/* -----------------------------------------------------------------------------
5. Top 5 pacienti cu cele mai multe proceduri si costul total al procedurilor.
   Ideea: adaugam si componenta financiara, nu doar numarul brut de proceduri.
----------------------------------------------------------------------------- */
SELECT
    pr.patient,
    COUNT(*) AS total_proceduri,
    SUM(pr.base_cost) AS cost_total_proceduri,
    ROUND(AVG(pr.base_cost), 2) AS cost_mediu_procedura
FROM procedures pr
GROUP BY pr.patient
ORDER BY total_proceduri DESC, cost_total_proceduri DESC
LIMIT 5;


/* -----------------------------------------------------------------------------
6. Organizatii cu multe encounter-uri si cost mediu ridicat.
   Ideea: vedem activitatea organizatiilor impreuna cu severitatea financiara.
----------------------------------------------------------------------------- */
SELECT
    o.name AS organization_name,
    COUNT(*) AS total_encounters,
    SUM(e.total_claim_cost) AS total_claim_cost,
    ROUND(AVG(e.total_claim_cost), 2) AS avg_claim_cost
FROM encounters e
JOIN organizations o
    ON o.id = e.organization
GROUP BY o.name
HAVING COUNT(*) >= 20
ORDER BY total_encounters DESC, avg_claim_cost DESC;


/* -----------------------------------------------------------------------------
7. Pacienti pentru care costul total al procedurilor depaseste media globala
   per pacient.
   Ideea: subquery agregata comparata cu media tuturor pacientilor.
----------------------------------------------------------------------------- */
WITH patient_procedure_costs AS (
    SELECT
        pr.patient,
        SUM(pr.base_cost) AS total_cost
    FROM procedures pr
    GROUP BY pr.patient
)
SELECT
    ppc.patient,
    ppc.total_cost
FROM patient_procedure_costs ppc
WHERE ppc.total_cost > (
    SELECT AVG(total_cost)
    FROM patient_procedure_costs
)
ORDER BY ppc.total_cost DESC;


/* -----------------------------------------------------------------------------
8. Cele mai frecvente conditii pentru pacientii care au avut cel putin
   3 proceduri distincte.
   Ideea: filtram un subset mai "complex clinic".
----------------------------------------------------------------------------- */
WITH patients_with_many_procedures AS (
    SELECT
        pr.patient
    FROM procedures pr
    GROUP BY pr.patient
    HAVING COUNT(*) >= 3
)
SELECT
    c.description AS conditie,
    COUNT(*) AS total
FROM conditions c
WHERE c.patient IN (
    SELECT patient
    FROM patients_with_many_procedures
)
GROUP BY c.description
ORDER BY total DESC, conditie ASC
LIMIT 10;


/* =============================================================================
   ALEX
   ========================================================================== */


/* -----------------------------------------------------------------------------
 9. Pentru fiecare payer, procentul din costul total al claim-urilor care ramane neacoperit.
----------------------------------------------------------------------------- */
SELECT
    py.name AS payer_name,
    SUM(e.total_claim_cost) AS total_claim_cost,
    SUM(e.payer_coverage) AS total_acoperit,
    SUM(e.total_claim_cost - e.payer_coverage) AS total_neacoperit,
    ROUND(
        100.0 * SUM(e.total_claim_cost - e.payer_coverage)
        / NULLIF(SUM(e.total_claim_cost), 0),
        2
    ) AS procent_neacoperit
FROM encounters e
JOIN payers py
    ON py.id = e.payer
GROUP BY py.name
HAVING SUM(e.total_claim_cost) > 0
ORDER BY procent_neacoperit DESC, total_neacoperit DESC;


/* -----------------------------------------------------------------------------
10. Organizatiile in care numarul de provideri este peste media tuturor organizatiilor, 
    impreuna cu nr de encounter-uri si costul mediu al acestora.
----------------------------------------------------------------------------- */
WITH providers_per_org AS (
    SELECT
        p.organization,
        COUNT(*) AS nr_providers
    FROM providers p
    GROUP BY p.organization
),
avg_providers AS (
    SELECT AVG(nr_providers) AS avg_nr_providers
    FROM providers_per_org
)
SELECT
    o.name AS organization_name,
    ppo.nr_providers,
    COUNT(e.id) AS nr_encounters,
    ROUND(AVG(e.total_claim_cost), 2) AS avg_claim_cost
FROM providers_per_org ppo
JOIN avg_providers ap
    ON 1 = 1
JOIN organizations o
    ON o.id = ppo.organization
LEFT JOIN encounters e
    ON e.organization = o.id
WHERE ppo.nr_providers > ap.avg_nr_providers
GROUP BY o.name, ppo.nr_providers
ORDER BY ppo.nr_providers DESC, nr_encounters DESC;


/* -----------------------------------------------------------------------------
11. Pacienti care au alergii si pt care valoarea maxima a unui encounter depaseste costul mediu
//     al tuturor encounter-urilor.
----------------------------------------------------------------------------- */
SELECT
    p.id AS patient_id,
    p.first,
    p.last,
    COUNT(DISTINCT a.allergy_id) AS nr_allergii,
    MAX(e.total_claim_cost) AS max_claim_cost
FROM patients p
JOIN allergies a
    ON a.patient = p.id
JOIN encounters e
    ON e.patient = p.id
GROUP BY p.id, p.first, p.last
HAVING MAX(e.total_claim_cost) > (
    SELECT AVG(total_claim_cost)
    FROM encounters
)
ORDER BY max_claim_cost DESC, nr_allergii DESC;


/* -----------------------------------------------------------------------------
12. Pentru fiecare an de nastere, costul mediu si costul total al encounter-urilor
    asociate pacientilor nascuti in acel an.
----------------------------------------------------------------------------- */
SELECT
    EXTRACT(YEAR FROM p.birthdate) AS an_nastere,
    COUNT(DISTINCT p.id) AS nr_pacienti,
    ROUND(AVG(e.total_claim_cost), 2) AS avg_claim_cost,
    SUM(e.total_claim_cost) AS total_claim_cost
FROM patients p
JOIN encounters e
    ON e.patient = p.id
GROUP BY EXTRACT(YEAR FROM p.birthdate)
HAVING COUNT(DISTINCT p.id) >= 5
ORDER BY an_nastere ASC;