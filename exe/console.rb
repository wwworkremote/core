#!/usr/bin/env /Users/mike/projects/outlier_jobs/rails runner
# frozen_string_literal: true

Notifications::RequestFaraday.find_each do |notification|
  payload = notification.payload.deep_symbolize_keys
  ap payload.keys

  case payload
  in response_body: Array
    puts 'Array'
  # Filter for RSS job postings
  in response_body: { rss: { channel: { item: [*items] } } }
    items.map do |item|
      case item
      in {
        guid: { __content__: String => guid },
        pubDate: String => pub_date,
        link: String => link,
        title: String => title,
        description: String => description
      }

        {
          external_id: guid,
          published_at: DateTime.strptime(pub_date, '%a, %d %b %Y %H:%M:%S %Z'),
          target_url: link,
          title: title,
          body: description.strip
        }
      end
    rescue NoMatchingPatternError => e
      ap e
      binding.pry
      puts
    end
  end
end

binding.pry
puts
