apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: myapp
  name: myapp-dbjob
  annotations:
    iam.gke.io/gcp-service-account: myapp-dbjob@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
