rs.initiate({
  _id: "shard1ReplSet",
  members: [
    { _id: 0, host: "shard1a:26000" },
    { _id: 1, host: "shard1b:26000" },
    { _id: 2, host: "shard1c:26000" }
  ]
});