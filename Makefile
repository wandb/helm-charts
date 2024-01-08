default:
	helm dependency build ./charts/operator-wandb/
	helm upgrade --namespace=default --create-namespace --install wandb ./charts/operator-wandb

clear-containers:
	kubectl get pods | grep cron | cut -d' ' -f1 | xargs kubectl delete pod
