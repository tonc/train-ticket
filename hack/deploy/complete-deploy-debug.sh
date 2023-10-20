#!/bin/bash

# Define the root directory
TT_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Source necessary scripts
source "$TT_ROOT/utils.sh"
source "$TT_ROOT/gen-mysql-secret.sh"  # Include this line to source gen-mysql-secret.sh

# Get the namespace from command line argument or set to "default" if not provided
namespace=${1:-default}

# Define function to complete deployment
function complete_deployment {
  echo "Start deployment Step <3/3>: train-ticket services--------------------------------------------"
  echo "Start to deploy secret of train-ticket services."
  kubectl apply -f deployment/kubernetes-manifests/quickstart-k8s/yamls/secret.yaml -n $namespace > /dev/null

  echo "Deploying service configurations..."
  kubectl apply -f deployment/kubernetes-manifests/quickstart-k8s/yamls/svc.yaml -n $namespace > /dev/null

  echo "sw_dp_sample_yaml: $sw_dp_sample_yaml"
  echo "sw_dp_yaml: $sw_dp_yaml"


  # echo "Deploying train-ticket deployments..."
  # update_tt_dp_cm $nacosRelease $rabbitmqRelease
  # kubectl apply -f deployment/kubernetes-manifests/quickstart-k8s/yamls/deploy.yaml -n $namespace > /dev/null

  echo "Deploying train-ticket deployments with skywalking agent..."
  update_tt_sw_dp_cm $nacosRelease $rabbitmqRelease
  kubectl apply -f deployment/kubernetes-manifests/quickstart-k8s/yamls/sw_deploy.yaml -n $namespace > /dev/null

  echo "Start deploy skywalking"
  kubectl apply -f deployment/kubernetes-manifests/skywalking -n $namespace

  echo "Start deploy prometheus and grafana"
  kubectl apply -f deployment/kubernetes-manifests/prometheus
  
  echo "End deployment Step <3/3>----------------------------------------------------------------------"
}

# Call the function to complete deployment
complete_deployment $namespace

