# Project 8 — Jenkins CI/CD, Amazon ECR & Kubernetes

## Overview

This project demonstrates a DevOps workflow using GitHub, Jenkins, Docker, Amazon ECR, and a local Kubernetes cluster powered by kind.

The Jenkins pipeline checks out the source code, runs unit tests, builds and inspects a Docker image, exports an image archive, authenticates to Amazon ECR using Jenkins-managed credentials, and pushes the image to ECR.

The application is deployed on the existing local kind cluster with two healthy replicas.

**Project status:** Jenkins-to-ECR pipeline verified successfully. Local Kubernetes Deployment verified with 2/2 replicas available. Amazon EKS deployment was not completed and is excluded from the completed project scope.

## Architecture

GitHub → Jenkins → Unit Tests → Docker Build → Amazon ECR

Local Kubernetes deployment is verified separately on the existing kind cluster.

## Technology Stack

- Linux / WSL
- Git and GitHub
- Python and `unittest`
- Docker
- Jenkins Pipeline
- Amazon Elastic Container Registry (ECR)
- Kubernetes
- kind

## Amazon ECR Image

- Region: `ap-south-1` (Mumbai)
- Repository: `project8-cicd-lab`
- Tag: `1.0`
- Image URI:

  `258167965211.dkr.ecr.ap-south-1.amazonaws.com/project8-cicd-lab:1.0`

- Verified digest:

  `sha256:b1390e19f778360cebbf2506a9bb813a41a400b7155d5f64039f5a7fb86b74ea`

The ECR image is preserved for future use.

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

The verified Jenkins pipeline performs these stages:

1. Checks out source code from GitHub.
2. Runs unit tests.
3. Builds the Docker image.
4. Inspects the image.
5. Exports an image archive to the shared Jenkins workspace.
6. Authenticates to Amazon ECR using a Jenkins-managed credential.
7. Pushes the image to ECR.
8. Logs out of ECR after pushing.

The Jenkins credential ID is `project8-aws-ecr`.

Never commit AWS access keys, secret keys, or authorization tokens to source control.

## Local Kubernetes Deployment

The existing local cluster context is `kind-devops-k8s`.

The application Deployment is in namespace `project8-cicd` and uses:

- Image: `project8-cicd-lab:1.0`
- Replicas: 2
- Container port: 8000
- Readiness and liveness probes on `/health`
- CPU and memory requests and limits
- A non-root container security context

The Deployment was verified with **2/2 replicas available**.

The manifest uses `imagePullPolicy: Never`, so the image must already be available on the kind node. The local Deployment is separate from the image pushed to Amazon ECR; the ECR push does not automatically update the local Kubernetes Deployment.

### Deployment preflight script

`scripts/deploy-to-kind.sh` checks that:

- Required commands are installed.
- The active Kubernetes context is `kind-devops-k8s`.
- The namespace and Deployment exist.
- The expected image archive is present.

**Important:** The current script performs preflight checks only. It does not import the image, apply manifests, or update the Deployment.

There is no Kubernetes Service currently present in the `project8-cicd` namespace.

## Amazon EKS Scope

Amazon EKS was explored during this project, but the worker-node group could not be created successfully. The EKS cluster and failed node group have since been deleted to avoid unnecessary ongoing costs.

The files `k8s/eks-deployment.yaml` and `k8s/eks-service.yaml` are retained as reference manifests. They passed a local client-side dry run, but they were not deployed to a live EKS cluster.

Do not describe this project as a completed EKS deployment.

## Verification Status

- [x] Three unit tests passed in Jenkins.
- [x] Docker image built and inspected.
- [x] Docker image archive exported.
- [x] Jenkins authenticated to ECR and pushed image tag `1.0`.
- [x] ECR image tag and digest independently verified.
- [x] Kubernetes Deployment verified with 2/2 replicas available on the existing kind cluster.
- [x] EKS manifests passed a local client-side dry run.
- [ ] Automated deployment from Jenkins to Kubernetes.
- [ ] Kubernetes Service and application-access verification.
- [ ] Live EKS deployment (excluded from this project).

## Cleanup and Cost Awareness

The EKS cluster and its failed worker-node group were deleted. The ECR repository and image are intentionally retained.

The existing kind cluster, Jenkins containers and agents, existing EC2 instances, VPCs, IAM roles, and Terraform project resources are outside the scope of this cleanup.

Before removing any additional resources, verify their names and ownership. Do not delete shared or pre-existing infrastructure as part of Project 8 cleanup.
