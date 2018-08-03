#!/bin/bash
# Runs bundle-audit on the contents of the 'targets' dir,
# storing the output in 'report.txt' within each target folder.
# Include a 'SKIP.txt' file next to 'package.json' if you don't want snyk to run on that target.

set -e

run_bundleaudit_recurs ()
{
  if [ -f "Gemfile.lock" ] && [ ! -f "SKIP.txt" ]; then
      bundle-audit check > report.txt
  fi

  for SUBTARGET in *
  do
    if [ -d ${SUBTARGET} ]; then
      cd ${SUBTARGET}
      run_bundleaudit_recurs
      cd ..
    fi
  done
}

DIR=`dirname $0`
cd "${DIR}/targets/"
run_bundleaudit_recurs
