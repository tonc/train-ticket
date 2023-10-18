#!/bin/bash

# Define the root directory
TT_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Source necessary scripts
source "$TT_ROOT/utils.sh"

# Get the namespace from command line argument or set to "default" if not provided
namespace=${1:-default}

# Define the necessary variables and parameters
mysqlCharts=deployment/kubernetes-manifests/quickstart-k8s/charts/mysql
tsUser="ts"
tsPassword="Ts_123456"
tsDB="ts"
tsMysqlName="tsdb"

# Define function to continue deployment
function continue_deployment {
  echo "Start to deploy nacos."
  helm install $nacosRelease --set nacos.db.host=$nacosDBHost --set nacos.db.username=$nacosDBUser --set nacos.db.name=$nacosDBName --set nacos.db.password=$nacosDBPass $nacosCharts -n $namespace
  echo "Waiting for nacos to be ready ......"
  kubectl rollout status statefulset/$nacosRelease -n $namespace
  echo "Start to deploy rabbitmq."
  helm install $rabbitmqRelease $rabbitmqCharts -n $namespace
  echo "Waiting for rabbitmq to be ready ......"
  kubectl rollout status deployment/$rabbitmqRelease -n $namespace
  echo "Start deployment Step <2/3>: mysql cluster of train-ticket services----------------------"
  helm install $tsMysqlName --set mysql.mysqlUser=$tsUser --set mysql.mysqlPassword=$tsPassword --set mysql.mysqlDatabase=$tsDB $mysqlCharts -n $namespace 1>/dev/null
  echo "Waiting for mysql cluster of train-ticket to be ready ......"
  kubectl rollout status statefulset/${tsMysqlName}-mysql -n $namespace
  gen_secret_for_services $tsUser $tsPassword $tsDB "${tsMysqlName}-mysql-leader"
  echo "End deployment Step <2/3>-----------------------------------------------------------------"
}

# Call the function to continue deployment
continue_deployment $namespace

