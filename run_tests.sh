#!/usr/bin/env bash

resource_name='test_barbican'

# Run prepare environment script
bash prepare_environment.sh $resource_name

# Run all tests from tests/ dirrectory
for test in tests/*; do $test $resource_name; done

bash clean_up.sh $resource_name