#!/bin/bash
# Boot script for every ASG instance. Installs Docker, authenticates to ECR and
# starts the pre-built ToDoAI image. The instance role supplies ECR credentials.
set -euo pipefail

dnf install -y docker
systemctl enable --now docker

REGION="${aws_region}"
REGISTRY="${ecr_registry}"
IMAGE_URI="${image_uri}"

# Authenticate to the private registry and pull the immutable image digest.
login_and_pull() {
  aws ecr get-login-password --region "$REGION" \
    | docker login --username AWS --password-stdin "$REGISTRY"
  docker pull "$IMAGE_URI"
}

# Retry transient ECR/S3/DNS failures instead of leaving the instance without a
# container and waiting for the ASG to replace it.
for attempt in 1 2 3 4 5; do
  if login_and_pull; then
    break
  fi

  if [ "$attempt" -eq 5 ]; then
    echo "ECR login or image pull failed after 5 attempts" >&2
    exit 1
  fi

  sleep $((attempt * 10))
done

# Make the script safe if user_data is ever re-run on an existing instance.
docker rm -f todoai || true

# Port 80 is the nginx default and matches the ALB target group.
docker run -d \
  --name todoai \
  --restart unless-stopped \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  -p 80:80 \
  "$IMAGE_URI"
