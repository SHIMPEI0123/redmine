#!/usr/bin/env bash
set -euo pipefail
test -s /etc/redmine-team/runtime.env || { echo 'Missing /etc/redmine-team/runtime.env' >&2; exit 1; }
command -v docker
command -v aws
docker compose version
mkdir -p /var/lib/redmine-team
