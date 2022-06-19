# README

WwworkRemote

Oh. HI!

## Example source queries

```
where
  payload->'response_body'->'rss'->'channel'->'item'->>'title' ~ '^No job postings'
;
```

```
where
  payload->'response'->>'status' = '301'
  and payload->'response'->>'body' = ''
;
```

```
where
  payload->'response'->'body'->'rss'->>'channel' is not null
  and payload->'response'->'body'->'rss'->'channel'->>'item' is null
;
```

## HackerNews Jobstories are automatically resolved

```
where
  payload->>'url' = 'https://hacker-news.firebaseio.com/v0/jobstories.json'
;
```

```
config.lograge.ignore_actions = %w[HealthCheck::HealthCheckController#index]
```
