# Simple Time Service API

## Overview
This repository contains the "simple_time_service" api and aswell the terraform stack to deploy a kubernetes environment on AWS using EKS.

## Running the simple_time_service api locally
There are two ways to run the api locally

### Using Docker
    ```sh
    docker run -p 8000:8000 32682504/simple_time_service:latest
    ```

### Cloning the project
1. **Clone the Repository**:
    ```sh
    git clone https://github.com/nicomana/simple_time_service
    cd simple_time_service/app
    ```

2. **Install Dependencies**:
    Ensure you have python and pip installed in your local machine then run:
    ```sh
    pip install -r requirements.txt
    ```

3. **Start the Api**:
    ```sh
    python simple_time_service.py
    ```

4. **Access the Application**:
    Open your web browser and navigate to `http://localhost:8000` to view the application or 
    ```sh
    curl http://localhost:8000
    ```

### Response
The api listens on the port 8000 and it will return a pure JSON response containing the current `timestamp` and the `ip` of the caller like in the example bellow:
`{"timestamp":"2025-01-09T02:54:11.447255","ip":"127.0.0.1"}`

### Deploy to your Kubernetes
In the root folder of this repo you can find a YAML manifesto called `microservice.yaml` that will configure a service and a deploy with the simple api.

To install it, on your console of choise get context to yor kubernetes cluster and run the following command
```
kubectl apply -f microservice.yaml -n NAME_SPACE
```
The manifest will deploy 3 replicas by default, this can be configured in the .yaml file. to validate the deployment was succesful run:
```
kubectl get po -n NAME_SPACE
```

## Infrastructure

The infrastructure is managed by `terraform`, to deploy you'll have to export your AWS credentials in your environment and then run the terraform commands:

1. **Clone the Repository**:
    ```sh
    git clone https://github.com/nicomana/simple_time_service
    cd simple_time_service/terraform
    ```

2. **Export your AWS Credentials**:
    ```sh
    export AWS_ACCESS_KEY_ID=<KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<SECRET_KEY_ID>
    ```

2. **Navigate to the Terraform directory**:
    ```sh
    cd terraform/
    ```

3. **Init and Plan to Validate the Stack**:
    ```sh
    terraform init
    terraform plan
    ```

4. **Apply Changes**:
    ```sh
    terraform apply
    ```

Once the stack is deployed, for this example, the EKS cluster endpoint will be accessible through a console using the following command

    ```sh
    export AWS_ACCESS_KEY_ID=<KEY_ID>
    export AWS_SECRET_ACCESS_KEY=<SECRET_KEY_ID>
    aws eks update-kubeconfig --name particle41-dev-cluster
    ```
To remove delete the full stack run:
```
terraform destroy
```

# CI-CD

This repository has CICD configured to
1. Build the api
2. Deploy the infrastructure

When a Pull Request is created the pipeline will
- Build the docker image
- Validate the Terraform code
- Run `terraform plan` to validate the changes

When a Pull Request is merged to main **(Ideally this step would enforce a peer review)**
- The docker image will be pushed to docker hub
- Terraform will apply the changes

For the CICD to work the pipeline uses 4 secrets that are injected at runtime managed by github actions
- AWS_ACCESS_KEY
- AWS_SECRET_KEY
- DOCKER_HUB_ID
- DOCKER_HUB_PASSWD
These steps can be configured under the folder `simple_time_service/.github/workflows`

Next steps for CICD
- Multiple TF environments recognizing the branch origin
- Pylint
- Terraform lint
- Docker Image Scan
- Add backend to Terraform

# Monitoring
Prometheus and Grafana have been added to the EKS cluster with a basic hardcoded password that is enforced to be changed on the first login to Grafana.
The configs for these two services are not ready at this stage.

