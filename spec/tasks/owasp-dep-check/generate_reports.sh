#!/bin/bash
# Runs dependency-check.sh on the contents of the 'targets' dir,
# storing the output in 'dependency-check-report.xml' within each target root folder.
# Include a 'SKIP.txt' in the root folder if you don't want dependency-check to run on that target.

set -e

DEP_CHECK_PATH=~/dependency-check/bin/dependency-check.sh

function usage () {
    local name=$(basename "$0")

    echo >&2 "Usage: ${name} [-p PATH_TO_DEP_CHECK]"
    echo >&2 "Options:"
    echo >&2 "  -p      Path to dependency-check.sh executable"
    exit 1
}

run_dependency_check () {
  FILES=$(find -type f -name "*.jar")
  if [ ! -z ${FILES} ] && [ ! -f "SKIP.txt" ]; then
    ${DEP_CHECK_PATH} --project Glue -s . -f XML
  fi
}


while getopts ":p:h" opt; do
    case $opt in
        p)
            DEP_CHECK_PATH=${OPTARG}
            ;;
        h)
            usage
            ;;
        \?)
            echo >&2 "Invalid option: -${OPTARG}"
            usage
            ;;
    esac
done

echo >&2 "Using dependency-check path: ${DEP_CHECK_PATH}"

DIR=`dirname $0`
cd "${DIR}/targets/"

# dependency-check.sh will generate a report in each root directory
# for all dependencies found in its sub directories
for SUBTARGET in *
do
    if [ -d ${SUBTARGET} ]; then
        cd ${SUBTARGET}
        run_dependency_check
        cd ..
    fi
done
