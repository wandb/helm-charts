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

Running a MySQL database in your k8s cluster is not recommended. This chart does not provide any way to backup the data or ensure the database can scale. You'll need to manually increase the resources requested for the database and the size of the volume as load increases. If possible you should use an external database service and set the following variables:

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

# Mounting SSL Certificates to the Deployment

Important Note: W&B strongly recommends against using a self-signed certificate and would suggest getting a CA certificate that works best with all network configurations and doesn't need any extra work to setup.

To mount self-signed SSL certificates to your wandb deployment, follow these steps:

1. Create a Kubernetes secret containing the SSL certificate and private key:

```bash
kubectl create secret tls wandb-tls --cert=path/to/tls.crt --key=path/to/tls.key -n wandb
```

Replace `path/to/tls.crt` and `path/to/tls.key` with the paths to your SSL certificate and private key files, respectively.

2. Update your `values.yaml` file to configure the ingress to use the created secret for TLS:

```yaml
ingress:
    enabled: true
    ...
    tls:
    - secretName: wandb-tls
    hosts:
        - your-domain.com
```

Replace `your-domain.com` with your desired domain name.

3. Apply the changes by upgrading the Helm release:

```bash
helm upgrade --namespace=wandb wandb ./charts/wandb --set license=$LICENSE --set bucket=$BUCKET --set bucketRegion=$BUCKET_REGION
```

Now, your wandb deployment will use the mounted SSL certificate for securing communication over HTTPS.

### Configuring the wandb python SDK to leverage the self-signed SSL Certificates

To configure the wandb SDK to use the SSL certificates, follow these steps:

1. Set the `REQUESTS_CA_BUNDLE` and `SSL_CERT_FILE` environment variables to the path of the certificate file:

```python
import os
os.environ['REQUESTS_CA_BUNDLE'] = '/path/to/cert.pem'
os.environ['SSL_CERT_FILE'] = '/path/to/cert.pem'
```

2. Append your self-signed certificate to the default CA bundle to allow both self-signed and default certificates to be used:

```bash
cat /path/to/selfsigned.cer >> /path/to/cacert.pem
```

Now, the wandb SDK will be able to use the SSL certificates for HTTPS communication.

# Upgrade Guide

For information on upgrading the Helm module and wandb server version, please refer to the [upgrade guide](./upgrade.md).
