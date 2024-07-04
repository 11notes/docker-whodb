#!/bin/ash
  if [ -z "${1}" ]; then
    cd /usr/local/bin
    set -- "whodb"
  fi

  exec "$@"