db = db.getSiblingDB("students");

sh.enableSharding("students");
db.studenti.createIndex({ _id: 1 });
sh.shardCollection("students.studenti", { _id: 1 });

db.studenti.insertMany([
  {
    _id: 0,
    name: "Aimee Zank",
    scores: [
      { score: 1.463179736705023, type: "exam" },
      { score: 11.78273309957772, type: "quiz" },
      { score: 35.8740349954354, type: "homework" }
    ]
  },
  {
    _id: 1,
    name: "Aurelia Menendez",
    scores: [
      { score: 60.06045071030959, type: "exam" },
      { score: 52.79790691903873, type: "quiz" },
      { score: 71.76133439165544, type: "homework" }
    ]
  }
]);

printjson(db.studenti.find().toArray());
printjson(db.studenti.getShardDistribution());
db.studenti.drop();
print("students.studenti dropped");