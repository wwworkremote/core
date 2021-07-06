#!/usr/bin/env /Users/mike/projects/outlier_jobs/rails runner
# frozen_string_literal: true

query = Notifications::RequestFaraday.where('created_at >= ?', 1.day.ago)
feed = query.find_each.flat_map do |notification|
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
      notification_id: notification.id,
      body: text.strip,
      external_author_id: by,
      external_id: id.to_s.strip,
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
      notification_id: notification.id,
      external_author_id: by,
      external_id: id.to_s.strip,
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
      notification_id: notification.id,
      body: text.strip,
      external_author_id: by,
      external_id: id.to_s.strip,
      published_at: Time.at(time, in: 'UTC').utc,
      target_url: url,
      title: title.strip
    }

  in rss: { channel: { item: [*items] } }
    items.flat_map do |item|
      case item

      in company: String => company,
          description: String => description,
          guid: String => guid,
          image: String,
          link: String => link,
          location: String => location,
          pubDate: String => pub_date,
          tags: String => tags,
          title: String => title

        {
          notification_id: notification.id,
          body: description.strip,
          external_id: guid.to_s.strip,
          published_at: DateTime.parse(pub_date).to_time,
          target_url: link,
          title: title.strip,
          location: location,
          company: company,
          tags: tags.split(',').map(&:strip)
        }

      in company: String => company,
          description: String => description,
          guid: String => guid,
          image: String,
          link: String => link,
          location:,
          pubDate: String => pub_date,
          tags: String => tags,
          title: String => title

        {
          notification_id: notification.id,
          body: description.strip,
          external_id: guid.to_s.strip,
          published_at: DateTime.parse(pub_date).to_time,
          target_url: link,
          title: title.strip,
          company: company,
          tags: tags.split(',').map(&:strip)
        }

      in description: String => description,
          guid: { __content__: String => guid },
          link: String => link,
          pubDate: String => pub_date,
          title: String => title

        {
          notification_id: notification.id,
          body: description.strip,
          external_id: guid.to_s.strip,
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
          notification_id: notification.id,
          body: description.strip,
          external_id: guid.to_s.strip,
          published_at: Time.strptime(pub_date, '%a, %d %b %Y %H:%M:%S %Z'),
          target_url: link,
          title: title
        }
      end
    end
  end
end

puts feed.select(&:present?).to_json
