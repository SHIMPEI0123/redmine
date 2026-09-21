#!/usr/bin/env bash
set -euo pipefail
cd /opt/redmine-team
set -a
source /etc/redmine-team/runtime.env
source ./image.env
set +a
[[ "$IMAGE_URI" =~ ^[0-9]{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com/redmine-team:[a-f0-9]{12}$ ]] || {
  echo 'Unexpected IMAGE_URI' >&2; exit 1;
}
REGION=$(echo "$IMAGE_URI" | cut -d. -f4)
REGISTRY="${IMAGE_URI%%/*}"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"
docker pull "$IMAGE_URI"
# DBおよび添付ファイルはnamed volume。down -vを使用しない。
docker compose --project-name redmine-team -f compose.prod.yaml up -d --wait
