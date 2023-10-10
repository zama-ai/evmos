#!/bin/bash

cp .env.example .env
TEST_CONTAINER_NAME=evmosnodelocal0 npm run test:inband
