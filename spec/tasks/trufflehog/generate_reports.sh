#!/bin/bash
# Runs Trufflehog on the contents of the 'targets' dir and stores the output in 'results'.
DIR=`dirname $0`
TRUFFLEHOG="/home/glue/tools/truffleHog/truffleHog/truffleHog.py"

for TARGET_PATH in "$DIR/targets/"*
do
  TARGET=`basename $TARGET_PATH`
  # echo $TARGET
  # echo a > "$DIR/reports/$TARGET.json"
  python $TRUFFLEHOG --json $TARGET_PATH > "$DIR/reports/$TARGET.json"
done
