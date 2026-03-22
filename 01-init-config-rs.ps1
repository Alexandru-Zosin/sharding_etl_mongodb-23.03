nerdctl cp .\01-cfg-init.js cfg1:/tmp/01-cfg-init.js #copiaza intre host si container (FS sau, NU VOLUM)
nerdctl exec -i cfg1 mongosh --port 26050 /tmp/01-cfg-init.js
Start-Sleep -Seconds 3
nerdctl exec -i cfg1 mongosh --port 26050 --eval 'rs.status()'

# powershell -ExecutionPolicy Bypass -File .\01-init-config-rs.ps1