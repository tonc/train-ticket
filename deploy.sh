#!/bin/bash

# Define necessary variables
mysqlCharts=deployment/kubernetes-manifests/quickstart-k8s/charts/mysql
nacosCharts=deployment/kubernetes-manifests/quickstart-k8s/charts/nacos
rabbitmqCharts=deployment/kubernetes-manifests/quickstart-k8s/charts/rabbitmq
nacosDBRelease="nacosdb"
nacosDBHost="${nacosDBRelease}-mysql-leader"
nacosDBUser="nacos"
nacosDBPass="Abcd1234#"
nacosDBName="nacos"
nacosRelease="nacos"
rabbitmqRelease="rabbitmq"
tsUser="ts"
tsPassword="Ts_123456"
tsDB="ts"
tsMysqlName="tsdb"
svc_list="assurance auth config consign-price consign contacts delivery food food-delivery inside-payment notification order-other order payment price route security station-food station ticket-office train-food train travel travel2 user voucher wait-order"

secret_yaml="deployment/kubernetes-manifests/quickstart-k8s/yamls/secret.yaml"
dp_sample_yaml="deployment/kubernetes-manifests/quickstart-k8s/yamls/deploy.yaml.sample"
sw_dp_sample_yaml="deployment/kubernetes-manifests/quickstart-k8s/yamls/sw_deploy.yaml.sample"
dp_yaml="deployment/kubernetes-manifests/quickstart-k8s/yamls/deploy.yaml"
sw_dp_yaml="deployment/kubernetes-manifests/quickstart-k8s/yamls/sw_deploy.yaml"

# Get the namespace from command line argument or set to "default" if not provided
namespace=${1:-default}

# Utility function to wait for all pods in a namespace to be ready
function wait_for_pods_ready {
  local namespace=$1
  echo "Waiting for all pods in namespace '$namespace' to be ready..."

  while true; do
    # Check the 'READY' column for pods that are not fully ready
    non_ready_pods=$(kubectl get pods -n "$namespace" --no-headers | awk '{split($2,a,"/"); if (a[1] != a[2]) print $1}' | wc -l)

    if [ "$non_ready_pods" -eq 0 ]; then
      echo "All pods in namespace '$namespace' are ready."
      break
    fi

    echo "$non_ready_pods pod(s) are not ready yet. Checking again in 10 seconds..."
    sleep 10
  done
}

# Step 1: Deploy infrastructure services
function deploy_infrastructures {
  echo "Start deployment Step <1/3>------------------------------------"
  echo "Start to deploy mysql cluster for nacos."
  helm install $nacosDBRelease --set mysql.mysqlUser=$nacosDBUser --set mysql.mysqlPassword=$nacosDBPass --set mysql.mysqlDatabase=$nacosDBName $mysqlCharts -n $namespace
  echo "Waiting for mysql cluster of nacos to be ready ......"
  kubectl rollout status statefulset/$nacosDBRelease-mysql -n $namespace
  echo "Finish nacos DB rollout.."
}

# Step 2: Patch Nacos MySQL cluster
function patch_nacos_mysql {
  echo "Patching Nacos MySQL cluster..."
  for pod in $(kubectl get pods -n "$namespace" --no-headers -o custom-columns=":metadata.name" | grep nacosdb-mysql); do
    kubectl exec "$pod" -n "$namespace" -- mysql -uroot -e "CREATE USER IF NOT EXISTS 'root'@'::1' IDENTIFIED WITH mysql_native_password BY '' ; GRANT ALL ON *.* TO 'root'@'::1' WITH GRANT OPTION ;"
    kubectl exec "$pod" -n "$namespace" -c xenon -- /sbin/reboot
  done
  wait_for_pods_ready $namespace
}

# Step 3: Deploy MySQL for Train Ticket services
function continue_deployment {
  echo "Start deployment Step <2/3>: Deploying services----------------------"
  
  # Deploy Nacos
  echo "Start to deploy nacos."
  helm install $nacosRelease --set nacos.db.host=$nacosDBHost --set nacos.db.username=$nacosDBUser --set nacos.db.name=$nacosDBName --set nacos.db.password=$nacosDBPass $nacosCharts -n $namespace
  echo "Waiting for nacos to be ready ......"
  kubectl rollout status statefulset/$nacosRelease -n $namespace
  
  # Deploy RabbitMQ
  echo "Start to deploy rabbitmq."
  helm install $rabbitmqRelease $rabbitmqCharts -n $namespace
  echo "Waiting for rabbitmq to be ready ......"
  kubectl rollout status deployment/$rabbitmqRelease -n $namespace
  
  # Deploy MySQL for Train Ticket services
  echo "Start deployment Step <2/3>: mysql cluster of train-ticket services----------------------"
  helm install $tsMysqlName --set mysql.mysqlUser=$tsUser --set mysql.mysqlPassword=$tsPassword --set mysql.mysqlDatabase=$tsDB $mysqlCharts -n $namespace
  echo "Waiting for mysql cluster of train-ticket to be ready ......"
  kubectl rollout status statefulset/${tsMysqlName}-mysql -n $namespace
  
  # Generate secrets for Train Ticket services
  gen_secret_for_services $tsUser $tsPassword $tsDB "${tsMysqlName}-mysql-leader"
  echo "End deployment Step <2/3>-----------------------------------------------------------------"
}

# Step 4: Patch Train Ticket MySQL cluster
function patch_tt_mysql {
  echo "Patching Train Ticket MySQL cluster..."
  for pod in $(kubectl get pods -n "$namespace" --no-headers -o custom-columns=":metadata.name" | grep tsdb-mysql); do
    kubectl exec "$pod" -n "$namespace" -- mysql -uroot -e "CREATE USER IF NOT EXISTS 'root'@'::1' IDENTIFIED WITH mysql_native_password BY '' ; GRANT ALL ON *.* TO 'root'@'::1' WITH GRANT OPTION ;"
    kubectl exec "$pod" -n "$namespace" -c xenon -- /sbin/reboot
  done
  wait_for_pods_ready $namespace
}

# Step 5: Generate MySQL secrets for Train Ticket services
function gen_secret_for_services {
  echo "Generating secrets for Train Ticket services..."
  rm -f $secret_yaml && touch $secret_yaml
  for s in $svc_list; do
    cat >> $secret_yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ts-$s-mysql
  namespace: $namespace
type: Opaque
stringData:
  ${s^^}_HOST: "ts-$s-mysql-leader"
  ${s^^}_PORT: "3306"
  ${s^^}_DATABASE: "$tsDB"
  ${s^^}_USER: "$tsUser"
  ${s^^}_PASSWORD: "$tsPassword"
---
EOF
  done
}

# Step 6: Complete deployment of Train Ticket services
function complete_deployment {
  echo "Completing deployment of Train Ticket services..."

  # Apply MySQL secrets
  echo "Applying MySQL secrets for Train Ticket services..."
  kubectl apply -f $secret_yaml

  # Apply service configurations
  echo "Applying service configurations..."
  kubectl apply -f deployment/kubernetes-manifests/quickstart-k8s/yamls/svc.yaml -n $namespace

  # Update and apply Skywalking deployment configuration
  echo "Updating Skywalking deployment configuration..."
  update_tt_sw_dp_cm $nacosRelease $rabbitmqRelease
  kubectl apply -f $sw_dp_yaml -n $namespace

  # Deploy Skywalking
  echo "Deploying Skywalking..."
  kubectl apply -f deployment/kubernetes-manifests/skywalking -n kube-system

  # Deploy Prometheus and Grafana
  echo "Deploying Prometheus and Grafana..."
  kubectl apply -f deployment/kubernetes-manifests/prometheus -n kube-system

  # Wait for all pods to be ready
  echo "Waiting for all pods to be ready in namespace '$namespace'..."
  wait_for_pods_ready $namespace

  echo "Deployment complete!"
}

# Main script execution
deploy_infrastructures
wait_for_pods_ready $namespace
patch_nacos_mysql
continue_deployment
wait_for_pods_ready $namespace
patch_tt_mysql
complete_deployment