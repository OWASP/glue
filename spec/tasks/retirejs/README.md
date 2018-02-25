## RetireJS spec tests

### Overview of RetireJS

[Retire](https://github.com/retirejs/retire.js/)
scans a project's Node.js package dependencies
(similar to [Snyk](https://snyk.io/))
and also scans the content of files looking for dependencies
on JS libraries.

The names/versions are compared against
[repositories](https://github.com/RetireJS/retire.js/tree/master/repository)
of known npm and JS library vulnerabilities.

To install RetireJS:
```
npm install -g retire
```

The simplest way to run it from the command line
is to `cd` to the root folder of your project and call:
```
retire
```

In Glue, `retire` is called with the following arguments:
```
retire -c --outputpath /dev/stdout --outputformat json --path <TARGET>
```
(By default, `retire` outputs to `STDERR`. Glue expects results to be
output to `STDOUT`, hence the need for the `--outputpath /dev/stdout`.)

### The spec tests

The specs do not call the RetireJS API because this would be too
slow (about 1 sec per spec test). Instead the specs rely on stubbing
Glue's `runsystem` method (which calls CLI commands).

In the specs, the return value of `runsystem` is always a canned response.
Either it will be a generic, minimal response, or it will be a snapshot of an
actual RetireJS report (generated using
[this commit](https://github.com/RetireJS/retire.js/commit/75d728139eda79aa825d1fe17ad2af6d48120146)
of RetireJS.)

The actual reports were generated via the script 'generate_reports.sh'.
The targets of the spec tests were set up in a minimal way to produce
non-trivial output.
