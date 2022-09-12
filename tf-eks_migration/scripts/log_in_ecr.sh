#!/usr/bin/env bash



if aws --version &>/dev/null; then
    DOCKER_LOGIN="$(aws ecr get-login)"
    REPLADCE=""
      eval "${DOCKER_LOGIN/-e none/}"
else
    echo "AWS CLI is not installed..."
fi