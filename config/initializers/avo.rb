# frozen_string_literal: true

# For more information regarding these settings check out our docs https://docs.avohq.io
# The values disaplayed here are the default ones. Uncomment and change them to fit your needs.
Avo.configure do |config|
  ## == Routing ==
  config.root_path = '/avo'
  # used only when you have custom `map` configuration in your config.ru
  # config.prefix_path = "/internal"

  ## == Licensing ==
  config.license = 'community' # 'pro', 'enterprise', or 'community'
  # config.license_key = ENV['AVO_LICENSE_KEY']

  ## == Context ==
  # config.context = {}

  ## == Authentication ==
  # config.current_user_method = {}
  # config.authenticate_with = {}

  ## == Authorization ==
  # config.authorization_methods = {
  #   index: 'index?',
  #   show: 'show?',
  #   edit: 'edit?',
  #   new: 'new?',
  #   update: 'update?',
  #   create: 'create?',
  #   destroy: 'destroy?',
  #   associations_index: 'index?',
  #   associations_show: 'show?',
  #   associations_edit: 'edit?',
  #   associations_new: 'new?',
  #   associations_update: 'update?',
  #   associations_create: 'create?',
  #   associations_destroy: 'destroy?',
  # }
  # config.raise_error_on_missing_policy = false


  ## == Localization ==
  # config.locale = 'en-US'

  ## == Resource events ==
  # config.resource_event_notifier = -> (resource, event, user, record) {
  #   Rails.logger.info "Avo Resource Event: #{resource.class.name} #{event} by #{user.name} on #{record.id}"
  # }

  ## == Customization ==
  # config.app_name = 'Avocadelic'
  # config.timezone = 'UTC'
  # config.currency = 'USD'
  # config.hide_avo_branding = false
  # config.layout = :unpaged # :boxed or :unpaged
  # config.set_full_width_layout_wrap = true
  # config.top_header_layout = :paged # :paged or :full_width
  # config.sidebar_default_state = :open # :open or :closed
  # config.force_sidebar_open = false

  ## == Breadcrumbs ==
  # config.display_breadcrumbs = true
  # config.set_initial_breadcrumbs do
  #   add_breadcrumb "Home", '/avo'
  # end

  ## == Menus ==
  # config.main_menu = -> {
  #   section "Dashboards", icon: "dashboards" do
  #     all_dashboards
  #   end

  #   section "Resources", icon: "resources" do
  #     all_resources
  #   end

  #   section "Tools", icon: "tools" do
  #     all_tools
  #   end
  # }
  # config.profile_menu = -> {
  #   link "Profile", path: "/avo/profile", icon: "user"
  # }
end
