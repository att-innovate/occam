#!/bin/bash

if [ -z "$1" ]; then
  echo "No argument supplied"
  exit 1
elif [ "$1" == "-d" ]; then
  OPER='discovery'
elif [ "$1" == "-vq" ]; then
  OPER='value'
  CMD='list_queues'
elif [ "$1" == "-v" ]; then
  OPER='value'
  VTYPE=$2
  VVHOST=$3
  VNAME=$4
  VITEM=$5
fi

if [ "$OPER" == "discovery" ]; then

  POSITION=1
  echo "{"
  echo " \"data\":["

  for VHOST in `sudo rabbitmqctl -q list_vhosts`; do
    for QUEUE in `sudo rabbitmqctl -q -p $VHOST list_queues name`; do
      if [ $POSITION -gt 1 ]
      then
        echo ","
      fi
      echo -n " { \"{#TYPE}\": \"QUEUE\", \"{#NAME}\": \"$QUEUE\", \"{#VHOST}\": \"$VHOST\"}"
      POSITION=$[POSITION+1]
    done
  done

  echo ""
  echo " ]"
  echo "}"
elif [ "$OPER" == "value" ]; then
  if [ "$VTYPE" == "queue" ]; then
    RET=`sudo rabbitmqctl -q -p $VVHOST list_queues name $VITEM | grep "^${VNAME}\s" | awk {'print $2'}`
    echo $RET
  fi
fi

