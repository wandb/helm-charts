#default values
settings = {
    "allowedContexts": [
        "docker-desktop",
        "minikube",
        "kind-kind",
    ],
    "forwardedPorts": {
        "nginx": 8080,
    },
    "installMinio": True,
    "installIngress": False,
    "values": "default",
    "defaultValues": {
        "global.mysql.password": "password",
        "global.env.GLOBAL_ADMIN_API_KEY": "",
        "reloader.install": "true",
    },
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

current_values = read_yaml('./charts/operator-wandb/values.yaml')
local_values = read_yaml(settings["operator-wandb-values"])
for key, value in local_values.items():
    if key in current_values:
        current_values[key].update(value)
    else:
        current_values[key] = value

if settings.get("installMinio"):
    k8s_yaml('./test-configs/minio/default.yaml')
    k8s_resource(
        'minio',
        'Minio',
        objects=[
            'minio:service',
            'minio:namespace'
        ],
        port_forwards="9090:9090"
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

if current_values.get('global', {}).get('pubSub', {}).get('enabled', False):
    k8s_yaml(helm('./charts/wandb-base', 'pubsub', values=['./test-configs/pubsub/values.yaml']))

if current_values.get('global', {}).get('bigtable', {}).get('v2', {}).get('enabled', False):
    k8s_yaml(helm('./charts/wandb-base', 'bigtable', values=['./test-configs/bigtable/values.yaml']))

helmSetValues = []
for key, value in settings["defaultValues"].items():
    helmSetValues.append(key + '=' + value)
for key, value in settings["additionalValues"].items():
    helmSetValues.append(key + '=' + value)

# Disable anaconda in app if separate anaconda2 service is enabled
if current_values.get('anaconda2', {}).get('install', False):
    helmSetValues.append('app.env.ANACONDA_ENABLED=false')
    helmSetValues.append('global.anaconda2.enabled=true')

k8s_yaml(helm('./charts/operator-wandb', 'wandb', values=['./charts/operator-wandb/values.yaml', settings.get("operator-wandb-values")], set=helmSetValues))
app_names = {}
for app in ['app', 'console', 'executor', 'parquet', 'weave', 'weave-trace']:
    app_names[app] = 'wandb-' + app
    postfix = current_values.get(app, {}).get('deploymentPostfix', "")
    if postfix != "":
        app_names[app] += '-' + postfix
k8s_resource(app_names['app'], objects=['wandb-app:ServiceAccount:default'])
k8s_resource(app_names['console'])
k8s_resource("wandb-nginx", port_forwards=settings["forwardedPorts"]["nginx"], objects=['wandb-console:ServiceAccount:default'])
if current_values.get('anaconda2', {}).get('install', False):
    k8s_resource('wandb-anaconda2', objects=['wandb-anaconda2:ServiceAccount:default'])
if current_values.get('executor', {}).get('install', False):
    k8s_resource(app_names['executor'],objects=['wandb-executor:ServiceAccount:default'])
k8s_resource('wandb-mysql', trigger_mode=TRIGGER_MODE_MANUAL)
k8s_resource('wandb-otel-daemonset',objects=['wandb-otel-daemonset:ServiceAccount:default', 'wandb-otel-daemonset:clusterrole:default', 'wandb-otel-daemonset:clusterrolebinding:default'])
k8s_resource(app_names['parquet'],objects=['wandb-parquet:ServiceAccount:default'])
k8s_resource('wandb-prometheus-server',objects=['wandb-prometheus-server:ServiceAccount:default', 'wandb-prometheus-server:clusterrole:default', 'wandb-prometheus-server:clusterrolebinding:default'])
k8s_resource('wandb-redis-master',objects=['wandb-redis-master:ServiceAccount:default'])
if current_values.get('reloader', {}).get('install', False):
    k8s_resource('wandb-reloader',objects=['wandb-reloader:ServiceAccount:default'])
k8s_resource(app_names['weave'],objects=['wandb-weave:ServiceAccount:default'])
# if current_values.get('weave-trace', {}).get('install', False):
#     k8s_resource(app_names['weave-trace'])

configObjects = [
    'wandb-api-configmap:configmap:default',
    'wandb-app-configmap:configmap:default',
    'wandb-bucket-configmap:configmap:default',
    'wandb-bucket:secret:default',
    'wandb-ca-certs:configmap:default',
    'wandb-clickhouse-configmap:configmap:default',
    'wandb-console-configmap:configmap:default',
    'wandb-executor-configmap:configmap:default',
    'wandb-flat-run-fields-updater-configmap:configmap:default',
    'wandb-frontend-configmap:configmap:default',
    'wandb-local-configmap:configmap:default',
    'wandb-parquet-configmap:configmap:default',
    'wandb-weave-trace-configmap:configmap:default',
    'wandb-weave-configmap:configmap:default',
    'wandb-filestream-configmap:configmap:default',
    'wandb-global-secret:secret:default',
    'wandb-glue-configmap:configmap:default',
    'wandb-kafka-configmap:configmap:default',
    'wandb-kafka:secret:default',
    'wandb-mysql-configmap:configmap:default',
    'wandb-redis-configmap:configmap:default',
    'wandb-redis-secret:secret:default',
    'wandb-gorilla-session-key:secret:default',
]

# if current_values.get('weave-trace', {}).get('install', False):
#     configObjects.append('wandb-clickhouse-configmap:configmap:default')

k8s_resource(
    new_name='wandb-configs',
    objects=configObjects
)
k8s_resource(new_name='DO NOT REFRESH THESE', objects=['wandb-mysql:secret:default', 'wandb-clickhouse:secret:default'], trigger_mode=TRIGGER_MODE_MANUAL)
k8s_resource(new_name='PVCs', objects=['wandb-mysql-data:PersistentVolumeClaim:default', 'wandb-prometheus-server:PersistentVolumeClaim:default'], trigger_mode=TRIGGER_MODE_MANUAL)
