load('ext://namespace', 'namespace_create')
#default values
settings = {
    "allowedContexts": [
        "docker-desktop",
        "minikube",
        "kind-kind",
        "kind-wandb-helm-charts",
        "orbstack",
    ],
    "forwardedPorts": {
        "nginx": 8080,
    },
    "installMinio": True,
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

current_namespace = k8s_namespace()
namespace_create(current_namespace)

if settings.get("installMinio"):
    k8s_yaml('./test-configs/minio/default.yaml')
    k8s_resource(
        'minio',
        'Minio',
        objects=[
            'minio:service'
        ],
        port_forwards="9090:9090"
    )

k8s_yaml('./test-configs/keycloak/default.yaml')
k8s_yaml(helm('./charts/wandb-base', 'pubsub', namespace=current_namespace, values=['./test-configs/pubsub/values.yaml']))
k8s_yaml(helm('./charts/wandb-base', 'bigtable', namespace=current_namespace, values=['./test-configs/bigtable/values.yaml']))

helmSetValues = []
for key, value in settings["defaultValues"].items():
    helmSetValues.append(key + '=' + value)
for key, value in settings["additionalValues"].items():
    helmSetValues.append(key + '=' + value)

# Disable anaconda in app if separate anaconda2 service is enabled
if current_values.get('anaconda2', {}).get('install', False):
    helmSetValues.append('app.env.ANACONDA_ENABLED=false')
    helmSetValues.append('global.anaconda2.enabled=true')

k8s_yaml(helm('./charts/operator-wandb', 'wandb', namespace=current_namespace, values=['./charts/operator-wandb/values.yaml', settings.get("operator-wandb-values")], set=helmSetValues))
app_names = {}
for app in ['app', 'console', 'executor', 'parquet', 'weave', 'weave-trace']:
    app_names[app] = 'wandb-' + app
    postfix = current_values.get(app, {}).get('deploymentPostfix', "")
    if postfix != "":
        app_names[app] += '-' + postfix
k8s_resource(app_names['app'], objects=['wandb-app:ServiceAccount:' + current_namespace])
k8s_resource(app_names['console'])
k8s_resource("wandb-nginx", port_forwards=settings["forwardedPorts"]["nginx"], objects=['wandb-console:ServiceAccount:' + current_namespace])
if current_values.get('anaconda2', {}).get('install', False):
    k8s_resource('wandb-anaconda2', objects=['wandb-anaconda2:ServiceAccount:' + current_namespace])
if current_values.get('executor', {}).get('install', False):
    k8s_resource(app_names['executor'],objects=['wandb-executor:ServiceAccount:' + current_namespace])
k8s_resource('wandb-mysql', trigger_mode=TRIGGER_MODE_MANUAL)
k8s_resource('wandb-otel-daemonset',objects=['wandb-otel-daemonset:ServiceAccount:' + current_namespace, 'wandb-otel-daemonset:clusterrole:' + current_namespace, 'wandb-otel-daemonset:clusterrolebinding:' + current_namespace])
k8s_resource(app_names['parquet'],objects=['wandb-parquet:ServiceAccount:' + current_namespace])
k8s_resource('wandb-prometheus-server',objects=['wandb-prometheus-server:ServiceAccount:' + current_namespace, 'wandb-prometheus-server:clusterrole:' + current_namespace, 'wandb-prometheus-server:clusterrolebinding:' + current_namespace])
k8s_resource('wandb-redis-master',objects=['wandb-redis-master:ServiceAccount:' + current_namespace])
if current_values.get('reloader', {}).get('install', False):
    k8s_resource('wandb-reloader',objects=['wandb-reloader:ServiceAccount:' + current_namespace])
k8s_resource(app_names['weave'],objects=['wandb-weave:ServiceAccount:' + current_namespace])
# if current_values.get('weave-trace', {}).get('install', False):
#     k8s_resource(app_names['weave-trace'])

configObjects = [
    'wandb-api-configmap:configmap:' + current_namespace,
    'wandb-app-configmap:configmap:' + current_namespace,
    'wandb-bucket-configmap:configmap:' + current_namespace,
    'wandb-bucket:secret:' + current_namespace,
    'wandb-ca-certs:configmap:' + current_namespace,
    'wandb-clickhouse-configmap:configmap:' + current_namespace,
    'wandb-console-configmap:configmap:' + current_namespace,
    'wandb-executor-configmap:configmap:' + current_namespace,
    'wandb-flat-run-fields-updater-configmap:configmap:' + current_namespace,
    'wandb-frontend-configmap:configmap:' + current_namespace,
    'wandb-local-configmap:configmap:' + current_namespace,
    'wandb-parquet-configmap:configmap:' + current_namespace,
    'wandb-weave-trace-configmap:configmap:' + current_namespace,
    'wandb-weave-configmap:configmap:' + current_namespace,
    'wandb-filestream-configmap:configmap:' + current_namespace,
    'wandb-global-secret:secret:' + current_namespace,
    'wandb-glue-configmap:configmap:' + current_namespace,
    'wandb-kafka-configmap:configmap:' + current_namespace,
    'wandb-kafka:secret:' + current_namespace,
    'wandb-mysql-configmap:configmap:' + current_namespace,
    'wandb-redis-configmap:configmap:' + current_namespace,
    'wandb-redis-secret:secret:' + current_namespace,
    'wandb-gorilla-session-key:secret:' + current_namespace,
]

# if current_values.get('weave-trace', {}).get('install', False):
#     configObjects.append('wandb-clickhouse-configmap:configmap:' + current_namespace)

k8s_resource(
    new_name='wandb-configs',
    objects=configObjects
)
k8s_resource(new_name='DO NOT REFRESH THESE', objects=['wandb-mysql:secret:' + current_namespace, 'wandb-clickhouse:secret:' + current_namespace], trigger_mode=TRIGGER_MODE_MANUAL)
k8s_resource(new_name='PVCs', objects=['wandb-mysql-data:PersistentVolumeClaim:' + current_namespace, 'wandb-prometheus-server:PersistentVolumeClaim:' + current_namespace], trigger_mode=TRIGGER_MODE_MANUAL)
