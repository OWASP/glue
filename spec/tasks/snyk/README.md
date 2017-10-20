## Snyk spec tests

### Overview of Snyk

[Snyk](https://snyk.io/) scans a project's Node.js package dependencies,
comparing package version numbers against
[Snyk's database of known vulnerabilities](https://snyk.io/vuln).

Snyk requires sign-up and an authentication token before it can be run.
See their website for details. It can be run on open source projects for
free, up to a set number of times per billing cycle.

Once installed, to run Snyk locally from within a project's root folder, run:
```
snyk test
```

Snyk can also scan Ruby, Java, Scala, and Python dependencies.
By default, if Snyk does not find a 'yarn.lock' or a 'package.json' file,
then it will look for a 'Gemfile'. If none is found, it will look for a
'pom.xml'. And so on for the different languages. When it finds a
package-management file that it recognizes, it stops searching further.

In Glue, Snyk is only called on directories that have a 'package.json' file.
Therefore Glue will only return Snyk results for Node.js package vulnerabilities.

To replicate this behavior when calling Snyk directly from the command line from
within a given project:
```
snyk test --file=package.json
```

Some other command line options when running Snyk locally:
* `--json` - Outputs in json, with more detailed information than the default output.
* `--dev` - Include dev dependencies. By default (and in Glue) dev dependencies are excluded.

See [Snyk's CLI documentation](https://snyk.io/docs/using-snyk) for more info.

### The spec tests

The specs do not call the actual Snyk API, for two reasons. First, because it would be too slow.
Second (and more importantly), because we would quickly breach the limit for the
number of times we can run Snyk for free per billing cycle.

Instead, the specs rely on stubbing Glue's 'runsystem' method (which is responsible
for calling CLI commands).

In the specs, the return value of 'runsystem' is always a canned response.
Either it will be a generic, minimal response, or it will be a snapshot of an
actual Snyk report.

The actual reports were generated via the script 'generate_reports.sh'.
The targets of the spec tests were set up in a minimal way to produce non-trivial output.
This required a 'package.json' file, a 'node_modules' folder with the package sub-folders,
and a 'package.json' file within the package sub-folders. The 'package.json' files only needed
the "dependencies" list. All extraneous information from the 'package.json' files was
deleted, and the code for the packages themselves was not included.
