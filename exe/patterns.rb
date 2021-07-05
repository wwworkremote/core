#!/usr/bin/env /Users/mike/projects/outlier_jobs/rails runner
# frozen_string_literal: true

begin
  feed = Notifications::RequestFaraday.find_each.flat_map do |notification|
    payload = notification.payload
    response_body = payload['response_body']

    next if response_body.blank? || response_body.is_a?(Array)

    response_body = response_body.deep_symbolize_keys

    case response_body
    in response_body: String | Array
      nil
    in by: String => by,
       id: Integer => id,
       score: Integer,
       text: String => text,
       time: Integer => time,
       title: String => title,
       type: String => type if type == 'job'

      {
        body: text.strip,
        external_author_id: by,
        external_id: id,
        published_at: Time.at(time, in: 'UTC').utc,
        title: title.strip
      }
    in by: String => by,
       id: Integer => id,
       score: Integer,
       time: Integer => time,
       title: String => title,
       type: String => type,
       url: String => url if type == 'job'

      {
        external_author_id: by,
        external_id: id,
        published_at: Time.at(time, in: 'UTC').utc,
        target_url: url,
        title: title.strip
      }

    in by: String => by,
       id: Integer => id,
       score: Integer,
       text: String => text,
       time: Integer => time,
       title: String => title,
       type: String => type,
       url: String => url if type == 'job'

      {
        body: text.strip,
        external_author_id: by,
        external_id: id,
        published_at: Time.at(time, in: 'UTC').utc,
        target_url: url,
        title: title.strip
      }

    in rss: { channel: { item: [*items] } }
      items.flat_map do |item|
        case item
        in description: String => description,
           guid: { __content__: String => guid },
           link: String => link,
           pubDate: String => pub_date,
           title: String => title

          {
            body: description.strip,
            external_id: guid,
            published_at: Time.strptime(pub_date, '%a, %d %b %Y %H:%M:%S %Z'),
            target_url: link,
            title: title.strip
          }
        in description: String => description,
           guid: String => guid,
           link: String => link,
           pubDate: String => pub_date,
           title: String => title

          {
            body: description.strip,
            external_id: guid,
            published_at: Time.strptime(pub_date, '%a, %d %b %Y %H:%M:%S %Z'),
            target_url: link,
            title: title
          }
        end
      end
    end
  end

  ap feed
  ap Notifications::RequestFaraday.count
  ap feed.size
rescue StandardError => e
  ap e
  binding.pry
  puts
end
