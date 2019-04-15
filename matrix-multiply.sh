#!/bin/bash

count=${1:-1}

for i in $(seq 1 $count)
  do
    snowsql -c pm_matrix -o friendly=False -o timing=True -o execution_only=True -f matrix-product.sql &
  done
wait
