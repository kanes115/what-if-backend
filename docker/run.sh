#!/bin/bash

SYSCONFIG="${RELEASE_PATH}/releases/*/sys.config"
WHAT_IF_HOSTNAME="${WHAT_IF_HOSTNAME:-$(hostname)}"
SECRET="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"

#setup nemo
sed -i -e "s/__WHAT_IF_PSQL_USER__/${WHAT_IF_PSQL_USER}/" ${SYSCONFIG}
sed -i -e "s/__WHAT_IF_PSQL_PASSWORD__/${WHAT_IF_PSQL_PASSWORD}/" ${SYSCONFIG}
sed -i -e "s/__WHAT_IF_PSQL_HOST__/${WHAT_IF_PSQL_HOST}/" ${SYSCONFIG}
sed -i -e "s/__SECRET__/${SECRET}/" ${SYSCONFIG}

#migrate db
SUCCESS=1
while [ ${SUCCESS} != 0 ]; do
    ${RELEASE_PATH}/bin/what_if command 'Elixir.WhatIf.Release.Task' migrate
    SUCCESS=$?
    sleep 2
done
${RELEASE_PATH}/bin/what_if foreground

