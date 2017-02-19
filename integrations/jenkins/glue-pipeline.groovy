node {
    stage("Checkout"){
        git url: "https://github.com/Jemurai/triage.git"
    }
    stage("Glue-Static"){
        sh '''echo "Starting Glue"
echo "Script executed from: ${PWD}"

eval $(docker-machine env default)
GUID="$RANDOM"
docker run --rm=true --name=glue_ci_code -v ${PWD}:/tmp/$GUID/ owasp/glue -z -t brakeman,sfl -d /tmp/$GUID/'''
    }
    stage("Deploy"){
        echo "TODO:  DEPLOY"
    }
    stage("Glue-Dynamic"){
        echo "TODO: ZAP"
    }
}
