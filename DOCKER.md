# Glue with Docker

Glue is distributed in a Docker image for each of use.
This has the advantage of coming with tools already
configured and ready to go.

# Installation

```
docker pull owasp/glue
```

# Usage

## Help

This is one way to get help.
```
docker run --rm owasp/glue --help
```

## Typical Usage

Most basic starting point.  Will analyze a predetermined codebase.
```
docker run --rm --name=Glue owasp/glue
```

Here is an example that runs on a github repo.
```
docker run --rm --name=Glue owasp/glue https://github.com/YourOrg/YourProject.git
```

This example only runs code analysis tools and outputs JSON.
```
docker run --rm --name=Glue owasp/glue -l code -f json https://github.com/YourOrg/YourProject.git
```

Example:
```
docker run --rm --name=Glue owasp/glue -l code -f json https://github.com/Owasp/triage.git
```

## On the File System

Running against a local file system:
```
docker run --rm --name=Glue -v /code/location:/tmp/directory owasp/glue -d -f json /tmp/directory/
```

Example:
```
docker run --rm --name=Glue -v /Users/mk/line/tmp/triage:/tmp/triage owasp/glue -l code -f json /tmp/triage/
```

Note that the folder sharing on Windows and Mac is constrained by [Docker Volumes](https://docs.docker.com/engine/userguide/dockervolumes/).
To summarize those for Mac, it is easy to share directories in the Users home directory but if you want to share
a different directory you have to make it shared through VirtualBox or whatever container controls your base image.

## Running Specific Tools

Glue supports running specific tools using the -t flag.  For example the following command only runs retire.js on the project.
```
docker run --rm --name=Glue -v /Users/mk/line/tmp/NodeGoat:/tmp/nodegoat owasp/glue:0.7 -t retirejs -f csv /tmp/nodegoat/
```

The tools include:
- brakeman
- bundler-audit
- retirejs
- nodesecurityproject
- eslint
- sfl (Sensitive file lookup - part of Glue)


# Dependencies

- Docker:  https://get.docker.com/
  - Mac: https://docs.docker.com/mac/step_one/
  - Linux: https://docs.docker.com/linux/step_one/
  - Windows:  https://docs.docker.com/windows/step_one/

# Development

To run the code from the docker image by hand or debug issues there, run the following:

```
docker run --name=Glue --rm -i -t --entrypoint=bash owasp/glue
```

Then, you will be in the root of the project. You can run the tool as though you were developing it.

# Configuration files

For advanced usage scenarios, you can save your configuration
and use it at runtime.

# License

[Apache 2](http://www.apache.org/licenses/LICENSE-2.0)
