# README

Praca Zdalna


## Update Sources with no results

```
update
  sources
set
  status = -1
where
  status = 0
  and payload->'response_body'->'rss'->'channel'->'item'->>'title' ~ '^No job postings'
;
```

```
update sources
set status = -1
where
  status = 0
  and payload->'response'->>'status' = '301'
  and payload->'response'->>'body' = ''
;
```

```
update
  sources
set
  status = -1
where
  status = 0
  and (
    payload->'response'->'body'->'rss'->>'channel' is not null
      and payload->'response'->'body'->'rss'->'channel'->>'item' is null
  ) 
;
```
