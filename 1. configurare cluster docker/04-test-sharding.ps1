nerdctl cp .\04-test-sharding.js mongos:/tmp/04-test-sharding.js
nerdctl exec -i mongos mongosh --port 26061 /tmp/04-test-sharding.js

# powershell -ExecutionPolicy Bypass -File .\04-test-sharding.ps1