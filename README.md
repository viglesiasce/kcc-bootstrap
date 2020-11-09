# Kubernetes Config Connector Getting Started

This repositories contains automation to quickly provision a
[Config Connector](https://cloud.google.com/config-connector/docs/overview) cluster.

## Installation

1. Install Terraform and kubectl

1. Set your GCP project ID as an environment variable

    ```shell
    export PROJECT_ID=<INSERT-PROJECT-ID>
    ```

1. Run Terraform to provision the cluster and its dependencies

    ```shell
    terraform plan -var project_id=$PROJECT_ID
    terraform apply -var project_id=$PROJECT_ID
    ```

1. Download the cluster's credentials

    ```shell
    gcloud container clusters get-credentials --region us-central1 kcc-bootstrap
    ```

1. Apply the configuration for the Config Connector:

    ```shell
    sed -i s/PROJECT_ID/$PROJECT_ID/g configconnector.yaml
    kubectl apply -f configconnector.yaml
    ```

1. Annotate your namespace with the project you'd like resources to be created in

    ```shell
    kubectl annotate namespace default cnrm.cloud.google.com/project-id=$PROJECT_ID
    ```

1. (Optional) Test the setup by creating a bucket in your project

    ```shell
    sed -i s/PROJECT_ID/$PROJECT_ID/g bucket.yaml
    kubectl apply -f bucket.yaml
    watch gsutil ls gs://$PROJECT_ID-kcc-bootstrap-demo
    ```
