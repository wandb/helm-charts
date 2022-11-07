# Getting Started

First download a license from https://deploy.wandb.ai and set it in your environment:

```shell
export LICENSE=XXXXXXX
```

For persistance you'll need an S3 compatible object store, be sure your container has AWS credentials (potentially use extraEnv) and specify the bucket and region with:

```shell
export BUCKET=s3://my-bucket
export BUCKET_REGION=us-east-1
```

## A note on the database

Running a MySQL database in your k8s cluster is not recommended.  This chart does not provide any way to backup the data or ensure the database can scale.  You'll need to manually increase the resources requested for the database and the size of the volume as load increases.  If possible you should use an external database service and set the following variables:

```shell
--set mysql.managed=false --set mysql.host=db.host --set mysql.user=wandb --set mysql.password=XXX --set mysql.database=wandb
```

You can create a database and grant the needed access with:

```sql
CREATE USER 'wandb'@'%' IDENTIFIED BY 'XXX';
CREATE DATABASE wandb CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL ON wandb.* TO 'wandb'@'%' WITH GRANT OPTION;
```

## Install from our helm repo

```shell
helm repo add wandb https://wandb.github.io/helm-charts
helm upgrade --namespace=wandb --create-namespace --install wandb wandb/wandb --version 0.2.0 --set license=$LICENSE --set bucket=$BUCKET --set bucketRegion=$BUCKET_REGION
```

## Install from source

Then provision your instance with:

```shell
git clone https://github.com/wandb/helm-charts.git
cd helm-charts
helm upgrade --namespace=wandb --create-namespace --install wandb ./charts/wandb --set license=$LICENSE --set bucket=$BUCKET --set bucketRegion=$BUCKET_REGION
```
