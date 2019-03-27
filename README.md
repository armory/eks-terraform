# Terraform EKS Scripts

## Changes that have to be made

### To allow access to the EKS cluster

In [outputs.tf](outputs.tf#L22) make sure to change `ACCOUNT_ID` to be your AWS account ID. Also change `myuser` to the user that you already have created to access the EKS cluster. You can add more users with the same groups to give them access to the cluster.

In [outputs.tf](outputs.tf#L57) make sure to change `MY_AWS_PROFILE` to be the AWS profile that you are using.

### To allow storing Terraform state in the cloud

In [providers.tf](providers.tf#L8) make sure to change `MY_AWS_PROFILE` to be the AWS profile that you are using.

In [providers.tf](providers.tf#L25) make sure to change `BUCKET_NAME` to be the S3 bucket you want to store the Terraform state in.

In [providers.tf](providers.tf#L26) make sure to change `KEY_NAME` to be the S3 key inside the bucket you want to store the Terraform state in.

In [providers.tf](providers.tf#L28) make sure to change `MY_AWS_PROFILE` to be the AWS profile that you are using.

## How To Use
```bash
# you may need to do this on the first time
terraform init

# to see what will happen with the configuration.
terraform plan

# to actually apply the changes.
terraform apply

# to generate a kubeconfig file to be used to connect to the cluster
terraform output kubeconfig > kubeconfig

# to generate a ConfigMap to allow users access to the cluster
terraform output config_map_aws_auth > config-map-aws-auth.yaml

# to apply the ConfigMap to the cluster
kubectl --kubeconfig kubeconfig apply -f config-map-aws-auth.yaml
```
