// =============================================================================
// BIANCA
// =============================================================================

// -----------------------------------------------------------------------------
// 1. Top 5 afectiuni dupa costul total al encounter-urilor in care au aparut.
// -----------------------------------------------------------------------------
print("\n--- Query 1: Top 5 afectiuni dupa costul total al encounter-urilor ---");
printjson(
  db.conditions_allergies_patient.aggregate([
    { $unwind: "$conditions" },
    {
      $lookup: {
        from: "observations_procedures_encounter",
        localField: "conditions.encounter_id",
        foreignField: "encounter_id",
        as: "enc"
      }
    },
    { $unwind: "$enc" },
    {
      $group: {
        _id: "$conditions.description",
        nr_aparitii: { $sum: 1 },
        cost_total_encounteruri: { $sum: "$enc.total_claim_cost" },
        cost_mediu_per_aparitie: { $avg: "$enc.total_claim_cost" }
      }
    },
    { $match: { nr_aparitii: { $gte: 5 } } },
    { $sort: { cost_total_encounteruri: -1, nr_aparitii: -1 } },
    { $limit: 5 }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 2. Top payers dupa numar de pacienti distincti si acoperire medie per pacient.
// -----------------------------------------------------------------------------
print("\n--- Query 2: Top payers dupa pacienti distincti si acoperire medie ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    {
      $group: {
        _id: {
          payer_id: "$payer_id",
          patient_id: "$patient_id"
        },
        total_coverage_per_patient: { $sum: "$payer_coverage" }
      }
    },
    {
      $group: {
        _id: "$_id.payer_id",
        nr_pacienti_distincti: { $sum: 1 },
        total_acoperit: { $sum: "$total_coverage_per_patient" },
        medie_acoperire_per_pacient: { $avg: "$total_coverage_per_patient" }
      }
    },
    {
      $lookup: {
        from: "payer",
        localField: "_id",
        foreignField: "payer_id",
        as: "payer_info"
      }
    },
    { $unwind: "$payer_info" },
    {
      $project: {
        _id: 0,
        payer_id: "$_id",
        payer_name: "$payer_info.name",
        nr_pacienti_distincti: 1,
        total_acoperit: 1,
        medie_acoperire_per_pacient: 1
      }
    },
    { $sort: { nr_pacienti_distincti: -1, total_acoperit: -1 } }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 3. Pentru fiecare gen, top 3 conditii medicale dupa numar de aparitii.
// -----------------------------------------------------------------------------
print("\n--- Query 3: Top 3 conditii medicale pentru fiecare gen ---");
printjson(
  db.conditions_allergies_patient.aggregate([
    { $unwind: "$conditions" },
    {
      $group: {
        _id: {
          gender: "$gender",
          condition: "$conditions.description"
        },
        total: { $sum: 1 }
      }
    },
    { $sort: { "_id.gender": 1, total: -1, "_id.condition": 1 } },
    {
      $group: {
        _id: "$_id.gender",
        top_conditii: {
          $push: {
            conditie: "$_id.condition",
            total: "$total"
          }
        }
      }
    },
    {
      $project: {
        _id: 0,
        gender: "$_id",
        top_3_conditii: { $slice: ["$top_conditii", 3] }
      }
    },
    { $sort: { gender: 1 } }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 4. Asiguratorii cu cea mai mare suma neacoperita.
// -----------------------------------------------------------------------------
print("\n--- Query 4: Asiguratorii cu cea mai mare suma neacoperita ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    {
      $addFields: {
        neacoperit: { $subtract: ["$total_claim_cost", "$payer_coverage"] }
      }
    },
    {
      $group: {
        _id: "$payer_id",
        nr_encounteruri: { $sum: 1 },
        total_claim_cost: { $sum: "$total_claim_cost" },
        total_acoperit: { $sum: "$payer_coverage" },
        total_neacoperit: { $sum: "$neacoperit" },
        medie_neacoperit: { $avg: "$neacoperit" }
      }
    },
    { $match: { nr_encounteruri: { $gte: 10 } } },
    {
      $lookup: {
        from: "payer",
        localField: "_id",
        foreignField: "payer_id",
        as: "payer_info"
      }
    },
    { $unwind: "$payer_info" },
    {
      $project: {
        _id: 0,
        payer_id: "$_id",
        payer_name: "$payer_info.name",
        nr_encounteruri: 1,
        total_claim_cost: 1,
        total_acoperit: 1,
        total_neacoperit: 1,
        medie_neacoperit: 1
      }
    },
    { $sort: { total_neacoperit: -1, total_claim_cost: -1 } }
  ]).toArray()
);


// =============================================================================
// ANDREEA
// =============================================================================

// -----------------------------------------------------------------------------
// 5. Top 5 pacienti cu cele mai multe proceduri si cost total al procedurilor.
// -----------------------------------------------------------------------------
print("\n--- Query 5: Top 5 pacienti dupa numarul si costul procedurilor ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    { $unwind: "$procedures" },
    {
      $group: {
        _id: "$patient_id",
        total_proceduri: { $sum: 1 },
        cost_total_proceduri: { $sum: "$procedures.base_cost" },
        cost_mediu_procedura: { $avg: "$procedures.base_cost" }
      }
    },
    { $sort: { total_proceduri: -1, cost_total_proceduri: -1 } },
    { $limit: 5 }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 6. Organizatii cu multe encounter-uri si cost mediu ridicat.
// -----------------------------------------------------------------------------
print("\n--- Query 6: Organizatii cu multe encounter-uri si cost mediu ridicat ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    {
      $group: {
        _id: "$organization_id",
        total_encounters: { $sum: 1 },
        total_claim_cost: { $sum: "$total_claim_cost" },
        avg_claim_cost: { $avg: "$total_claim_cost" }
      }
    },
    { $match: { total_encounters: { $gte: 20 } } },
    {
      $lookup: {
        from: "organizations_provider",
        localField: "_id",
        foreignField: "organization.id",
        as: "org_rows"
      }
    },
    { $unwind: "$org_rows" },
    {
      $group: {
        _id: {
          organization_id: "$_id",
          organization_name: "$org_rows.organization.name"
        },
        total_encounters: { $first: "$total_encounters" },
        total_claim_cost: { $first: "$total_claim_cost" },
        avg_claim_cost: { $first: "$avg_claim_cost" }
      }
    },
    {
      $project: {
        _id: 0,
        organization_id: "$_id.organization_id",
        organization_name: "$_id.organization_name",
        total_encounters: 1,
        total_claim_cost: 1,
        avg_claim_cost: 1
      }
    },
    { $sort: { total_encounters: -1, avg_claim_cost: -1 } }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 7. Pacienti al caror cost total al procedurilor este peste media tuturor.
// -----------------------------------------------------------------------------
print("\n--- Query 7: Pacienti cu cost total al procedurilor peste medie ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    { $unwind: "$procedures" },
    {
      $group: {
        _id: "$patient_id",
        total_cost: { $sum: "$procedures.base_cost" }
      }
    },
    {
      $group: {
        _id: null,
        avg_total_cost: { $avg: "$total_cost" },
        rows: {
          $push: {
            patient_id: "$_id",
            total_cost: "$total_cost"
          }
        }
      }
    },
    { $unwind: "$rows" },
    {
      $match: {
        $expr: { $gt: ["$rows.total_cost", "$avg_total_cost"] }
      }
    },
    {
      $project: {
        _id: 0,
        patient_id: "$rows.patient_id",
        total_cost: "$rows.total_cost",
        avg_total_cost: 1
      }
    },
    { $sort: { total_cost: -1 } }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 8. Cele mai frecvente conditii la pacientii cu cel putin 3 proceduri.
// -----------------------------------------------------------------------------
print("\n--- Query 8: Cele mai frecvente conditii la pacientii cu cel putin 3 proceduri ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    { $unwind: "$procedures" },
    {
      $group: {
        _id: "$patient_id",
        nr_proceduri: { $sum: 1 }
      }
    },
    { $match: { nr_proceduri: { $gte: 3 } } },
    {
      $lookup: {
        from: "conditions_allergies_patient",
        localField: "_id",
        foreignField: "patient_id",
        as: "patient_info"
      }
    },
    { $unwind: "$patient_info" },
    { $unwind: "$patient_info.conditions" },
    {
      $group: {
        _id: "$patient_info.conditions.description",
        total: { $sum: 1 }
      }
    },
    { $sort: { total: -1, _id: 1 } },
    { $limit: 10 }
  ]).toArray()
);


// =============================================================================
// ALEX
// =============================================================================

// -----------------------------------------------------------------------------
// 9. Top 10 combinatii conditie + procedura care apar in acelasi encounter.
// -----------------------------------------------------------------------------
print("\n--- Query 9: Top 10 combinatii conditie plus procedura in acelasi encounter ---");
printjson(
  db.conditions_allergies_patient.aggregate([
    { $unwind: "$conditions" },
    {
      $lookup: {
        from: "observations_procedures_encounter",
        localField: "conditions.encounter_id",
        foreignField: "encounter_id",
        as: "enc"
      }
    },
    { $unwind: "$enc" },
    { $unwind: "$enc.procedures" },
    {
      $group: {
        _id: {
          conditie: "$conditions.description",
          procedura: "$enc.procedures.description"
        },
        nr_corelari: { $sum: 1 }
      }
    },
    { $match: { nr_corelari: { $gte: 3 } } },
    { $sort: { nr_corelari: -1, "_id.conditie": 1, "_id.procedura": 1 } },
    { $limit: 10 }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 10. Pentru fiecare payer, procentul din cost care ramane neacoperit.
// -----------------------------------------------------------------------------
print("\n--- Query 10: Procentul din cost ramas neacoperit pentru fiecare payer ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    {
      $addFields: {
        neacoperit: { $subtract: ["$total_claim_cost", "$payer_coverage"] }
      }
    },
    {
      $group: {
        _id: "$payer_id",
        total_claim_cost: { $sum: "$total_claim_cost" },
        total_acoperit: { $sum: "$payer_coverage" },
        total_neacoperit: { $sum: "$neacoperit" }
      }
    },
    {
      $addFields: {
        procent_neacoperit: {
          $cond: [
            { $eq: ["$total_claim_cost", 0] },
            0,
            {
              $multiply: [
                { $divide: ["$total_neacoperit", "$total_claim_cost"] },
                100
              ]
            }
          ]
        }
      }
    },
    {
      $lookup: {
        from: "payer",
        localField: "_id",
        foreignField: "payer_id",
        as: "payer_info"
      }
    },
    { $unwind: "$payer_info" },
    {
      $project: {
        _id: 0,
        payer_id: "$_id",
        payer_name: "$payer_info.name",
        total_claim_cost: 1,
        total_acoperit: 1,
        total_neacoperit: 1,
        procent_neacoperit: 1
      }
    },
    { $sort: { procent_neacoperit: -1, total_neacoperit: -1 } }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 11. Organizatiile cu numar de provideri peste media tuturor organizatiilor.
// -----------------------------------------------------------------------------
print("\n--- Query 11: Organizatii cu numar de provideri peste medie ---");
printjson(
  db.organizations_provider.aggregate([
    {
      $group: {
        _id: {
          organization_id: "$organization.id",
          organization_name: "$organization.name"
        },
        nr_providers: { $sum: 1 }
      }
    },
    {
      $group: {
        _id: null,
        avg_nr_providers: { $avg: "$nr_providers" },
        rows: {
          $push: {
            organization_id: "$_id.organization_id",
            organization_name: "$_id.organization_name",
            nr_providers: "$nr_providers"
          }
        }
      }
    },
    { $unwind: "$rows" },
    {
      $match: {
        $expr: { $gt: ["$rows.nr_providers", "$avg_nr_providers"] }
      }
    },
    {
      $lookup: {
        from: "observations_procedures_encounter",
        localField: "rows.organization_id",
        foreignField: "organization_id",
        as: "encounters"
      }
    },
    {
      $project: {
        _id: 0,
        organization_id: "$rows.organization_id",
        organization_name: "$rows.organization_name",
        nr_providers: "$rows.nr_providers",
        avg_nr_providers: 1,
        nr_encounters: { $size: "$encounters" }
      }
    },
    { $sort: { nr_providers: -1, nr_encounters: -1 } }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 12. Pacienti care au alergii si au avut cel putin un encounter cu cost
//     peste media tuturor encounter-urilor.
// -----------------------------------------------------------------------------
print("\n--- Query 12: Pacienti cu alergii si encounter peste media costurilor ---");
printjson(
  db.observations_procedures_encounter.aggregate([
    {
      $group: {
        _id: null,
        avg_claim_cost: { $avg: "$total_claim_cost" },
        encounters: {
          $push: {
            patient_id: "$patient_id",
            total_claim_cost: "$total_claim_cost"
          }
        }
      }
    },
    { $unwind: "$encounters" },
    {
      $match: {
        $expr: {
          $gt: ["$encounters.total_claim_cost", "$avg_claim_cost"]
        }
      }
    },
    {
      $lookup: {
        from: "conditions_allergies_patient",
        localField: "encounters.patient_id",
        foreignField: "patient_id",
        as: "patient_info"
      }
    },
    { $unwind: "$patient_info" },
    {
      $addFields: {
        nr_allergii: { $size: "$patient_info.allergies" }
      }
    },
    { $match: { nr_allergii: { $gt: 0 } } },
    {
      $group: {
        _id: "$encounters.patient_id",
        first: { $first: "$patient_info.first" },
        last: { $first: "$patient_info.last" },
        nr_allergii: { $first: "$nr_allergii" },
        max_claim_cost: { $max: "$encounters.total_claim_cost" }
      }
    },
    { $sort: { max_claim_cost: -1, nr_allergii: -1 } }
  ]).toArray()
);


// -----------------------------------------------------------------------------
// 13. Cost mediu al encounter-urilor pe cohorte de an de nastere.
// -----------------------------------------------------------------------------
print("\n--- Query 13: Cost mediu al encounter-urilor pe cohorte de an de nastere ---");
printjson(
  db.conditions_allergies_patient.aggregate([
    {
      $addFields: {
        an_nastere: { $year: "$birthdate" }
      }
    },
    {
      $lookup: {
        from: "observations_procedures_encounter",
        localField: "patient_id",
        foreignField: "patient_id",
        as: "encounters"
      }
    },
    { $unwind: "$encounters" },
    {
      $group: {
        _id: "$an_nastere",
        nr_pacienti_set: { $addToSet: "$patient_id" },
        avg_claim_cost: { $avg: "$encounters.total_claim_cost" },
        total_claim_cost: { $sum: "$encounters.total_claim_cost" }
      }
    },
    {
      $addFields: {
        nr_pacienti: { $size: "$nr_pacienti_set" }
      }
    },
    { $match: { nr_pacienti: { $gte: 5 } } },
    {
      $project: {
        _id: 0,
        an_nastere: "$_id",
        nr_pacienti: 1,
        avg_claim_cost: 1,
        total_claim_cost: 1
      }
    },
    { $sort: { an_nastere: 1 } }
  ]).toArray()
);