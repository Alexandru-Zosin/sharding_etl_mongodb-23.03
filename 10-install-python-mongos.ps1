# nerdctl exec -it mongos bash
$ErrorActionPreference = "Stop"

nerdctl exec mongos bash -lc "apt-get update && apt-get install -y python3 python3-pip"
nerdctl exec mongos bash -lc "python3 --version && pip3 --version"