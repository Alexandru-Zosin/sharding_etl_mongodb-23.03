nerdctl cp .\03-add-shards.js mongos:/tmp/03-add-shards.js
nerdctl exec -i mongos mongosh --port 26061 /tmp/03-add-shards.js

# powershell -ExecutionPolicy Bypass -File .\03-add-shards.ps1