apiVersion: v1
kind: Pod
metadata:
  namespace: myapp
  name: myapp-console-${USER}
spec:
  serviceAccountName: myapp-dbjob
  restartPolicy: Never
  securityContext:
    fsGroup: 61000
    runAsGroup: 61000
    runAsUser: 61000
  containers:
    - name: console
      image: "${IMAGE}@${DIGEST}"
      securityContext:
        allowPrivilegeEscalation: false
        privileged: false
      command: ["sleep", "infinity"]
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
