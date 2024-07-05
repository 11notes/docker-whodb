#!/bin/ash
  if [ -z "${1}" ]; then
    set -- "whodb"
  fi

  exec "$@"