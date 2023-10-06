#!/bin/bash

cp .env.example .env
LOCAL_IMAGE_NAME=evmosnodelocal0 npm run test:inband
