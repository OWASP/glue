![Pipeline Logo](https://upload.wikimedia.org/wikipedia/commons/3/37/The_Great_Wave_of_Kanagava.jpg)

# Pipeline

Pipeline is a framework for running a series of tools.  Generally, it is intended as a backbone 
for automating a security analysis pipeline of tools.

# Recommended Usage

For those wishing to run pipeline, we recommend using the docker image.
See the documentation for more info.  [Pipeline Docker Documentation](./DOCKER.md)

For those interested in how to use Pipeline in a DevOps context, see
[Pipeline DevOps Integration Options](./DEVOPS.md)

# Installation

gem install pipeline

# Extending Pipeline

Pipeline is intended to be extended through added "tasks".  To add a new tool, 
copy an existing task and tweak to make it work for the tool in question.

# Usage

pipeline <options> <target>

## Options

Common options include: 
-d for debug
-f for format (takes "json", "csv", "jira")

For a full list of options, use `pipeline --help` or see the [OPTIONS.md](./OPTIONS.md) file.

## Target

The target can be: 
* Filesystem (which is analyzed in place)
* Git repo (which is cloned for analysis)
* Other types of images (.iso, docker, etc. are experimental)


# Dependencies

* clamav
* hashdeep
* rm (*nix)
* git
* mount (*nix)
* docker

# Development

To run the code, run the following from the root directory: 
>ruby bin/pipeline <options> target

To build a gem, just run: 
gem build pipeline.gemspec


# Integration

## Git Hooks

First, grab the hook from the code.
```
meditation:hooks mk$ cp /area53/owasp/pipeline/hooks/pre-commit .
```

Then make it executable.
```
meditation:hooks mk$ chmod +x pre-commit
```

Make sure the shell you are committing in can see docker.
```
meditation:hooks mk$ eval "$(docker-machine env default)"
```

Now go test and make a change and commit a file.
The result should be that pipeline runs against your 
code and will not allow commits unless the results 
are clean. (Which is not necessarily a reasonable 
expectation)


# Configuration files

For advanced usage scenarios, you can save your configuration and use it at runtime.

# Authors

Matt Konda
Alex Lock
Rafa Perez

# License

Apache 2:  http://www.apache.org/licenses/LICENSE-2.0