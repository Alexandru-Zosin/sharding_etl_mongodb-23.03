nerdctl cp .\02-shard1-init.js shard1a:/tmp/02-shard1-init.js
nerdctl exec -i shard1a mongosh --port 26000 /tmp/02-shard1-init.js
Start-Sleep -Seconds 3
nerdctl exec -i shard1a mongosh --port 26000 --eval "rs.status()"

nerdctl cp .\02-shard2-init.js shard2a:/tmp/02-shard2-init.js
nerdctl exec -i shard2a mongosh --port 26000 /tmp/02-shard2-init.js
Start-Sleep -Seconds 3
nerdctl exec -i shard2a mongosh --port 26000 --eval "rs.status()"

# powershell -ExecutionPolicy Bypass -File .\02-init-shards-rs.ps1