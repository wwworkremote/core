select
  root_domains.id as id,
  root_domains.name as name,
  jsonb_object_agg(distinct domains.id, domains.name
  order by
    domains.id asc) as subdomains,
  -- array_agg(distinct domains.name order by domains.name asc) as subdomain_names,
  -- array_agg(distinct domains.id order by domains.id asc) as subdomain_ids,
  count(distinct domains.id) as subdomain_count
from
  domains as root_domains
  left outer join domains on root_domains.root_domain_id = domains.root_domain_id
where
  root_domains.id = root_domains.root_domain_id
  and domains.root_domain_id != domains.id
group by
  root_domains.id,
  root_domains.name
order by
  count(distinct domains.id)
  desc,
  root_domains.id desc;
