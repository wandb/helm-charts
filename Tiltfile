#default values
settings = {
    "allowedContexts": [
        "docker-desktop",
        "minikube",
        "kind-kind",
    ],
    "installMinio": True,
    "installIngress": False,
    "values": "default",
    "additionalValues": {},
}

# global settings
settings.update(read_json(
    "tilt-settings.json",
    default={},
))

settings["operator-wandb-values"] = "./test-configs/operator-wandb/" + settings['values'] + ".yaml"
settings["additional-resource-directory"] = "./test-configs/additional-resources/" + settings['values'] + ""

if os.path.exists(settings["additional-resource-directory"]):
    for file in listdir(settings["additional-resource-directory"]):
        if file.endswith(".yaml") or file.endswith(".yml"):
            k8s_yaml(os.path.join(settings["additional-resource-directory"], file))

if k8s_context() in settings.get("allowedContexts"):
    print("Context is allowed")
else:
    fail("Selected context is not in allow list")

allow_k8s_contexts(settings.get("allowed_k8s_contexts"))

current_values = read_yaml(settings["operator-wandb-values"])

if settings.get("installMinio"):
    k8s_yaml('./test-configs/minio/default.yaml')
    k8s_resource(
        'minio',
        'Minio',
        objects=[
            'minio:service',
            'minio:namespace'
        ]
    )

if settings.get("installIngress"):
    k8s_yaml('./test-configs/ingress/default.yaml')
    k8s_resource(
        new_name='ingress-nginx',
        objects=[
            'ingress-nginx:namespace',
            'ingress-nginx:serviceaccount',
            'ingress-nginx:role',
            'ingress-nginx-admission:role',
            'ingress-nginx:clusterrole',
            'ingress-nginx-admission:clusterrole',
            'ingress-nginx:rolebinding',
            'ingress-nginx-admission:rolebinding',
            'ingress-nginx:clusterrolebinding',
            'ingress-nginx-admission:clusterrolebinding',
            'ingress-nginx-admission:serviceaccount',
            'ingress-nginx-controller:configmap',
        ]
    )
    k8s_resource(
        'ingress-nginx-admission-create',
        resource_deps=[
            'ingress-nginx'
        ]
    )
    k8s_resource(
        'ingress-nginx-admission-patch',
        resource_deps=[
            'ingress-nginx'
        ]
    )
    k8s_resource(
        'ingress-nginx-controller',
        objects=[
            'nginx:ingressclass',
            'ingress-nginx-admission:validatingwebhookconfiguration'
        ],
        resource_deps=[
            'ingress-nginx', 'ingress-nginx-admission-create'
        ]
    )

helmSetValues = []
for key, value in settings["additionalValues"].items():
    helmSetValues.append(key + '=' + value)

k8s_yaml(helm('./charts/operator-wandb', 'wandb', values=['./charts/operator-wandb/values.yaml', settings.get("operator-wandb-values")], set=helmSetValues))
k8s_resource('wandb-app', port_forwards=8080, objects=['wandb-app:ServiceAccount:default', 'wandb-app-config:secret:default'])
k8s_resource('wandb-console', port_forwards=8082, objects=['wandb-console:ServiceAccount:default', 'wandb-console:clusterrole:default', 'wandb-console:clusterrolebinding:default'])
if current_values.get('executor', {}).get('install', False):
    k8s_resource('wandb-executor',objects=['wandb-executor:ServiceAccount:default'])
k8s_resource('wandb-mysql', trigger_mode=TRIGGER_MODE_MANUAL)
k8s_resource('wandb-otel-daemonset',objects=['wandb-otel-daemonset:ServiceAccount:default', 'wandb-otel-daemonset:clusterrole:default', 'wandb-otel-daemonset:clusterrolebinding:default'])
k8s_resource('wandb-parquet',objects=['wandb-parquet:ServiceAccount:default'])
k8s_resource('wandb-prometheus-server',objects=['wandb-prometheus-server:ServiceAccount:default', 'wandb-prometheus-server:clusterrole:default', 'wandb-prometheus-server:clusterrolebinding:default'])
k8s_resource('wandb-redis-master',objects=['wandb-redis-master:ServiceAccount:default'])
if current_values.get('reloader', {}).get('install', False):
    k8s_resource('wandb-reloader',objects=['wandb-reloader:ServiceAccount:default'])
k8s_resource('wandb-weave',objects=['wandb-weave:ServiceAccount:default'])
if current_values.get('weave-trace', {}).get('install', False):
    k8s_resource('wandb-weave-trace', port_forwards=8722)
k8s_resource(
    new_name='wandb-configs',
    objects=[
        'wandb-bucket-configmap:configmap:default',
        'wandb-bucket:secret:default',
        'wandb-ca-certs:configmap:default',
        'wandb-clickhouse:secret:default',
        'wandb-global-secret:secret:default',
        'wandb-glue-configmap:configmap:default',
        'wandb-glue-secret:secret:default',
        'wandb-gorilla-configmap:configmap:default',
        'wandb-gorilla-secret:secret:default',
        'wandb-kafka-configmap:configmap:default',
        'wandb-kafka:secret:default',
        'wandb-mysql-configmap:configmap:default',
        'wandb-redis-configmap:configmap:default',
        'wandb-redis-secret:secret:default',
    ]
)
k8s_resource(new_name='DO NOT REFRESH THESE', objects=['wandb-mysql:secret:default', 'wandb-gorilla-session-key:secret:default'], trigger_mode=TRIGGER_MODE_MANUAL)
k8s_resource(new_name='PVCs', objects=['wandb-mysql-data:PersistentVolumeClaim:default', 'wandb-prometheus-server:PersistentVolumeClaim:default'], trigger_mode=TRIGGER_MODE_MANUAL)
