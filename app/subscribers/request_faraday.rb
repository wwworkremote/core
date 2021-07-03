# frozen_string_literal: true

ActiveSupport::Notifications.monotonic_subscribe('request.faraday') do |event| # |name, start, finish, id, env|
  puts '------------ notify >>>>>>>>>>>>'

  puts "#{Rainbow('Payload:').bold.blue} #{event.payload.class}"
  puts "#{Rainbow('Started:').bold.blue} #{event.time.class}"
  puts "#{Rainbow('Finished:').bold.blue} #{event.end.class}"
  puts "#{Rainbow('Duration (ms):').bold.blue} #{event.duration.class}"
  puts "#{Rainbow('CPU time (ms):').bold.blue} #{event.cpu_time.class}"
  puts "#{Rainbow('Idle time (ms):').bold.blue} #{event.idle_time.class}"
  puts "#{Rainbow('Allocations:').bold.blue} #{event.allocations.class}"
  puts "#{Rainbow('Event:').bold.blue} #{event.inspect}"

  puts '<<<<<<<<<<<< notify ------------'
end
