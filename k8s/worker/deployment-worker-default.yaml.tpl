apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: myapp
  name: myapp-worker-default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp-worker-default
  template:
    metadata:
      labels:
        app: myapp-worker-default
    spec:
      serviceAccountName: myapp-worker-default
      securityContext:
        fsGroup: 61000
        runAsGroup: 61000
        runAsUser: 61000
      terminationGracePeriodSeconds: 60 # Fit timeout of worker
      containers:
      - name: worker
        image: "${IMAGE}:${COMMIT_SHA}"
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
        command: ["bin/worker", "default"]
        resources:
          requests:
            memory: 512Mi
            cpu: 1000m
          limits:
            memory: 512Mi
            cpu: 1000m
        envFrom:
        - configMapRef:
            name: myapp-env
