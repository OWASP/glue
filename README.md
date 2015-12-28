![Pipeline Logo](https://upload.wikimedia.org/wikipedia/commons/3/37/The_Great_Wave_of_Kanagava.jpg)

# Pipeline

Pipeline is a framework for running a series of tools.  Generally, it is intended as a backbone 
for automating a security analysis pipeline of tools.

# Recommended Usage

For those wishing to run pipeline, we recommend using the docker image.
See the documentation for more info.  [Pipeline Docker Documentation](./DOCKER.md)

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

# Configuration files

For advanced usage scenarios, you can save your configuration and use it at runtime.

# License

Apache 2:  http://www.apache.org/licenses/LICENSE-2.0