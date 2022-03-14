#!/bin/bash

date="201[7-9]"
clickhouse-client -q "SELECT partition,name,modification_time,database,table FROM system.parts WHERE database != 'system' AND match(partition, '$date');" | while read line; do
  query=$(awk '{if ($1!~",") {$1="\047" $1 "\047"} print "ALTER TABLE " $5 "." $6 " DETACH PARTITION " $1}' <<< $line)
  clickhouse-client -q "$query"
done
