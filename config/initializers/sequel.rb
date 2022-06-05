# frozen_string_literal: true

# Sequel.extension(:symbol_as)
#
# PGDATABASE = Sequel.connect(
#   adapter: 'postgres',
#   host: 'localhost',
#   database: "wwworkremote_#{Rails.env}"
# )
#
# PGDATABASE.extension(:pg_streaming)
#
# PGDATABASE.stream_all_queries = true

__END__

# Sequel.connect (
  after_connect: proc { |*args| puts [:after_connect, args].inspect },
  before_preconnect: proc { |*args| puts [:after_connect, args].inspect },
  notice_receiver: proc { |*args| puts [:notice_receiver, args].inspect },
  single_threaded: true
)

