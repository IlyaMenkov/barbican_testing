#!/usr/bin/env bash

resource_name="test_barbican"

mkdir log

datetime="$(date +"%Y_%m_%d_%I:%M%p")"
# Run prepare environment script
bash prepare_environment.sh $resource_name >> "log/prepare_environment_$datetime.log"

# Run all tests from tests/ dirrectory
for test in tests/*; do $test $resource_name >> "log/tests_run_$datetime.log"; done

bash cleanup.sh $resource_name >> "log/cleanup_$datetime.log"