## Scanning Options

There are several ways to control which tools you want to run when one
invokes Glue.  The first is "Stages".  Stages in glue just group certain tasks
that are related.  They are:

1.  File - File system (av, fim)
2.  Code - Source code (brakeman)
3.  Live - To run against a live system (ZAP)

When invoking glue, we can control what runs by specifying stages (labels)
or by specifying specific tasks.

Note that it can make sense to run File and Code stages against the same
target.  It does not really make sense to run against a Code and Live
stage in one invocation.  For that use case, it is recommended that those
be separated into two invocations, one with the git repo url for Code
and one with the staging url, for Live example.

### Stages / Labels

To run all of the file tasks, run:  
```
glue -l file
```
To run all of the code level tasks, run:
```
glue -l code
```
To run all the live tasks, run:
```
glue -l live
```

Note that there are also labels for certain programming languages.  So one
could run this to run javascript tools:
```
glue -l code,javascript
```
See the tasks in source code for current labels.

### Tasks

The easiest way to run a single tool is to specify the task option:
```
glue -t brakeman
```

The supported tasks, listed here by stage for convenience:

File Stage

1.  clamav
2.  fim (hashdeep)

Code Stage

1.  brakeman
2.  bundle-audit
3.  checkmarx
4.  dawnscanner
5.  eslint
6.  findsecbugs
7.  nsp (node security project)
8.  OWASPDependencyCheck
9.  pmd
10. retirejs
11. scanjs
12. sfl (sensitive file lookup)
13. synk

Live Stage

1. zap


### Excluding Tasks

It is also possible to exclude specific tasks.  This might be useful if you
want to run all of the code tasks except brakeman.  You could do that by
specifying:

```
glue -l code -x brakeman
```

## Output Options

We specify output using -f.

The alternatives are:

1.  csv
2.  text (default)
3.  json
4.  jira (must specify JIRA options)

Generally, it is advised to run Glue with the options you want to try
and get the output in text or one of the other local formats (json, csv)
prior to pushing to JIRA.

## Configuration Files

In order to facilitate running with complicated sets of options and to
allow for easy separation of credentials from command line invocations,
Glue supports reading certain options from configuration files.  The
following files will be read and options specified merged into any
CLI supplied options.

Configuration files can be located in:

1.  ./config/glue.yml
2.  ~/.glue/config.yml
3.  /etc/glue/config.yml

It is recommended that items such as JIRA connect configuration be
put into configuration files.

To get the config file content you want, you can run the following to get them
in the format YAML that the stored files should be in:
```
glue <complicated-options> --create-config
```
