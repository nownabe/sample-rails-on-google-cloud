apiVersion: v1
kind: ConfigMap
metadata:
  namespace: myapp
  name: myapp-env
data:
  GOOGLE_CLOUD_PROJECT: "${GOOGLE_CLOUD_PROJECT}"
  SPANNER_INSTANCE: "${SPANNER_INSTANCE}"
  SPANNER_DATABASE: "${SPANNER_DATABASE}"
  MASTER_KEY_SECRET_ID: "${MASTER_KEY_SECRET_ID}"
