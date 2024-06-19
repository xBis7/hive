#!/bin/bash

set -e

counter=0

while [[ "$counter" -le 10000000 ]]; do

  sleep 20

  counter=$(($counter + 1))
done

