# frozen_string_literal: true

# == Route Map
#
# I, [2026-04-22T13:31:55.579320 #16365]  INFO -- : Instrumentation: OpenTelemetry::Instrumentation::Rails was successfully installed with the following options {}
# I, [2026-04-22T13:31:55.591595 #16365]  INFO -- : Instrumentation: OpenTelemetry::Instrumentation::PG was successfully installed with the following options {peer_service: nil, db_statement: :obfuscate, obfuscation_limit: 2000, propagator: "none"}
# I, [2026-04-22T13:31:55.594463 #16365]  INFO -- : Instrumentation: OpenTelemetry::Instrumentation::Faraday was successfully installed with the following options {span_kind: :client, peer_service: nil, enable_internal_instrumentation: false}
# I, [2026-04-22T13:31:55.597630 #16365]  INFO -- : Instrumentation: OpenTelemetry::Instrumentation::RubyLLM was successfully installed with the following options {capture_content: false}
#                                   Prefix Verb   URI Pattern                                                                                       Controller#Action
#          analyze_match_user_job_postings POST   /user_job_postings/analyze_match(.:format)                                                        user_job_postings#analyze_match
#     generate_artifacts_user_job_postings POST   /user_job_postings/generate_artifacts(.:format)                                                   user_job_postings#generate_artifacts
#                        user_job_postings GET    /user_job_postings(.:format)                                                                      user_job_postings#index
#                                          POST   /user_job_postings(.:format)                                                                      user_job_postings#create
#                         user_job_posting PATCH  /user_job_postings/:id(.:format)                                                                  user_job_postings#update
#                                          PUT    /user_job_postings/:id(.:format)                                                                  user_job_postings#update
#                                          DELETE /user_job_postings/:id(.:format)                                                                  user_job_postings#destroy
#                      edit_career_profile GET    /career_profile/edit(.:format)                                                                    career_profiles#edit
#                           career_profile GET    /career_profile(.:format)                                                                         career_profiles#show
#                                          PATCH  /career_profile(.:format)                                                                         career_profiles#update
#                                          PUT    /career_profile(.:format)                                                                         career_profiles#update
#                          companies_index GET    /companies/index(.:format)                                                                        companies#index
#                           companies_show GET    /companies/show(.:format)                                                                         companies#show
#            company_pipeline_steps_create GET    /company_pipeline_steps/create(.:format)                                                          company_pipeline_steps#create
#                          contacts_create GET    /contacts/create(.:format)                                                                        contacts#create
#                         contacts_destroy GET    /contacts/destroy(.:format)                                                                       contacts#destroy
#                    pipeline_steps_create GET    /pipeline_steps/create(.:format)                                                                  pipeline_steps#create
#                    llm_chat_llm_messages POST   /llm_chats/:llm_chat_id/llm_messages(.:format)                                                    llm_messages#create
#                                llm_chats GET    /llm_chats(.:format)                                                                              llm_chats#index
#                                          POST   /llm_chats(.:format)                                                                              llm_chats#create
#                             new_llm_chat GET    /llm_chats/new(.:format)                                                                          llm_chats#new
#                            edit_llm_chat GET    /llm_chats/:id/edit(.:format)                                                                     llm_chats#edit
#                                 llm_chat GET    /llm_chats/:id(.:format)                                                                          llm_chats#show
#                                          PATCH  /llm_chats/:id(.:format)                                                                          llm_chats#update
#                                          PUT    /llm_chats/:id(.:format)                                                                          llm_chats#update
#                                          DELETE /llm_chats/:id(.:format)                                                                          llm_chats#destroy
#                           refresh_models POST   /models/refresh(.:format)                                                                         models#refresh
#                                   models GET    /models(.:format)                                                                                 models#index
#                                    model GET    /models/:id(.:format)                                                                             models#show
#                               admin_root GET    /admin(.:format)                                                                                  admin/dashboard#index
#                       admin_toggle_pause POST   /admin/toggle_pause(.:format)                                                                     admin/dashboard#toggle_pause
#                          admin_analytics GET    /admin/analytics(.:format)                                                                        admin/analytics#index
#                       trigger_admin_jobs POST   /admin/jobs/trigger(.:format)                                                                     admin/jobs#trigger
#                         prune_admin_jobs POST   /admin/jobs/prune(.:format)                                                                       admin/jobs#prune
#                        details_admin_job GET    /admin/jobs/:id/details(.:format)                                                                 admin/jobs#details
#                        discard_admin_job POST   /admin/jobs/:id/discard(.:format)                                                                 admin/jobs#discard
#                               admin_jobs GET    /admin/jobs(.:format)                                                                             admin/jobs#index
#     admin_company_company_pipeline_steps POST   /admin/companies/:company_id/company_pipeline_steps(.:format)                                     admin/company_pipeline_steps#create
#                          admin_companies GET    /admin/companies(.:format)                                                                        admin/companies#index
#                            admin_company GET    /admin/companies/:id(.:format)                                                                    admin/companies#show
#         admin_job_posting_pipeline_steps POST   /admin/job_postings/:job_posting_id/pipeline_steps(.:format)                                      admin/pipeline_steps#create
#               admin_job_posting_contacts POST   /admin/job_postings/:job_posting_id/contacts(.:format)                                            admin/contacts#create
#                admin_job_posting_contact DELETE /admin/job_postings/:job_posting_id/contacts/:id(.:format)                                        admin/contacts#destroy
#                       admin_job_postings GET    /admin/job_postings(.:format)                                                                     admin/job_postings#index
#                        admin_job_posting GET    /admin/job_postings/:id(.:format)                                                                 admin/job_postings#show
#                            admin_sources GET    /admin/sources(.:format)                                                                          admin/sources#index
#                             admin_source GET    /admin/sources/:id(.:format)                                                                      admin/sources#show
#                            admin_queries GET    /admin/queries(.:format)                                                                          admin/queries#index
#                              admin_query GET    /admin/queries/:id(.:format)                                                                      admin/queries#show
#                          admin_documents GET    /admin/documents(.:format)                                                                        admin/documents#index
#                           admin_document GET    /admin/documents/:id(.:format)                                                                    admin/documents#show
#                                          DELETE /admin/documents/:id(.:format)                                                                    admin/documents#destroy
#                            admin_domains GET    /admin/domains(.:format)                                                                          admin/domains#index
#                             admin_domain GET    /admin/domains/:id(.:format)                                                                      admin/domains#show
#                                          DELETE /admin/domains/:id(.:format)                                                                      admin/domains#destroy
#               admin_email_import_records GET    /admin/email_import_records(.:format)                                                             admin/email_import_records#index
#                admin_email_import_record GET    /admin/email_import_records/:id(.:format)                                                         admin/email_import_records#show
#                             admin_models GET    /admin/models(.:format)                                                                           admin/models#index
#                              admin_model GET    /admin/models/:id(.:format)                                                                       admin/models#show
#                             admin_visits GET    /admin/visits(.:format)                                                                           admin/visits#index
#                              admin_visit GET    /admin/visits/:id(.:format)                                                                       admin/visits#show
#                             admin_events GET    /admin/events(.:format)                                                                           admin/events#index
#                              admin_event GET    /admin/events/:id(.:format)                                                                       admin/events#show
#                                    about GET    /about(.:format)                                                                                  pages#show {page: "about"}
#                                     root GET    /                                                                                                 home#index
#                               home_index GET    /home/index(.:format)                                                                             home#index
#                            outbound_link GET    /outbound_links/:id(.:format)                                                                     outbound_links#show
#                             job_postings GET    /job_postings(.:format)                                                                           job_postings#index
#                              job_posting GET    /job_postings/:id(.:format)                                                                       job_postings#show
#                        run_data_fetchers POST   /data_fetchers/run(.:format)                                                                      data_fetchers#run
#            run_all_by_type_data_fetchers POST   /data_fetchers/run_all_by_type(.:format)                                                          data_fetchers#run_all_by_type
#                      audit_data_fetchers POST   /data_fetchers/audit(.:format)                                                                    data_fetchers#audit
#                     enrich_data_fetchers POST   /data_fetchers/enrich(.:format)                                                                   data_fetchers#enrich
#                            data_fetchers GET    /data_fetchers(.:format)                                                                          data_fetchers#index
#                               api_v0_geo GET    /api/v0/geo(.:format)                                                                             api/v0/geo#index {format: :json}
#                           api_v0_sources GET    /api/v0/sources(.:format)                                                                         api/v0/sources#index {format: :json}
#                            api_v0_source GET    /api/v0/sources/:id(.:format)                                                                     api/v0/sources#show {format: :json}
#                      api_v0_job_postings GET    /api/v0/job_postings(.:format)                                                                    api/v0/job_postings#index {format: :json}
#                       api_v0_job_posting GET    /api/v0/job_postings/:id(.:format)                                                                api/v0/job_postings#show {format: :json}
#              charts_data_behavior_visits GET    /charts/data/behavior/visits(.:format)                                                            charts/data/behavior#visits {format: :json}
#              charts_data_behavior_events GET    /charts/data/behavior/events(.:format)                                                            charts/data/behavior#events {format: :json}
#           charts_data_behavior_referrers GET    /charts/data/behavior/referrers(.:format)                                                         charts/data/behavior#referrers {format: :json}
#                      charts_data_sources GET    /charts/data/sources(.:format)                                                                    charts/data/sources#index {format: :json}
#                 charts_data_job_postings GET    /charts/data/job_postings(.:format)                                                               charts/data/job_postings#index {format: :json}
#          charts_data_job_postings_corpus GET    /charts/data/job_postings/corpus(.:format)                                                        charts/data/job_postings#corpus {format: :json}
#              charts_data_pipeline_health GET    /charts/data/pipeline/health(.:format)                                                            charts/data/pipeline#health {format: :json}
#              charts_data_pipeline_funnel GET    /charts/data/pipeline/funnel(.:format)                                                            charts/data/pipeline#funnel {format: :json}
#                   enrich_api_job_posting POST   /api/job_postings/:id/enrich(.:format)                                                            api/job_postings#enrich
#                                  pg_hero        /pghero                                                                                           PgHero::Engine
#                     mission_control_jobs        /jobs                                                                                             MissionControl::Jobs::Engine
#                                          GET    /pages/*page(.:format)                                                                            pages#show
#         turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                             turbo/native/navigation#recede
#         turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                             turbo/native/navigation#resume
#        turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                            turbo/native/navigation#refresh
#            rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                           action_mailbox/ingresses/postmark/inbound_emails#create
#               rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                              action_mailbox/ingresses/relay/inbound_emails#create
#            rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                           action_mailbox/ingresses/sendgrid/inbound_emails#create
#      rails_mandrill_inbound_health_check GET    /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#health_check
#            rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#create
#             rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                       action_mailbox/ingresses/mailgun/inbound_emails#create
#           rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#index
#                                          POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#create
#        new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                      rails/conductor/action_mailbox/inbound_emails#new
#            rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                      rails/conductor/action_mailbox/inbound_emails#show
# new_rails_conductor_inbound_email_source GET    /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                              rails/conductor/action_mailbox/inbound_emails/sources#new
#    rails_conductor_inbound_email_sources POST   /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                  rails/conductor/action_mailbox/inbound_emails/sources#create
#    rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                               rails/conductor/action_mailbox/reroutes#create
# rails_conductor_inbound_email_incinerate POST   /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                            rails/conductor/action_mailbox/incinerates#create
#                       rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#                 rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                          GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#                rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#          rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                          GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                       rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#                update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#                     rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create
#
# Routes for PgHero::Engine:
#                     space GET  (/:database)/space(.:format)                     pg_hero/home#space
#            relation_space GET  (/:database)/space/:relation(.:format)           pg_hero/home#relation_space
#               index_bloat GET  (/:database)/index_bloat(.:format)               pg_hero/home#index_bloat
#              live_queries GET  (/:database)/live_queries(.:format)              pg_hero/home#live_queries
#                   queries GET  (/:database)/queries(.:format)                   pg_hero/home#queries
#                show_query GET  (/:database)/queries/:query_hash(.:format)       pg_hero/home#show_query
#                    system GET  (/:database)/system(.:format)                    pg_hero/home#system
#                 cpu_usage GET  (/:database)/cpu_usage(.:format)                 pg_hero/home#cpu_usage
#          connection_stats GET  (/:database)/connection_stats(.:format)          pg_hero/home#connection_stats
#     replication_lag_stats GET  (/:database)/replication_lag_stats(.:format)     pg_hero/home#replication_lag_stats
#                load_stats GET  (/:database)/load_stats(.:format)                pg_hero/home#load_stats
#          free_space_stats GET  (/:database)/free_space_stats(.:format)          pg_hero/home#free_space_stats
#                   explain GET  (/:database)/explain(.:format)                   pg_hero/home#explain
#                      tune GET  (/:database)/tune(.:format)                      pg_hero/home#tune
#               connections GET  (/:database)/connections(.:format)               pg_hero/home#connections
#               maintenance GET  (/:database)/maintenance(.:format)               pg_hero/home#maintenance
#                      kill POST (/:database)/kill(.:format)                      pg_hero/home#kill
# kill_long_running_queries POST (/:database)/kill_long_running_queries(.:format) pg_hero/home#kill_long_running_queries
#                  kill_all POST (/:database)/kill_all(.:format)                  pg_hero/home#kill_all
#        enable_query_stats POST (/:database)/enable_query_stats(.:format)        pg_hero/home#enable_query_stats
#                           POST (/:database)/explain(.:format)                   pg_hero/home#explain
#         reset_query_stats POST (/:database)/reset_query_stats(.:format)         pg_hero/home#reset_query_stats
#              system_stats GET  (/:database)/system_stats(.:format)              redirect(301, system)
#               query_stats GET  (/:database)/query_stats(.:format)               redirect(301, queries)
#                      root GET  /(:database)(.:format)                           pg_hero/home#index
#
# Routes for MissionControl::Jobs::Engine:
#     application_queue_pause DELETE /applications/:application_id/queues/:queue_id/pause(.:format) mission_control/jobs/queues/pauses#destroy
#                             POST   /applications/:application_id/queues/:queue_id/pause(.:format) mission_control/jobs/queues/pauses#create
#          application_queues GET    /applications/:application_id/queues(.:format)                 mission_control/jobs/queues#index
#           application_queue GET    /applications/:application_id/queues/:id(.:format)             mission_control/jobs/queues#show
#       application_job_retry POST   /applications/:application_id/jobs/:job_id/retry(.:format)     mission_control/jobs/retries#create
#     application_job_discard POST   /applications/:application_id/jobs/:job_id/discard(.:format)   mission_control/jobs/discards#create
#    application_job_dispatch POST   /applications/:application_id/jobs/:job_id/dispatch(.:format)  mission_control/jobs/dispatches#create
#    application_bulk_retries POST   /applications/:application_id/jobs/bulk_retries(.:format)      mission_control/jobs/bulk_retries#create
#   application_bulk_discards POST   /applications/:application_id/jobs/bulk_discards(.:format)     mission_control/jobs/bulk_discards#create
#             application_job GET    /applications/:application_id/jobs/:id(.:format)               mission_control/jobs/jobs#show
#            application_jobs GET    /applications/:application_id/:status/jobs(.:format)           mission_control/jobs/jobs#index
#         application_workers GET    /applications/:application_id/workers(.:format)                mission_control/jobs/workers#index
#          application_worker GET    /applications/:application_id/workers/:id(.:format)            mission_control/jobs/workers#show
# application_recurring_tasks GET    /applications/:application_id/recurring_tasks(.:format)        mission_control/jobs/recurring_tasks#index
#  application_recurring_task GET    /applications/:application_id/recurring_tasks/:id(.:format)    mission_control/jobs/recurring_tasks#show
#                             PATCH  /applications/:application_id/recurring_tasks/:id(.:format)    mission_control/jobs/recurring_tasks#update
#                             PUT    /applications/:application_id/recurring_tasks/:id(.:format)    mission_control/jobs/recurring_tasks#update
#                      queues GET    /queues(.:format)                                              mission_control/jobs/queues#index
#                       queue GET    /queues/:id(.:format)                                          mission_control/jobs/queues#show
#                         job GET    /jobs/:id(.:format)                                            mission_control/jobs/jobs#show
#                        jobs GET    /:status/jobs(.:format)                                        mission_control/jobs/jobs#index
#                        root GET    /                                                              mission_control/jobs/queues#index

Rails.application.routes.draw do
  resources :user_job_postings, only: %i[index create update destroy] do
    collection do
      post :analyze_match
      post :generate_artifacts
    end
  end
  resource :career_profile, only: %i[show edit update] do
    member do
      post :sync_github
    end
  end
  get 'companies/index'
  get 'companies/show'
  get 'company_pipeline_steps/create'
  get 'contacts/create'
  get 'contacts/destroy'
  get 'pipeline_steps/create'
  resources :llm_chats do
    resources :llm_messages, only: %i[create]
  end
  resources :models, only: %i[index show] do
    collection do
      post :refresh
    end
  end
  namespace :admin do
    root to: 'dashboard#index'
    post 'toggle_pause' => 'dashboard#toggle_pause'
    get 'observability' => 'observability#index'
    resources :jobs, only: [:index] do
      collection do
        post :trigger
        post :prune
      end
      member do
        get :details
        post :discard
      end
    end
    resources :companies, only: %i[index show] do
      resources :company_pipeline_steps, only: [:create]
    end
    resources :job_postings, only: %i[index show] do
      resources :pipeline_steps, only: [:create]
      resources :contacts, only: %i[create destroy]
      resources :interview_sessions, only: [:create]
      resources :interview_tasks, only: [:create]
    end
    resources :interview_sessions, only: [] do
      resources :interview_questions, only: [:create]
    end

    resources :tasks, only: %i[index create update destroy]

    resources :sources, only: %i[index show]
    resources :queries, only: %i[index show]
    resources :documents, only: %i[index show destroy]
    resources :domains, only: %i[index show destroy]
    resources :email_import_records, only: %i[index show]
    resources :models, only: %i[index show]
    resources :visits, only: %i[index show]
    resources :events, only: %i[index show]
  end

  # Dashboard Routes
  get 'about' => 'pages#show', page: 'about'

  root to: 'home#index'
  get 'home/index'

  resources :outbound_links, only: [:show]
  resources :job_postings, only: %i[index show]

  resources :data_fetchers, only: [:index] do
    collection do
      post :run
      post :run_all_by_type
      post :audit
      post :enrich
    end
  end

  namespace :api, defaults: { format: :json }, constraints: { format: :json } do
    namespace :v0 do
      get 'geo' => 'geo#index'
      resources :sources, only: %i[index show]
      resources :job_postings, only: %i[index show create] do
        member do
          post :enrich
        end
      end
    end
  end

  namespace :charts do
    namespace :data, defaults: { format: :json }, constraints: { format: :json } do
      get 'behavior/visits' => 'behavior#visits'
      get 'behavior/events' => 'behavior#events'
      get 'behavior/referrers' => 'behavior#referrers'
      get 'sources' => 'sources#index'
      get 'job_postings' => 'job_postings#index'
      get 'job_postings/corpus'
      get 'pipeline/health' => 'pipeline#health'
      get 'pipeline/funnel' => 'pipeline#funnel'
    end
  end

  namespace :api do
    resources :job_postings, only: [] do
      member do
        post :enrich
      end
    end
    # ... other api routes ...
  end

  mount PgHero::Engine, at: 'pghero'
  mount MissionControl::Jobs::Engine, at: '/jobs'
  get '/pages/*page' => 'pages#show'
end
