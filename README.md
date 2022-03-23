# Getting Started

First download a license from https://deployer.wandb.ai and set it in your environment:

```shell
export LICENSE=XXXXXXX
```

For persistance you'll need an S3 compatible object store, be sure your container has AWS credentials (potentially use extraEnv) and specify the bucket and region with:

```shell
export BUCKET=s3://my-bucket
export BUCKET_REGION=us-east-1
```

Then provision your instance with:

```shell
git clone https://github.com/wandb/charts.git
cd charts/wandb
helm upgrade --namespace=wandb --create-namespace --install wandb . --set license=$LICENSE --set bucket=$BUCKET --set bucketRegion=$BUCKET_REGION
```