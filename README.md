
# Project 8 — Jenkins CI/CD to Amazon ECR and Kubernetes

## Overview

This project demonstrates a CI/CD workflow using GitHub, Jenkins, Docker, Amazon ECR, and Kubernetes manifests.

The Jenkins pipeline checks out the source, runs unit tests, builds and inspects a Docker image, exports an image archive, and pushes the image to Amazon ECR.

**Status:** Jenkins-to-ECR pipeline verified successfully. EKS manifests are prepared and locally validated. Deployment to a live EKS cluster is not yet completed.

## Architecture

GitHub → Jenkins → Unit Tests → Docker Build → Amazon ECR → Amazon EKS

## Technology Stack

- Linux / WSL
- Git and GitHub
- Python and unittest
- Docker
- Jenkins Pipeline
- Amazon ECR
- Kubernetes / Amazon EKS

## ECR Image

- Region: `ap-south-1` (Mumbai)
- Repository: `project8-cicd-lab`
- Tag: `1.0`
- Image URI:

  `258167965211.dkr.ecr.ap-south-1.amazonaws.com/project8-cicd-lab:1.0`

- Verified digest:

  `sha256:b1390e19f778360cebbf2506a9bb813a41a400b7155d5f64039f5a7fb86b74ea`

## Repository Layout

```text
.
├── app/
│   └── app.py
├── tests/
│   └── test_app.py
├── k8s/
│   ├── deployment.yaml
│   ├── eks-deployment.yaml
│   └── eks-service.yaml
├── scripts/
│   └── deploy-to-kind.sh
├── Dockerfile
├── Jenkinsfile
└── README.md
```

## Jenkins CI/CD Pipeline

The Jenkins pipeline performs these stages:

1. Checkout source from GitHub.
2. Run unit tests.
3. Build the Docker image.
4. Inspect the image.
5. Export the image archive to the shared Jenkins workspace.
6. Authenticate to ECR using a Jenkins-managed credential and push the image.
7. Log out of ECR after pushing.

The Jenkins credential ID is `project8-aws-ecr`. Never store AWS access keys, secret keys, or authorization tokens in source code or documentation.

## Kubernetes Manifests

### Local kind

`k8s/deployment.yaml` is the existing local-kind deployment manifest. It uses `project8-cicd-lab:1.0` with `imagePullPolicy: Never`.

### Amazon EKS

`k8s/eks-deployment.yaml` uses the ECR image with `imagePullPolicy: Always`. It configures two replicas, readiness and liveness probes on `/health`, resource requests and limits, and a non-root security context.

`k8s/eks-service.yaml` defines an internal `ClusterIP` Service on port 80 targeting the application on port 8000. It does not request an AWS Load Balancer.

Both EKS manifests passed a local `kubectl` client-side dry run. They have not been validated against a live EKS API server or deployed to EKS.

## Validate the EKS Manifests Locally

```bash
kubectl create --dry-run=client --validate=false \
  -f k8s/eks-deployment.yaml \
  -f k8s/eks-service.yaml
```

This command parses the manifests locally; it does not create AWS resources.

## Future EKS Deployment

Before deployment:

1. Confirm EKS availability, Free Plan restrictions, quotas, and estimated costs.
2. Create and configure an EKS cluster and worker capacity only after explicit approval.
3. Ensure the worker nodes have permission to pull the private ECR image.
4. Create the namespace and apply the manifests:

```bash
kubectl create namespace project8-cicd
kubectl apply -f k8s/eks-deployment.yaml
kubectl apply -f k8s/eks-service.yaml
kubectl rollout status deployment/project8-cicd -n project8-cicd
kubectl get pods,service -n project8-cicd
```

Test the internal Service without provisioning a load balancer:

```bash
kubectl port-forward -n project8-cicd service/project8-cicd 8080:80
```

In another terminal:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/
```

These are future deployment instructions. They have not been run against EKS.

## Cleanup

Before running cleanup commands, verify the active Kubernetes context and confirm that the resources belong to this lab.

To remove the lab's namespaced application resources:

```bash
kubectl delete namespace project8-cicd
```

This does not delete the EKS cluster or guarantee removal of separately provisioned AWS resources.

After an approved lab, remove the lab's worker node group and EKS cluster using the appropriate AWS workflow. Inspect for remaining billable resources such as load balancers, NAT Gateways, public IPv4 addresses, and EBS volumes. Retain the ECR repository if you want to reuse the image.

Do not create or delete AWS resources without reviewing the intended changes and obtaining explicit approval.

## Verification Status

- [x] Three unit tests passed in Jenkins.
- [x] Docker image built and inspected.
- [x] Docker image archive exported.
- [x] Jenkins authenticated to ECR and pushed image tag `1.0`.
- [x] ECR image tag and digest independently verified with AWS CLI.
- [x] EKS manifests passed local client-side dry-run parsing.
- [ ] Validate manifests against a live EKS API server.
- [ ] Deploy and verify the application on EKS.
- [ ] Complete AWS cleanup after the approved lab.
