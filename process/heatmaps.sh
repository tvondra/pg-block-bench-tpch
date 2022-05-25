#!/usr/bin/bash

DBNAME=block_bench_results_tpch

# get parent directory
ROOTDIR=`realpath $0`
ROOTDIR=`dirname $ROOTDIR`
ROOTDIR=`dirname $ROOTDIR`

echo "top directory: $ROOTDIR"

echo "generating heatmaps"

# remove stale generated files (if any)
rm -Rf heatmaps
mkdir heatmaps

#
psql $DBNAME -c "create extension tablefunc"

for m in i5 xeon; do

	if [ "$m" == "i5" ]; then
		SIZE="10GB"
		RAM="8GB"
	else
		SIZE='75GB';
		RAM='32GB';
	fi

	for r in `ls $ROOTDIR/$m/`; do

		d=`echo $r | sed 's/results-//'`

		mkdir -p heatmaps/$m/$d/queries
		mkdir -p heatmaps/$m/$d/loads

		for wss in `psql -t -A $DBNAME -c "select distinct wal_segment FROM queries WHERE run = '$d' AND machine = '$m'"`; do

			cp heatmap.template heatmap.plot

			data=queries-$wss

			psql -t -A -F ' ' $DBNAME > $data-min.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  query_time_min::int::text as value
 FROM query_results_agg
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM query_results_agg ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

			psql -t -A -F ' ' $DBNAME > $data-max.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  query_time_max::int::text as value
 FROM query_results_agg
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM query_results_agg ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

			psql -t -A -F ' ' $DBNAME > $data-avg.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  query_time_avg::int::text as value
 FROM query_results_agg
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM query_results_agg ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

			sed "s/DATAFILE/$data-min/g" heatmap.template | sed "s/TITLE/machine: $m  duration: min  size: $SIZE  RAM: $RAM/" > $data-min.plot
			sed "s/DATAFILE/$data-max/g" heatmap.template | sed "s/TITLE/machine: $m  duration: max  size: $SIZE  RAM: $RAM/" > $data-max.plot
			sed "s/DATAFILE/$data-avg/g" heatmap.template | sed "s/TITLE/machine: $m  duration: avg  size: $SIZE  RAM: $RAM/" > $data-avg.plot

			gnuplot $data-min.plot
			gnuplot $data-max.plot
			gnuplot $data-avg.plot

			for f in *.eps; do
				convert -background white -alpha remove -alpha off -density 200 $f ${f/eps/png}
			done

			mv *.plot *.eps *.png *.data heatmaps/$m/$d/queries

			for q in `seq 1 22`; do

				data=query-$q-$wss

				psql -t -A -F ' ' $DBNAME > $data-min.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  query_time_min::int::text as value
 FROM query_results
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss AND query_id = ''$q''
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM query_results_agg ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

				psql -t -A -F ' ' $DBNAME > $data-max.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  query_time_max::int::text as value
 FROM query_results
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss AND query_id = ''$q''
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM query_results_agg ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

				psql -t -A -F ' ' $DBNAME > $data-avg.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  query_time_avg::int::text as value
 FROM query_results
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss AND query_id = ''$q''
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM query_results_agg ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

				psql -t -A -F ' ' $DBNAME > $data-plan.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  dense_rank::text as value
 FROM query_plans
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss AND query_id = ''$q''
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM query_results_agg ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

				sed "s/DATAFILE/$data-min/g" heatmap.template | sed "s/TITLE/query: $q  machine: $m  run: $d  (min duration)/" > $data-min.plot
				sed "s/DATAFILE/$data-max/g" heatmap.template | sed "s/TITLE/query: $q  machine: $m  run: $d  (max duration)/" > $data-max.plot
				sed "s/DATAFILE/$data-avg/g" heatmap.template | sed "s/TITLE/query: $q  machine: $m  run: $d  (avg duration)/" > $data-avg.plot
				sed "s/DATAFILE/$data-plan/g" heatmap-plans.template | sed "s/TITLE/query: $q  machine: $m  run: $d  (query plans)/" > $data-plan.plot

				gnuplot $data-min.plot
				gnuplot $data-max.plot
				gnuplot $data-avg.plot
				gnuplot $data-plan.plot

				for f in *.eps; do
					convert -background white -alpha remove -alpha off -density 200 $f ${f/eps/png}
				done

				mv *.plot *.eps *.png *.data heatmaps/$m/$d/queries

			done

		done

		for wss in `psql -t -A $DBNAME -c "select distinct wal_segment FROM data_load WHERE run = '$d' AND machine = '$m'"`; do

			psql -t -A -F ' ' $DBNAME > load-total-$wss-wal-segment.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  load_time::int::text as value
 FROM data_load_results
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM data_load_results ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

			sed "s/DATAFILE/load-total-$wss-wal-segment/g" heatmap.template | sed "s/TITLE/machine: $m  run: $d/" > load-total-$wss-wal-segment.plot
			gnuplot load-total-$wss-wal-segment.plot

			for s in `psql -t -A $DBNAME -c "select distinct step_name FROM data_load WHERE run = '$d' AND machine = '$m' AND wal_segment = $wss"`; do

				psql -t -A -F ' ' $DBNAME > load-$s-$wss-wal-segment.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_block::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  step_time::int::text as value
 FROM data_load
WHERE run = ''$d'' AND machine = ''$m'' AND wal_segment = $wss AND step_name = ''$s''
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM data_load ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

				sed "s/DATAFILE/load-$s-$wss-wal-segment/g" heatmap.template | sed "s/TITLE/step: $s  machine: $m  run: $d/" > load-$s-$wss-wal-segment.plot
				gnuplot load-$s-$wss-wal-segment.plot

			done

			for f in *.eps; do
				convert -background white -alpha remove -alpha off -density 200 $f ${f/eps/png}
			done

			mv *.plot *.eps *.png *.data heatmaps/$m/$d/loads

		done

		for wbs in `psql -t -A $DBNAME -c "select distinct wal_block FROM data_load WHERE run = '$d' AND machine = '$m'"`; do

			psql -t -A -F ' ' $DBNAME > load-total-$wbs-wal-block.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_segment::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  load_time::int::text as value
 FROM data_load_results
WHERE run = ''$d'' AND machine = ''$m'' AND wal_block = $wbs
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM data_load_results ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

			ytics=`psql -t -A $DBNAME -c "SELECT string_agg(trim(wal_segment), ' ') FROM (SELECT DISTINCT lpad(wal_segment::text, 3) AS wal_segment FROM data_load_results WHERE run = '$d' AND machine = '$m' AND wal_block = $wbs ORDER BY 1) foo"`

			sed "s/DATAFILE/load-total-$wbs-wal-block/g" heatmap2.template | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/machine: $m run: $d WAL block: ${wbs}KB (load)/" > load-total-$wbs-wal-block.plot
			gnuplot load-total-$wbs-wal-block.plot

			for s in `psql -t -A $DBNAME -c "select distinct step_name FROM data_load WHERE run = '$d' AND machine = '$m' AND wal_block = $wbs"`; do

				psql -t -A -F ' ' $DBNAME > load-$s-$wbs-wal-block.data <<EOF
SELECT " 1", " 2", " 4", " 8", "16", "32" FROM crosstab('SELECT
  lpad(wal_segment::text,2) AS row_name,
  lpad(data_block::text,2) as category,
  step_time::int::text as value
 FROM data_load
WHERE run = ''$d'' AND machine = ''$m'' AND wal_block = $wbs AND step_name = ''$s''
ORDER BY 1,2',
'SELECT DISTINCT lpad(data_block::text,2) FROM data_load ORDER BY 1'
) AS ct(category text, " 1" text, " 2" text, " 4" text, " 8" text, "16" text, "32" text)
EOF

				sed "s/DATAFILE/load-$s-$wbs-wal-block/g" heatmap2.template | sed "s/YTICS_DATA/$ytics/" | sed "s/TITLE/machine: $m run: $d WAL block: ${wbs}KB ($s)/" > load-$s-$wbs-wal-block.plot
				gnuplot load-$s-$wbs-wal-block.plot

			done

			for f in *.eps; do
				convert -background white -alpha remove -alpha off -density 200 $f ${f/eps/png}
			done

			mv *.plot *.eps *.png *.data heatmaps/$m/$d/loads

		done

	done

done
