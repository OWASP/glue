# Use existing managed scripts to add this to your Jenkins build
# Obviously depends on having docker-machine and docker set up.

echo "Starting Glue"
echo "Script executed from: ${PWD}"

eval $(docker-machine env patched)
GUID="$RANDOM"
docker run --rm=true --name=glue_ci_active owasp/glue:0.9.0 -z -t zap -d https://staging.jemurai.com/
