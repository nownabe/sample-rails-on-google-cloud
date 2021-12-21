apiVersion: batch/v1
kind: Job
metadata:
  namespace: myapp
  name: db-migrate
spec:
  backoffLimit: 0
  template:
    metadata:
      name: db-migrate
    spec:
      serviceAccountName: myapp-dbjob
      restartPolicy: Never
      securityContext:
        fsGroup: 61000
        runAsGroup: 61000
        runAsUser: 61000
      containers:
        - name: db-migrate
          image: "${IMAGE}:${COMMIT_SHA}"
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
          command: ["bundle", "exec", "rake", "db:migrate"]
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
