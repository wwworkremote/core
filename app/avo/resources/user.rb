# frozen_string_literal: true

class Avo::Resources::User < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> { query.ransack(id_eq: q, name_cont: q, email_cont: q, m: "or").result(distinct: false) }
  }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :slug, as: :text
    field :email, as: :text
    field :sign_in_count, as: :number
    field :current_sign_in_at, as: :date_time
    field :last_sign_in_at, as: :date_time
    field :current_sign_in_ip, as: :text
    field :last_sign_in_ip, as: :text
    field :confirmation_token, as: :text
    field :confirmed_at, as: :date_time
    field :confirmation_sent_at, as: :date_time
    field :unconfirmed_email, as: :text
    field :failed_attempts, as: :number
    field :unlock_token, as: :text
    field :locked_at, as: :date_time
    field :messages, as: :has_many
  end
end
