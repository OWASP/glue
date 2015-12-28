# Pipeline with Docker

Pipeline is distributed in a Docker image for each of use.
This has the advantage of coming with tools already 
configured and ready to go.

# Installation

docker pull jemurai/pipeline:0.6

# Usage

## Help
docker run jemurai/pipeline:0.6 --help

## Typical Usage
docker run jemurai/pipeline:0.6 

docker run jemurai/pipeline:0.6 https://github.com/YourOrg/YourProject.git

docker run jemurai/pipeline:0.6 -l code -f json https://github.com/YourOrg/YourProject.git

Example: 
docker run jemurai/pipeline:0.6 -l code -f json https://github.com/Jemurai/triage.git


# Dependencies

* Docker:  https://get.docker.com/
** Mac: https://docs.docker.com/mac/step_one/
** Linux: https://docs.docker.com/linux/step_one/
** Windows:  https://docs.docker.com/windows/step_one/

# Development

To run the code from the docker image, run the following: 

docker run -i -t --entrypoint=/bin/bash jemurai/pipeline:0.6

Then, you can run the tool as though you were developing it.

cd ~/line/pipeline and you will be in the root of the project.

# Configuration files

For advanced usage scenarios, you can save your configuration 
and use it at runtime.

# License

Apache 2:  http://www.apache.org/licenses/LICENSE-2.0