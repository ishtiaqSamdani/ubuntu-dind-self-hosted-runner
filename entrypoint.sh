#!/bin/bash

# Start docker
start-docker.sh

su github -c "bash -c runner.sh"
