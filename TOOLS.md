# Setup and Tools Overview

Generally, if you are running Glue from a docker image, we have tried to
set up *most* of the relevant tools to be available so that you can just run
them.  It is also a self documenting way to set up the tools in Ubuntu, as the
Dockerfile in docker/glue/Dockerfile includes instructions for that platform.

For some people, such as those wanting to work with Glue straight from
source, it might be helpful to have instructions for setting up the tools
manually.  This document is intended to explain how to set up the tools
and provides a very brief overview of why the tools might be useful.

Note that you can always run the following to see a list of the tasks:
```
glue --checks
```

## Targets

In most of the examples provided for running Glue, we specify the CLI like:
```
glue operation target.  
```

The target can be:  
1.  A git repository eg:  https://github.com/jemurai/triage.git
2.  A local directory (/tmp/hello)
3.  A url (for live tools)
4.  A docker image
5.  An iso image

See the lib/glue/mounters for additional detail about targets.

## File Tools

### Clam AV

brew install clamav

ClamAV is an open source antivirus tool.  It may be desirable to run such
a tool against a file system or image or codebase to ensure that any well
publicized virus patterns would be noted if present.

```
glue -t clamav target
```

### Hashdeep (FIM)

TODO:  On Mac?
```
apt-get install md5deep
```

Hashdeep/md5deep is a file fingerprinting tool.  It calcluates an MD5 for each file
in a directory and alerts if files change.  This tool might be most useful
for looking at file system images that are not expected to change, or if so
to change in specific ways.

```
glue -t fim target
```

## Code Tools

### Brakeman
```
gem install brakeman
```

Brakeman is an excellent open source static analysis tool for Ruby on Rails
applications.  Any team building a rails application should find a way to
run brakeman regularly.

```
glue -t brakeman https://github.com/jemurai/triage.git
```

### Bundler Audit
```
gem install bundler-audit
```

Bundler audit is a Ruby dependency auditor.  It will read a Gemfile and
identify gem dependencies with known vulnerabilities.  It can be
redundant with brakeman but it works in non Rails environments, which
brakeman does not.

```
glue -t bundle-audit target
```

### Checkmarx

TODO:
checkmarx

Checkmarx is a commercial static analysis tool.  Note that additional options
will be required to effectively invoke Checkmarx since we are running it via
its API.

TODO:  Real world example.

### Dawn Scanner

TODO:

DawnScanner is a Ruby application scanner.  It works with Rails and Sinatra
applications.  It can be effective in certain cases where brakeman is not.

### ESLint

```
npm install -g eslint eslint-plugin-scanjs-rules eslint-plugin-no-unsafe-innerhtml
```

ESLInt is a Javascript syntax checker.  It can in some cases find interesting
potential issues.

```
glue -t eslint target
```

### Node Security Project (NSP)

```
npm install -g nsp
```

Node Security Project is a project for finding security issues in Node.js
projects.
```
glue -t nsp target
```

### Retire.js

```
npm install -g retirejs
```

Retire.js is a node library for checking dependencies for known vulnerabilities.

```
glue -t retirejs target
```

### scanjs

```
npm install -g scanjs
```

Scan JS is a script that runs javascript security checks.

```
glue -t scanjs target
```

### synk

```
npm install -g synk
```

Synk is a javascript dependency analysis tool.

```
glue -t scanjs target
```

### FindSecBugs

FindSecBugs is an extension of FindBugs which looks at compiled Java Bytecode
for specific issues.  It requires an intermediate compiled step and therefore
depends on having a general build process (maven).

```
glue -t findsecbugs target
```

### OWASP Dependency Check

```
curl -L http://dl.bintray.com/jeremy-long/owasp/dependency-check-1.4.3-release.zip --output owasp-dep-check.zip
unzip owasp-dep-check.zip
```

The OWASP Dependency Check project looks at a project's dependencies and checks them against the National
Vulnerability Database (NVD) and alerts us to issues in the libraries we are using.

```
glue -t owasp-dep-check target
```

### PMD

TODO:  Install?

PMD is a Java linter that can in some cases find security issues.

```
glue -t pmd target
```

### Sensitive File Lookup (SFL)

The sensitive file lookup is baked into Glue.  It is based on gitrob.  It looks
in a set of files for specific sensitive information like passwords or SSH keys.

```
glue -t sfl target
```

## Live Stage

### ZAP

Generally, we recommend running ZAP via its API.  It has a docker image that can
be run alongside the Glue docker image.

```
glue -t zap --zap-api-token <token> --zap-host <host>  --zap-port <port> https://site.com
```

## Maturity

In this section we will report the relative maturity of the tools and integrations.

The grades are common academic grades:  A is excellent, B is ok, C is meh, F is failing.

The areas we'll talk about include:  
1.  Integration - How well the tool is integrated into Glue right now.
2.  Tool Value - Our take on how valuable the tool is.
3.  Focus:  Any specifics areound where the tool focuses.

Grades (As of 9/30/2016):
1. brakeman - Integration: A, Tool Value: A, Focus:  Rails
2. bundleaudit - Integration: A, Tool Value:  A, Focus:  Ruby
3. checkmarx - Integration: C - Uses old API, only tested in one install, Tool Value: A, Focus:  Multi-language static.
4. clamav - Integration: B - Needs retest, Value: B, Focus: Open source Antivirus.
5. dawnscanner - Integration:  A, Tool:  B, Focus: Rails, Sinatra
6. eslint - Integration: F.
7. fim - Integration: C.
8. findsecbugs - Integration: C.
9. nsp - Integration C.
10. owasp-dep-check - Integration: B.
11. pmd - Integration: F.
12. retirejs - Integrations: F.
13. scanjs - Integrations:  F.
14. sfl - Integrations; A.  Tool:  B.  Focus:  Finding sensitive files / values.
15. sync - Integrations:  F.
16. zap - Integrations: B.  Tool: A.  Focus: Live scanning.
