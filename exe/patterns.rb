#!/usr/bin/env /Users/mike/projects/outlier_jobs/rails runner
# frozen_string_literal: true


feed = Notifications::RequestFaraday.find_each.flat_map do |notification|
  payload = notification.payload.deep_symbolize_keys

  case payload
  in response_body: String | Array
    nil

  in response_body: { by: String => by, id: Integer => id, text: String => text, title: String => title, type: String => type, time: Integer => time, score: Integer } if type == 'job'

    {
      external_id: id,
      published_at: Time.at(time, in: 'UTC').utc,
      title: title.strip,
      body: text.strip,
      external_author_id: by
    }
  in response_body: { by: String => by, id: Integer => id, url: String => url, time: Integer => time, type: String => type, score: Integer, title: String => title } if type == 'job'

    {
      external_id: id,
      published_at: Time.at(time, in: 'UTC').utc,
      target_url: url,
      title: title.strip,
      external_author_id: by
    }

  in response_body: { by: String => by, id: Integer => id, url: String => url, time: Integer => time, type: String => type, score: Integer, title: String => title, text: String => text } if type == 'job'

    {
      external_id: id,
      published_at: Time.at(time, in: 'UTC').utc,
      target_url: url,
      title: title.strip,
      body: text.strip,
      external_author_id: by
    }

  # Filter for RSS job postings
  in response_body: { rss: { channel: { item: [*items] } } }
    items.flat_map do |item|
      case item
      in { guid: { __content__: String => guid }, pubDate: String => pub_date, link: String => link, title: String => title, description: String => description }

        {
          external_id: guid,
          published_at: Time.strptime(pub_date, '%a, %d %b %Y %H:%M:%S %Z'),
          target_url: link,
          title: title.strip,
          body: description.strip
        }
      in { guid: String => guid, pubDate: String => pub_date, link: String => link, title: String => title, description: String => description }

        {
          external_id: guid,
          published_at: Time.strptime(pub_date, '%a, %d %b %Y %H:%M:%S %Z'),
          target_url: link,
          title: title,
          body: description.strip
        }
      end
    end
  end
end

ap feed
ap Notifications::RequestFaraday.count
ap feed.size
