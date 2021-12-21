apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: myapp
  name: myapp-worker-default
  annotations:
    iam.gke.io/gcp-service-account: myapp-worker-default@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
