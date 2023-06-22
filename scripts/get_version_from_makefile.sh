#!/bin/bash

variable_name=$1
value=$(grep "$variable_name ?=" Makefile | cut -d '=' -f 2- | tr -d '[:space:]')
echo $value