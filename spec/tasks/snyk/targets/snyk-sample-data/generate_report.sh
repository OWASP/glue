#!/bin/bash
# Grabs a set of sample data from Snyk's github.

curl https://raw.githubusercontent.com/snyk/snyk-to-html/master/sample-data/test-report.json | grep -v "\"org\"\|\"__filename\"" > report.json
