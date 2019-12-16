# Some regular pod commands.
kubectl create -f ./integrations/k8s/glue-triage-command.yaml
kubectl logs glue-triage
kubectl delete pod glue-triage

# Scheduled run
kubectl create -f ./integrations/k8s/glue-triage-cron.yaml
kubectl delete cronjob glue-triage-cron
