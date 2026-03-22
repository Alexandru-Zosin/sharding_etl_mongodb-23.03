$servicesCore = @(
    'cfg1','cfg2','cfg3',
    'shard1a','shard1b','shard1c',
    'shard2a','shard2b','shard2c',
    'pgsql'
)

foreach ($service in $servicesCore) {
    nerdctl start $service
}

Start-Sleep -Seconds 8

nerdctl start mongos

nerdctl ps