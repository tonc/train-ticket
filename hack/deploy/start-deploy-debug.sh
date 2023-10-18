#!/bin/bash

# Define the root directory
TT_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Define the necessary variables and parameters
mysqlCharts=deployment/kubernetes-manifests/quickstart-k8s/charts/mysql
nacosDBRelease="nacosdb"
nacosDBUser="nacos"
nacosDBPass="Abcd1234#"
nacosDBName="nacos"

# Get the namespace from command line argument or set to "default" if not provided
namespace=${1:-default}

# Define the deploy_infrastructures function
function deploy_infrastructures {
  echo "Start deployment Step <1/3>------------------------------------"
  echo "Start to deploy mysql cluster for nacos."
  helm install $nacosDBRelease --set mysql.mysqlUser=$nacosDBUser --set mysql.mysqlPassword=$nacosDBPass --set mysql.mysqlDatabase=$nacosDBName $mysqlCharts -n $namespace
  echo "Waiting for mysql cluster of nacos to be ready ......"
  kubectl rollout status statefulset/$nacosDBRelease-mysql -n $namespace
  echo "Finish nacos DB rollout.."
}

# Call the deploy_infrastructures function
deploy_infrastructures $namespace

