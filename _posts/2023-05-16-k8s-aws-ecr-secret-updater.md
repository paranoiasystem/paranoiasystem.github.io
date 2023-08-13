---
title: Automatic Management of AWS ECR Credentials in a Kubernetes Cluster
category: Kubernetes
description: Learn how to automatically manage AWS ECR credentials in a Kubernetes cluster using a cronjob.
keywords: Kubernetes, AWS ECR, Secret, Elastic Container Registry, k8s, cronjob, kubectl, AWSCLI, Docker, Dockerfile, bash, script, automation, security, least privilege
layout: post
date:   2023-05-16
---
In the course of my work with **_AWS ECR (Elastic Container Registry)_**, I ran into a problem: The repository access key expires every six hours. Working with a non-AWS Kubernetes test cluster, I had to constantly update these credentials manually, a repetitive and tedious process.

From this experience came the idea to create a tool that automated this process: **_[k8s-aws-ecr-secret-updater](https://github.com/paranoiasystem/k8s-aws-ecr-secret-updater)_**. This tool is a Kubernetes cronjob, designed to automatically update the AWS ECR repository access credentials.

## Cronjob Configuration

The YAML code to create the cronjob consists of several parts, which I will now analyze piece by piece:

#### A Role that has permission to get, create, and delete secrets and get and update ServiceAccounts.


```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: k8sawsecrsecretupdater
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "create", "delete"]
- apiGroups: [""]
  resources: ["serviceaccounts"]
  verbs: ["get", "patch"]
```

A key component of this configuration is the **_k8sawsecrsecretupdater_** role. This role is fundamental for authorization within the Kubernetes namespace, allowing the cronjob to perform specific operations on certain resources.

In particular, the **_k8sawsecrsecretupdater_** role has the following permissions:

  1. It has permissions to get (**_get_**), create (**_create_**), and delete (**_delete_**) **_Secrets_**. This is crucial because the cronjob needs to be able to create and delete AWS ECR credentials, which are stored as secrets in Kubernetes.
  2. It has permissions to get (**_get_**) and update (**_patch_**) **_ServiceAccounts_**. The cronjob needs to be able to manage service accounts in order to associate the AWS ECR credentials with the service that runs the cronjob.

Creating a specific role for these operations ensures that the cronjob has exactly the permissions it needs to do its job, without granting it access to unnecessary resources. This approach is in line with the principle of least privilege, a common security practice that limits access to resources only to what is strictly necessary to perform a specific task. This helps to minimize the potential impact of a possible attack.

#### ServiceAccount to be used by the job and cronjob.

 ```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8sawsecrsecretupdater
```

#### RoleBinding to associate the Role with the ServiceAccount.


```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: k8sawsecrsecretupdater
subjects:
  - kind: ServiceAccount
    name: k8sawsecrsecretupdater
roleRef:
  kind: Role
  name: k8sawsecrsecretupdater
  apiGroup: rbac.authorization.k8s.io
```

#### Job that creates the secret.


```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: k8sawsecrsecretupdater
spec:
  backoffLimit: 4
  template:
    spec:
      serviceAccountName: k8sawsecrsecretupdater
      restartPolicy: Never
      containers:
      - name: k8sawsecrsecretupdater
        image: ghcr.io/paranoiasystem/k8s-aws-ecr-secret-updater:latest
        imagePullPolicy: Always
        env:
        - name: AWS_ACCOUNT
          value: 'YourAwsAccountID'
        - name: AWS_ACCESS_KEY_ID
          value: YourAccessKeyID
        - name: AWS_SECRET_ACCESS_KEY
          value: YourSecretAccessKey
        - name: AWS_REGION
          value: YourRegion
```

#### CronJob that runs the Job every 6 hours.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: k8sawsecrsecretupdater
spec:
  schedule: "0 */6 * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: k8sawsecrsecretupdater
          restartPolicy: Never
          containers:
          - name: k8sawsecrsecretupdater
            image: ghcr.io/paranoiasystem/k8s-aws-ecr-secret-updater:latest
            imagePullPolicy: Always
            env:
            - name: AWS_ACCOUNT
              value: 'YourAwsAccountID'
            - name: AWS_ACCESS_KEY_ID
              value: YourAccess
            - name: AWS_SECRET_ACCESS_KEY
              value: YourSecretAccessKey
            - name: AWS_REGION
              value: YourRegion
```

## Creating the Docker Image
The cronjob uses a specific Docker image to perform its task. This Docker image is built from the following Dockerfile:

```dockerfile
FROM alpine

LABEL org.opencontainers.image.description `Docker image for refresh AWS ECR credentials in kubernetes cluster`

RUN apk update && apk add --update --no-cache \
    git \
    bash \
    curl \
    openssh \
    python3 \
    py3-pip \
    py-cryptography \
    wget \
    curl \
    jq 

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

# Install AWSCLI
RUN pip install --upgrade pip && \
    pip install --upgrade awscli

WORKDIR /scripts
COPY scripts/ /scripts

ENTRYPOINT ["bash", "/scripts/entrypoint.sh"]
```

In the Dockerfile, starting from an Alpine base image, the necessary tools are installed, including git, bash, curl, openssh, python3, py3-pip, py-cryptography, wget, curl, jq. Also, kubectl and AWSCLI are installed for interaction with Kubernetes and AWS, respectively.

Subsequently, the working directory is set to /scripts and the contents of the local /scripts directory are copied. Finally, an ENTRYPOINT is defined that starts the entrypoint.sh script when the container is run.

## Execution of the Script
When the cronjob is run, it starts the bash script contained in the Docker image. This script checks for the existence of a secret called `"regcred"`. If it exists, it deletes it and creates a new one. If it doesn't exist, it creates it. Below is the script:

```bash
#!/bin/bash

create_secret() {
  kubectl create secret docker-registry regcred \
    --docker-server=${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password --region ${AWS_REGION})
}

# Check if the secret exists
if kubectl get secret regcred; then
  # If it exists, delete it
  kubectl delete secret regcred
  # Create the secret again
  create_secret
else
  # If it doesn't exist, create it
  create_secret
fi
```

## Installing k8s-aws-ecr-secret-updater on Kubernetes

To use the **_[k8s-aws-ecr-secret-updater](https://github.com/paranoiasystem/k8s-aws-ecr-secret-updater)_** in your Kubernetes environment, you need to follow some simple steps.

Let's start by cloning the project's GitHub repository onto your local system:

```sh
git clone https://github.com/paranoiasystem/k8s-aws-ecr-secret-updater
```

Next, you need to open and edit the **_install.yaml_** file present in the repository. In this file, you will need to set the following values:

  - **AWS_ACCOUNT**: your AWS account ID.
  - **AWS_ACCESS_KEY_ID**: your AWS access key.
  - **AWS_SECRET_ACCESS_KEY**: your AWS secret access key.
  - **AWS_REGION**: the AWS region where your ECR is located.

Once you have made these changes, save and exit the install.yaml file.

Now, to install the **_[k8s-aws-ecr-secret-updater](https://github.com/paranoiasystem/k8s-aws-ecr-secret-updater)_** in your Kubernetes cluster, you need to execute the following command:

```sh
kubectl apply -n <destination_namespace> -f install.yaml
```

Remember to replace **destination_namespace** with the Kubernetes namespace where you want to install the cronjob.

## Conclusions

This tool eliminates the need for manual updating of credentials, saving time and reducing the risk of errors. I hope this article and the tool I created can be of help to anyone dealing with a similar issue in managing AWS ECR credentials in a Kubernetes cluster.