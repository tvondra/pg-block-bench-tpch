create table queries (
  id           serial primary key,
  run          text,   -- identifies the run (date)
  machine      text,   -- identifies the system (i5/xeon)
  data_block   int,    -- data block size in KB
  wal_block    int,    -- WAL block size in KB
  data_segment int,    -- data segment size
  wal_segment  int,    -- WAL segment size in MB
  query_id     text,   -- query number
  query_run    int,    -- run number (1..3)
  query_time   float4, -- duration of the query
  query_start  float4, -- start of the query
  plan_hash    text,
  result_hash  text
);

create table data_load (
  id           serial primary key,
  run          text,   -- identifies the run (date)
  machine      text,   -- identifies the system (i5/xeon)
  data_block   int,    -- data block size in KB
  wal_block    int,    -- WAL block size in KB
  data_segment int,    -- data segment size
  wal_segment  int,    -- WAL segment size in MB
  step_name    text,   -- step of load
  step_time    float4, -- duration of the step
  step_start   float4,
  step_wal     bigint
);

create view query_results as
select
  run,
  machine,
  data_segment,
  wal_segment, 
  data_block,
  wal_block,
  query_id,
  avg(query_time) as query_time_avg,
  min(query_time) as query_time_min,
  max(query_time) as query_time_max
from queries
group by 1, 2, 3, 4, 5, 6, 7
order by 1, 2, 3, 4, 5, 6, 7;

create view query_results_agg as
select
  run,
  machine,
  data_segment,
  wal_segment, 
  data_block,
  wal_block,
  sum(query_time_avg) as query_time_avg,
  sum(query_time_min) as query_time_min,
  sum(query_time_max) as query_time_max
from query_results
group by 1, 2, 3, 4, 5, 6
order by 1, 2, 3, 4, 5, 6;


create view data_load_results as
select
  run,
  machine,
  data_segment,
  wal_segment, 
  data_block,
  wal_block,
  count(*) steps,
  sum(step_time) as load_time
from data_load
group by 1, 2, 3, 4, 5, 6
order by 1, 2, 3, 4, 5, 6;
