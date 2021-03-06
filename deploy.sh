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
  exit 1
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


# Deploy Rails web server to Cloud Run

gcloud run deploy myapp \
  --args bin/rails,server,-b,0.0.0.0 \
  --cpu 1000m \
  --memory 512Mi \
  --service-account myapp-main@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com \
  --set-env-vars GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT} \
  --set-env-vars SPANNER_INSTANCE=${SPANNER_INSTANCE} \
  --set-env-vars SPANNER_DATABASE=${SPANNER_DATABASE} \
  --set-env-vars MASTER_KEY_SECRET_ID=${MASTER_KEY_SECRET_ID} \
  --image ${IMAGE}:${COMMIT_SHA} \
  --allow-unauthenticated \
  --region asia-northeast1


# Deploy worker as a Deployment

kubectl apply -f k8s/worker/service-account-worker-default.yaml
kubectl apply -f k8s/worker/deployment-worker-default.yaml
