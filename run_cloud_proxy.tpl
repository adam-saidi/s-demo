#!/bin/bash
# bash script that'll be ran when the proxy instance is booted up

set -euo pipefail

# storing the account key in /var - its writeable and persists after reebot 

echo '${service_account_key}' >/var/svc_account_key.json
chmod 444 /var/svc_account_key.json

# ensure that every time the proxy boots up, we're pulling the latest release - remember to reboot often!
docker pull gcr.io/cloudsql-docker/gce-proxy:latest

# -p 127.0.0.1:5432:3306 -- mapping port 3306 in container to 5432 for Postgres access over localhost

# -v /var/svc_account_key.json:/key.json:ro -- read only access granted for key for protection

# -ip_address_types=PRIVATE -> The proxy should only try to connect to the databases private IP controlled by firewall rules/VPC

# -instances=${db_instance_name}=tcp:0.0.0.0:3306 -> proxy should accept incoming TCP connections on port 3306

docker run --rm -p 127.0.0.1:5432:3306 -v /var/svc_account_key.json:/key.json:ro gcr.io/cloudsql-docker/gce-proxy:latest /cloud_sql_proxy -credential_file=/key.json -ip_address_types=PRIVATE -instances=${db_instance_name}=tcp:0.0.0.0:3306