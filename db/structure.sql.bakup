SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: sslinfo; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS sslinfo WITH SCHEMA public;


--
-- Name: EXTENSION sslinfo; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION sslinfo IS 'information about SSL certificates';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domains (
    id bigint NOT NULL,
    name public.citext NOT NULL,
    root_domain_id bigint,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: domain_hierarchies; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.domain_hierarchies AS
 SELECT root_domains.id,
    root_domains.name,
    jsonb_object_agg(DISTINCT domains.id, domains.name ORDER BY domains.id) AS subdomains,
    count(DISTINCT domains.id) AS subdomain_count
   FROM (public.domains root_domains
     LEFT JOIN public.domains ON ((root_domains.root_domain_id = domains.root_domain_id)))
  WHERE ((root_domains.id = root_domains.root_domain_id) AND (domains.root_domain_id <> domains.id))
  GROUP BY root_domains.id, root_domains.name
  ORDER BY (count(DISTINCT domains.id)) DESC, root_domains.id DESC
  WITH NO DATA;


--
-- Name: domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.domains_id_seq OWNED BY public.domains.id;


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emails (
    id bigint NOT NULL,
    address public.citext NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.emails_id_seq OWNED BY public.emails.id;


--
-- Name: job_postings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_postings (
    id bigint NOT NULL,
    signature character varying NOT NULL,
    source_id bigint,
    title character varying,
    body character varying,
    company character varying,
    location character varying,
    external_author_id character varying,
    external_id character varying,
    published_at timestamp without time zone,
    tags character varying[],
    target_url character varying,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: job_postings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_postings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_postings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_postings_id_seq OWNED BY public.job_postings.id;


--
-- Name: origins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.origins (
    id bigint NOT NULL,
    name public.citext,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: origins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.origins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: origins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.origins_id_seq OWNED BY public.origins.id;


--
-- Name: pghero_query_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pghero_query_stats (
    id bigint NOT NULL,
    database text,
    "user" text,
    query text,
    query_hash bigint,
    total_time double precision,
    calls bigint,
    captured_at timestamp without time zone
);


--
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pghero_query_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pghero_query_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pghero_query_stats_id_seq OWNED BY public.pghero_query_stats.id;


--
-- Name: pghero_space_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pghero_space_stats (
    id bigint NOT NULL,
    database text,
    schema text,
    relation text,
    size bigint,
    captured_at timestamp without time zone
);


--
-- Name: pghero_space_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pghero_space_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pghero_space_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pghero_space_stats_id_seq OWNED BY public.pghero_space_stats.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
)
PARTITION BY RANGE (created_at);


--
-- Name: sources_y2020_m11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2020_m11 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2020_m12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2020_m12 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m01 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m02 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m03 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m04 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m05 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m06 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m07 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m08 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m09 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m10 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m11 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2021_m12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2021_m12 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2022_m01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2022_m01 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sources_y2022_m02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources_y2022_m02 (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    signature text NOT NULL,
    event jsonb DEFAULT '{}'::jsonb NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id bigint NOT NULL,
    name public.citext NOT NULL,
    slug public.citext NOT NULL,
    root_tag_id integer,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: target_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.target_domains (
    id bigint NOT NULL,
    job_posting_id bigint NOT NULL,
    domain_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: target_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.target_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: target_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.target_domains_id_seq OWNED BY public.target_domains.id;


--
-- Name: sources_y2020_m11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2020_m11 FOR VALUES FROM ('2020-11-01 00:00:00') TO ('2020-12-01 00:00:00');


--
-- Name: sources_y2020_m12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2020_m12 FOR VALUES FROM ('2020-12-01 00:00:00') TO ('2021-01-01 00:00:00');


--
-- Name: sources_y2021_m01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m01 FOR VALUES FROM ('2021-01-01 00:00:00') TO ('2021-02-01 00:00:00');


--
-- Name: sources_y2021_m02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m02 FOR VALUES FROM ('2021-02-01 00:00:00') TO ('2021-03-01 00:00:00');


--
-- Name: sources_y2021_m03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m03 FOR VALUES FROM ('2021-03-01 00:00:00') TO ('2021-04-01 00:00:00');


--
-- Name: sources_y2021_m04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m04 FOR VALUES FROM ('2021-04-01 00:00:00') TO ('2021-05-01 00:00:00');


--
-- Name: sources_y2021_m05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m05 FOR VALUES FROM ('2021-05-01 00:00:00') TO ('2021-06-01 00:00:00');


--
-- Name: sources_y2021_m06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m06 FOR VALUES FROM ('2021-06-01 00:00:00') TO ('2021-07-01 00:00:00');


--
-- Name: sources_y2021_m07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m07 FOR VALUES FROM ('2021-07-01 00:00:00') TO ('2021-08-01 00:00:00');


--
-- Name: sources_y2021_m08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m08 FOR VALUES FROM ('2021-08-01 00:00:00') TO ('2021-09-01 00:00:00');


--
-- Name: sources_y2021_m09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m09 FOR VALUES FROM ('2021-09-01 00:00:00') TO ('2021-10-01 00:00:00');


--
-- Name: sources_y2021_m10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m10 FOR VALUES FROM ('2021-10-01 00:00:00') TO ('2021-11-01 00:00:00');


--
-- Name: sources_y2021_m11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m11 FOR VALUES FROM ('2021-11-01 00:00:00') TO ('2021-12-01 00:00:00');


--
-- Name: sources_y2021_m12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2021_m12 FOR VALUES FROM ('2021-12-01 00:00:00') TO ('2022-01-01 00:00:00');


--
-- Name: sources_y2022_m01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2022_m01 FOR VALUES FROM ('2022-01-01 00:00:00') TO ('2022-02-01 00:00:00');


--
-- Name: sources_y2022_m02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources ATTACH PARTITION public.sources_y2022_m02 FOR VALUES FROM ('2022-02-01 00:00:00') TO ('2022-03-01 00:00:00');


--
-- Name: domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domains ALTER COLUMN id SET DEFAULT nextval('public.domains_id_seq'::regclass);


--
-- Name: emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails ALTER COLUMN id SET DEFAULT nextval('public.emails_id_seq'::regclass);


--
-- Name: job_postings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_postings ALTER COLUMN id SET DEFAULT nextval('public.job_postings_id_seq'::regclass);


--
-- Name: origins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.origins ALTER COLUMN id SET DEFAULT nextval('public.origins_id_seq'::regclass);


--
-- Name: pghero_query_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_query_stats ALTER COLUMN id SET DEFAULT nextval('public.pghero_query_stats_id_seq'::regclass);


--
-- Name: pghero_space_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_space_stats ALTER COLUMN id SET DEFAULT nextval('public.pghero_space_stats_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: target_domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_domains ALTER COLUMN id SET DEFAULT nextval('public.target_domains_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: domains domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (id);


--
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: job_postings job_postings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_postings
    ADD CONSTRAINT job_postings_pkey PRIMARY KEY (id);


--
-- Name: origins origins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.origins
    ADD CONSTRAINT origins_pkey PRIMARY KEY (id);


--
-- Name: pghero_query_stats pghero_query_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_query_stats
    ADD CONSTRAINT pghero_query_stats_pkey PRIMARY KEY (id);


--
-- Name: pghero_space_stats pghero_space_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pghero_space_stats
    ADD CONSTRAINT pghero_space_stats_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2020_m11 sources_y2020_m11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2020_m11
    ADD CONSTRAINT sources_y2020_m11_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2020_m12 sources_y2020_m12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2020_m12
    ADD CONSTRAINT sources_y2020_m12_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m01 sources_y2021_m01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m01
    ADD CONSTRAINT sources_y2021_m01_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m02 sources_y2021_m02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m02
    ADD CONSTRAINT sources_y2021_m02_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m03 sources_y2021_m03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m03
    ADD CONSTRAINT sources_y2021_m03_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m04 sources_y2021_m04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m04
    ADD CONSTRAINT sources_y2021_m04_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m05 sources_y2021_m05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m05
    ADD CONSTRAINT sources_y2021_m05_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m06 sources_y2021_m06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m06
    ADD CONSTRAINT sources_y2021_m06_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m07 sources_y2021_m07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m07
    ADD CONSTRAINT sources_y2021_m07_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m08 sources_y2021_m08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m08
    ADD CONSTRAINT sources_y2021_m08_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m09 sources_y2021_m09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m09
    ADD CONSTRAINT sources_y2021_m09_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m10 sources_y2021_m10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m10
    ADD CONSTRAINT sources_y2021_m10_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m11 sources_y2021_m11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m11
    ADD CONSTRAINT sources_y2021_m11_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2021_m12 sources_y2021_m12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2021_m12
    ADD CONSTRAINT sources_y2021_m12_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2022_m01 sources_y2022_m01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2022_m01
    ADD CONSTRAINT sources_y2022_m01_pkey PRIMARY KEY (id, created_at);


--
-- Name: sources_y2022_m02 sources_y2022_m02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources_y2022_m02
    ADD CONSTRAINT sources_y2022_m02_pkey PRIMARY KEY (id, created_at);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: target_domains target_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_domains
    ADD CONSTRAINT target_domains_pkey PRIMARY KEY (id);


--
-- Name: index_domain_hierarchies_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_domain_hierarchies_on_id ON public.domain_hierarchies USING btree (id);


--
-- Name: index_domains_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_domains_on_name ON public.domains USING btree (name);


--
-- Name: index_emails_on_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_emails_on_address ON public.emails USING btree (address);


--
-- Name: index_job_postings_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_postings_on_source_id ON public.job_postings USING btree (source_id);


--
-- Name: index_job_postings_on_tags_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_postings_on_tags_and_id ON public.job_postings USING btree (tags, id);


--
-- Name: index_pghero_query_stats_on_database_and_captured_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pghero_query_stats_on_database_and_captured_at ON public.pghero_query_stats USING btree (database, captured_at);


--
-- Name: index_pghero_space_stats_on_database_and_captured_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pghero_space_stats_on_database_and_captured_at ON public.pghero_space_stats USING btree (database, captured_at);


--
-- Name: index_sources_on_id_and_created_at_and_signature; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sources_on_id_and_created_at_and_signature ON ONLY public.sources USING btree (id, created_at, signature);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tags_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_slug ON public.tags USING btree (slug);


--
-- Name: index_target_domains_on_domain_id_and_job_posting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_target_domains_on_domain_id_and_job_posting_id ON public.target_domains USING btree (domain_id, job_posting_id);


--
-- Name: index_target_domains_on_job_posting_id_and_domain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_target_domains_on_job_posting_id_and_domain_id ON public.target_domains USING btree (job_posting_id, domain_id);


--
-- Name: sources_y2020_m11_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2020_m11_id_created_at_signature_idx ON public.sources_y2020_m11 USING btree (id, created_at, signature);


--
-- Name: sources_y2020_m12_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2020_m12_id_created_at_signature_idx ON public.sources_y2020_m12 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m01_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m01_id_created_at_signature_idx ON public.sources_y2021_m01 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m02_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m02_id_created_at_signature_idx ON public.sources_y2021_m02 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m03_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m03_id_created_at_signature_idx ON public.sources_y2021_m03 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m04_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m04_id_created_at_signature_idx ON public.sources_y2021_m04 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m05_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m05_id_created_at_signature_idx ON public.sources_y2021_m05 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m06_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m06_id_created_at_signature_idx ON public.sources_y2021_m06 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m07_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m07_id_created_at_signature_idx ON public.sources_y2021_m07 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m08_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m08_id_created_at_signature_idx ON public.sources_y2021_m08 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m09_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m09_id_created_at_signature_idx ON public.sources_y2021_m09 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m10_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m10_id_created_at_signature_idx ON public.sources_y2021_m10 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m11_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m11_id_created_at_signature_idx ON public.sources_y2021_m11 USING btree (id, created_at, signature);


--
-- Name: sources_y2021_m12_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2021_m12_id_created_at_signature_idx ON public.sources_y2021_m12 USING btree (id, created_at, signature);


--
-- Name: sources_y2022_m01_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2022_m01_id_created_at_signature_idx ON public.sources_y2022_m01 USING btree (id, created_at, signature);


--
-- Name: sources_y2022_m02_id_created_at_signature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sources_y2022_m02_id_created_at_signature_idx ON public.sources_y2022_m02 USING btree (id, created_at, signature);


--
-- Name: sources_y2020_m11_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2020_m11_id_created_at_signature_idx;


--
-- Name: sources_y2020_m11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2020_m11_pkey;


--
-- Name: sources_y2020_m12_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2020_m12_id_created_at_signature_idx;


--
-- Name: sources_y2020_m12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2020_m12_pkey;


--
-- Name: sources_y2021_m01_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m01_id_created_at_signature_idx;


--
-- Name: sources_y2021_m01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m01_pkey;


--
-- Name: sources_y2021_m02_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m02_id_created_at_signature_idx;


--
-- Name: sources_y2021_m02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m02_pkey;


--
-- Name: sources_y2021_m03_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m03_id_created_at_signature_idx;


--
-- Name: sources_y2021_m03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m03_pkey;


--
-- Name: sources_y2021_m04_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m04_id_created_at_signature_idx;


--
-- Name: sources_y2021_m04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m04_pkey;


--
-- Name: sources_y2021_m05_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m05_id_created_at_signature_idx;


--
-- Name: sources_y2021_m05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m05_pkey;


--
-- Name: sources_y2021_m06_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m06_id_created_at_signature_idx;


--
-- Name: sources_y2021_m06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m06_pkey;


--
-- Name: sources_y2021_m07_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m07_id_created_at_signature_idx;


--
-- Name: sources_y2021_m07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m07_pkey;


--
-- Name: sources_y2021_m08_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m08_id_created_at_signature_idx;


--
-- Name: sources_y2021_m08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m08_pkey;


--
-- Name: sources_y2021_m09_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m09_id_created_at_signature_idx;


--
-- Name: sources_y2021_m09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m09_pkey;


--
-- Name: sources_y2021_m10_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m10_id_created_at_signature_idx;


--
-- Name: sources_y2021_m10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m10_pkey;


--
-- Name: sources_y2021_m11_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m11_id_created_at_signature_idx;


--
-- Name: sources_y2021_m11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m11_pkey;


--
-- Name: sources_y2021_m12_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2021_m12_id_created_at_signature_idx;


--
-- Name: sources_y2021_m12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2021_m12_pkey;


--
-- Name: sources_y2022_m01_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2022_m01_id_created_at_signature_idx;


--
-- Name: sources_y2022_m01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2022_m01_pkey;


--
-- Name: sources_y2022_m02_id_created_at_signature_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_sources_on_id_and_created_at_and_signature ATTACH PARTITION public.sources_y2022_m02_id_created_at_signature_idx;


--
-- Name: sources_y2022_m02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.sources_pkey ATTACH PARTITION public.sources_y2022_m02_pkey;


--
-- Name: target_domains fk_rails_94b9410c80; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_domains
    ADD CONSTRAINT fk_rails_94b9410c80 FOREIGN KEY (domain_id) REFERENCES public.domains(id);


--
-- Name: target_domains fk_rails_c053cd46b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.target_domains
    ADD CONSTRAINT fk_rails_c053cd46b2 FOREIGN KEY (job_posting_id) REFERENCES public.job_postings(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20210626222927'),
('20210712020439'),
('20210712021013'),
('20210815003805'),
('20210905163739'),
('20210926193251'),
('20210930221729'),
('20211001125635'),
('20211003201634'),
('20211004134953'),
('20211006120147'),
('20211011133311'),
('20211011135906'),
('20211031220334');


