#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_CONTEXT="kind-devops-k8s"
CLUSTER_NAME="devops-k8s"
NAMESPACE="project8-cicd"
DEPLOYMENT="project8-cicd"
CONTAINER_NAME="app"
IMAGE_NAME="project8-cicd-lab"
IMAGE_TAG="${1:-1.0}"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

echo "== Project 8 local kind deployment =="

for cmd in kubectl kind docker; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: Required command not found: $cmd" >&2
        exit 1
    }
done

CURRENT_CONTEXT="$(kubectl config current-context)"
if [[ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]]; then
    echo "ERROR: Expected context '$EXPECTED_CONTEXT', got '$CURRENT_CONTEXT'." >&2
    exit 1
fi

kind get clusters | grep -Fxq "$CLUSTER_NAME" || {
    echo "ERROR: Existing kind cluster '$CLUSTER_NAME' was not found." >&2
    exit 1
}

kubectl get namespace "$NAMESPACE" >/dev/null
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" >/dev/null

CURRENT_IMAGE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].image}')"

echo "Context: $CURRENT_CONTEXT"
echo "Cluster: $CLUSTER_NAME"
echo "Namespace: $NAMESPACE"
echo "Deployment: $DEPLOYMENT"
echo "Current image: $CURRENT_IMAGE"
echo "Target image: $IMAGE"

docker image inspect "$IMAGE" >/dev/null || {
    echo "ERROR: Local Docker image '$IMAGE' was not found." >&2
    exit 1
}

echo "Loading image into the existing kind cluster..."
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

echo "Updating the existing Deployment..."
kubectl set image "deployment/$DEPLOYMENT" \
    "$CONTAINER_NAME=$IMAGE" -n "$NAMESPACE"

echo "Waiting for rollout..."
kubectl rollout status "deployment/$DEPLOYMENT" \
    -n "$NAMESPACE" --timeout=120s

echo "Final Deployment status:"
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o wide
kubectl get pods -n "$NAMESPACE" -o wide

echo "Checking application health..."
HEALTH_RESPONSE="$(kubectl exec -n "$NAMESPACE" "deployment/$DEPLOYMENT" -- \
    python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5).read().decode())")"

if [[ "$HEALTH_RESPONSE" != '{"status": "healthy"}' ]]; then
    echo "ERROR: Application health check failed: $HEALTH_RESPONSE" >&2
    exit 1
fi

echo "Application health check passed: $HEALTH_RESPONSE"
echo "Deployment completed successfully."
