#!/bin/bash

# Reinstall daemon
COSMOS_BUILD_OPTIONS=nostrip make install

./setup.sh

chmod -R 766 $HOME/.evmosd