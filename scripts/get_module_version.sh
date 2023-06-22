#!/bin/bash

FILE=$1
PATTERN=$2

LINE=$(grep ${PATTERN} ${FILE})
LAST_VALUE=$(echo ${LINE} | sed -n 's/.* \([^ ]*\)$/\1/p')

echo ${LAST_VALUE}