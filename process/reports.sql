select machine, run, query_id, count(distinct plan_hash) filter (where wal_segment = 1), count(distinct plan_hash) filter (where wal_segment = 16), count(distinct plan_hash) filter (where wal_segment = 512) from queries group by 1,2,3 order by 1, 2, 3, query_id::int;



