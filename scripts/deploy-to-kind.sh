#!/usr/bin/env bash
set -euo pipefail

EXPECTED_CONTEXT="kind-devops-k8s"
NAMESPACE="project8-cicd"
DEPLOYMENT="project8-cicd"
IMAGE_NAME="project8-cicd-lab"
IMAGE_TAG="${1:-1.0}"
HANDOFF_DIR="/home/jenkins/agent/project8-handoff"
IMAGE_ARCHIVE="${HANDOFF_DIR}/${IMAGE_NAME}-${IMAGE_TAG}.tar"

echo "== Project 8 deployment preflight =="

# Confirm required commands are available.
for cmd in kubectl kind docker; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: Required command not found: $cmd" >&2
        exit 1
    }
done

# Ensure this script targets the intended cluster.
CURRENT_CONTEXT="$(kubectl config current-context)"
if [[ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]]; then
    echo "ERROR: Expected context '$EXPECTED_CONTEXT', got '$CURRENT_CONTEXT'." >&2
    exit 1
fi

# Verify the existing namespace and Deployment.
kubectl get namespace "$NAMESPACE" >/dev/null
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null

# Check the current Deployment image without changing it.
CURRENT_IMAGE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].image}')"
echo "Cluster context: $CURRENT_CONTEXT"
echo "Namespace: $NAMESPACE"
echo "Deployment: $DEPLOYMENT"
echo "Current image: $CURRENT_IMAGE"
echo "Expected image: ${IMAGE_NAME}:${IMAGE_TAG}"

# Require the image archive before proceeding.
if [[ ! -f "$IMAGE_ARCHIVE" ]]; then
    echo "ERROR: Image archive not found: $IMAGE_ARCHIVE" >&2
    exit 1
fi

echo "Image archive found: $IMAGE_ARCHIVE"
echo "Preflight complete. No Kubernetes resources were changed."
