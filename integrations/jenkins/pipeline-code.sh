# Use existing managed scripts to add this to your Jenkins build
# Obviously depends on having docker-machine and docker set up.

echo "Starting Pipeline Tool"
echo "Script executed from: ${PWD}"

eval $(docker-machine env patched)
GUID="$RANDOM"
docker run -v ${PWD}:/tmp/$GUID/ jemurai/pipeline:0.8 -z -L code -d /tmp/$GUID/
