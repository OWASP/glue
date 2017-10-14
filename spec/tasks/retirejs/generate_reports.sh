#!/bin/bash
# Runs 'retire' on the contents of the 'test_targets' dir,
# storing the output in 'report.json' within each target folder.
#
# After running it, transfer the results to the 'targets' dir.
#
# Include a 'SKIP.txt' file next to 'package.json'
# if you don't want retire to run on that target.
#
# This uses sed to find-replace the absolute file paths
# with truncated relative versions.
# (Some vulnerabilities report an abs file path.
# Glue attempts to parse this to a relative path, using 'relative_path'.
# But this will not work correctly for the canned reports of
# the spec tests, since the abs file path in the canned report
# won't necessarily match the abs file path on the user's machine.
# To get around this for the spec tests, we just convert the
# reported abs file paths to relative file paths.)
#
# Note with sed: on Mac (but not on Linux) the -i (inplace editing)
# will always create a backup, with extension equal to the first arg
# after -i.

run_retire_recurs ()
{
  if [ -f package.json ] && [ ! -f SKIP.txt ]; then
    # pwd
    retire -c --outputformat json --outputpath report.json
    sed -i.bak -e "s;$ABS_DIR/;;g" report.json
    rm report.json.bak
  fi

  for SUBTARGET in *
  do
    if [ -d $SUBTARGET ] && [ $SUBTARGET != "node_modules" ]; then
      cd $SUBTARGET
      run_retire_recurs
      cd ..
    fi
  done
}

DIR=`dirname $0`
# cd "$DIR/targets/"
cd "$DIR/test_targets/"
ABS_DIR="$(pwd)"

run_retire_recurs
