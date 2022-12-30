#!/bin/bash

#
# Publishes a new package.
# Provide path to the package as first argument.
#

env=$(cat .env)
if [ -n "${env}" ]; then
    export $(echo "${env}" | xargs)
fi

budget="1000000"
if [ -z "${GAS}" ]; then
    sui client publish --gas-budget "${budget}" "${1}"
else
    sui client publish \
        --gas "${GAS}" \
        --gas-budget "${budget}" "${1}"
fi
