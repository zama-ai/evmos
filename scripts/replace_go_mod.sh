#!/bin/bash

FILE=$1
REPO_NAME=$2

#grep -n "zama.ai/$REPO_NAME" "$FILE" | cut -d: -f1 | xargs -I{} sed -i "{}s/=>.*/=> .\/work_dir\/$REPO_NAME/" "$FILE"
grep -n "zama.ai/$REPO_NAME" "$FILE" | cut -d: -f1 | xargs -I{} sed -i -e "{}s/=>.*/=> .\/work_dir\/$REPO_NAME/" "$FILE"
