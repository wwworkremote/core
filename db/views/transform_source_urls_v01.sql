select
  source_id,
  url,
  protocol,
  host,
  path,
  qs2.querystring
from (
  select
    s.id as source_id,
    source_url ->> 'url' as url,
    source_url ->> 'protocol' as protocol,
    source_url ->> 'host' as host,
    split_part(source_url ->> 'url_path', '?', 1) as path,
    string_to_array(split_part(regexp_replace(regexp_replace(source_url ->> 'url_path', '%5B', '['), '%5D', ']'), '?', 2), '&') as querystring
  from
    sources as s
  left join lateral (
    select
      jsonb_object (array_agg(alias),
        array_agg(token)) as source_url
    from
      ts_parse('default', payload ->> 'url') as parsed
      natural join ts_token_type('default')
    where
      tokid in(5, 14, 6, 18)) as url on true) as t2
  left join lateral (
    select
      jsonb_object (array_agg(split_part(qs, '=', 1)), array_agg(split_part(qs, '=', 2))) as querystring
    from
      unnest(querystring) with ordinality qs) as qs2 on true
;
