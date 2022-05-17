#!/bin/bash

DBNAME=block_bench_results_tpch

# get parent directory
ROOTDIR=`realpath $0`
ROOTDIR=`dirname $ROOTDIR`
ROOTDIR=`dirname $ROOTDIR`

echo "top directory: $ROOTDIR"

# remove stale generated files (if any)
rm -f *.tmp

for m in i5 xeon; do

	for r in `ls $ROOTDIR/$m/`; do

		d=`echo $r | sed 's/results-//'`

		sed "s/^/$d;$m;/g" $ROOTDIR/$m/$r/queries.csv | sed 's/.sql//g' | grep -v '-' >> queries.tmp


		while read line; do

			IFS=";" read -a strarr <<< "$line"

			dbs="${strarr[0]}"
			wbs="${strarr[1]}"
			dss="${strarr[2]}"
			wss="${strarr[3]}"
			step="${strarr[4]}"
			start="${strarr[5]}"
			time="${strarr[6]}"
			wal="${strarr[7]}"

			echo "$d;$m;$dbs;$wbs;$dss;$wss;$step;$start;$time;$wal" >> load.tmp

		done < $ROOTDIR/$m/$r/load.csv

	done

done


dropdb --if-exists $DBNAME
createdb $DBNAME

psql $DBNAME < stats.sql

cat queries.tmp | psql $DBNAME -c "copy queries (run, machine, data_block, wal_block, data_segment, wal_segment, query_id, query_run, query_start, query_time, plan_hash, result_hash) from stdin with (format csv, delimiter ';')"

cat load.tmp | psql $DBNAME -c "copy data_load (run, machine, data_block, wal_block, data_segment, wal_segment, step_name, step_start, step_time, step_wal) from stdin with (format csv, delimiter ';')"

psql $DBNAME -c "vacuum analyze"

rm *.tmp
