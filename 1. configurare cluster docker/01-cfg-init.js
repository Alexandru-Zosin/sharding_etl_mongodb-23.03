rs.initiate({
  _id: "cfgReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "cfg1:26050" },
    { _id: 1, host: "cfg2:26050" },
    { _id: 2, host: "cfg3:26050" }
  ]
});