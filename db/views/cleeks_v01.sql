select
  'messages' as name,
  now() as timestamp,
  count(*) as value,
  min(created_at) as lbound,
  count(*) filter (where created_at >= now() - '1 week'::interval) as lbound_week_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 week'::interval), min(created_at)) as lbound_week,
  count(*) filter (where created_at >= now() - '1 day'::interval) as lbound_day_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 day'::interval), min(created_at)) as lbound_day,
  count(*) filter (where created_at >= now() - '1 hour'::interval) as lbound_hour_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 hour'::interval), min(created_at)) as lbound_hour,
  max(created_at) as rbound
from
  messages
union all
select
  'sources' as name,
  now() as timestamp,
  count(*) as value,
  min(created_at) as lbound,
  count(*) filter (where created_at >= now() - '1 week'::interval) as lbound_week_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 week'::interval), min(created_at)) as lbound_week,
  count(*) filter (where created_at >= now() - '1 day'::interval) as lbound_day_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 day'::interval), min(created_at)) as lbound_day,
  count(*) filter (where created_at >= now() - '1 hour'::interval) as lbound_hour_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 hour'::interval), min(created_at)) as lbound_hour,
  max(created_at) as rbound
from
  sources
union all
select
  'tags' as name,
  now() as timestamp,
  count(*) as value,
  min(created_at) as lbound,
  count(*) filter (where created_at >= now() - '1 week'::interval) as lbound_week_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 week'::interval), min(created_at)) as lbound_week,
  count(*) filter (where created_at >= now() - '1 day'::interval) as lbound_day_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 day'::interval), min(created_at)) as lbound_day,
  count(*) filter (where created_at >= now() - '1 hour'::interval) as lbound_hour_value,
  coalesce(min(created_at) filter (where created_at >= now() - '1 hour'::interval), min(created_at)) as lbound_hour,
  max(created_at) as rbound
from
  tags;
