#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Render Kubernetes manifests

for f in $(ls k8s/{common,dbjob,worker}/*.tpl); do
  eval "cat <<EOF
$(cat $f)
EOF" > ${f%.tpl}
done


# Get credentials

gcloud container clusters get-credentials myapp --region asia-northeast1


# Apply common manifests

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/common/config-map-myapp-env.yaml


# Run db:migrate as a Job

kubectl apply -f k8s/dbjob/service-account.yaml

job_namespace=$(kubectl apply -f k8s/dbjob/job-db-migrate.yaml --dry-run=client -o jsonpath="{.metadata.namespace}")
job_name=$(kubectl apply -f k8s/dbjob/job-db-migrate.yaml --dry-run=client -o jsonpath="{.metadata.name}")

if kubectl -n ${job_namespace} get job ${job_name} >/dev/null 2>&1; then
  echo "Job ${job_name} already exists"
fi

kubectl apply -f k8s/dbjob/job-db-migrate.yaml

for _ in {1..360}; do # wait 30 minutes
  if [[ "$(kubectl -n ${job_namespace} get job ${job_name} -o jsonpath='{.status.succeeded}')" = "1" ]]; then
    break
  elif [[ "$(kubectl -n ${job_namespace} get job ${job_name} -o jsonpath='{.status.failed}')" = "1" ]]; then
    echo "Job ${job_name} failed" >&2
    exit 1
  fi
  sleep 5
done

kubectl delete -f k8s/dbjob/job-db-migrate.yaml
