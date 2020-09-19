Google Cloud Platform Kubernetes Cluster Terraform Module



Problem: Terraform does not keep state on the bucket. If you need to destroy your infrastructure you could lose your important file. 

Solution Process:


a) We have to create the bucket manually and add that information in the backent.tf file. 
b) We have to add set-env.sh file and run source set-env.sh cluster.tfvar 



Those following steps provide us to set the infrastructure and keep the bucket secure:

Use this deployment to easily deploy a Kubernetes cluster on Google Cloud Platform (GCP)'s Google Kubernetes Engine (GKE).

In order to do so we need to have 4 files:

* ```kubecluster-deployment.tf``` -- contains the definition of what we want to achieve

* ```variables.tf``` -- contains the variables definition.

* ```config.tfvars``` -- contains the values for variables.

* ```service_account_key.json``` -- contains the service account key.


1. In order to deploy kubernetes cluster in GCP

* You need to clone cluster-infrastructure repository from Fuchicorp. And go to kube-cluster folder 
```
git clone https://github.com/fuchicorp/cluster-infrastructure.git
cd cluster-infrastructure/kube-cluster/
```

2. Run setup-google-platform.sh  
```
    source setup-google-platform.sh fuchicorp-example-bucket
```

This script creates a service account and binds following roles to it. It also creates json file for your service account and bucket. When you run script you have to provide as user input unique bucket name ( in our example it is fuchicorp-example-bucket)

  
```
PROJECT OWNER
Kubernetes Engine Admin
DNS Admin
Storage Admin

```




3.

Create config.tfvars file

Create config.tfvars file with following content:
```
cluster_name            =    "example-name"
node_count              =    "2"
cpath                   =    "PATH/service_account_key.json"    # Path where ur service account key is located
project                 =    "example-240119"                   # Project_id
region                  =    "us-central1"                      # Region
node_name               =    "example"
```


4.  use the set-env.sh file  run this command
    ```source set-env.sh cluster.tfvars```



Plan before Apply

We need to plan all changes before applying them. That`s why we need to run the following command:

```terraform plan -var-file=$DATAFILE```   Displays what would be executed

Deploy the changes by applying

For applying all changes we need to run the following command:

```terraform apply  -var-file=$DATAFILE```    


if need destroy all the changes

To destroy everything please run the following command:

```terraform destroy -var-file=$DATAFILE```  
