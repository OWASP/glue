#!/bin/bash
# Runs Snyk on the contents of the 'targets' dir,
# storing the output in 'report.json' within each target folder.
# Filters the output through grep to delete lines with personal info.
#
# Include a 'SKIP.txt' file next to 'package.json' if you don't want snyk to run on that target.

run_snyk_recurs ()
{
  if [ -f package.json ] && [ ! -f SKIP.txt ]; then
    # pwd
    snyk test --json | grep -v "\"org\"\|\"__filename\"" > report.json
  fi

  for SUBTARGET in *
  do
    if [ -d $SUBTARGET ] && [ $SUBTARGET != "node_modules" ]; then
      cd $SUBTARGET
      run_snyk_recurs
      cd ..
    fi
  done
}

DIR=`dirname $0`
cd "$DIR/targets/"
run_snyk_recurs
