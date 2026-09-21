#!/usr/bin/env bash
set -euo pipefail
cd /opt/redmine-team
set -a
source /etc/redmine-team/runtime.env
source ./image.env
set +a
if curl --fail --silent --show-error --retry 30 --retry-delay 5 --retry-connrefused \
      http://127.0.0.1:3000/login -o /dev/null; then
  cp image.env /var/lib/redmine-team/current-image.env
  echo 'Redmine smoke test OK'
else
  echo 'Redmine smoke test FAILED. Attempting previous image rollback.' >&2
  if [ -s /var/lib/redmine-team/current-image.env ]; then
    source /var/lib/redmine-team/current-image.env
    docker compose --project-name redmine-team -f compose.prod.yaml up -d --wait || true
  fi
  exit 1
fi
