# Use existing managed scripts to add this to your Jenkins build
# Obviously depends on having docker-machine and docker set up.

echo "Starting Pipeline Tool"
echo "Script executed from: ${PWD}"

eval $(docker-machine env patched)
GUID="$RANDOM"
docker run --rm=true --name=pipeline_ci_active owasp/pipeline:0.8 -z -t zap -d https://staging.jemurai.com/
