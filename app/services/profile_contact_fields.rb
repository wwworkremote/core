# frozen_string_literal: true

# Flattens User + CareerProfile#contact_info/#location_info into the
# copy-paste field set the extension's application assist (TASK-78) shows
# next to a Greenhouse form's name/email/phone/links/location inputs.
class ProfileContactFields
  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
    @profile = user.career_profile
    @contact = @profile&.contact_info || {}
  end

  def call
    basic_fields.merge(url_fields).merge(location_fields)
  end

  private

  def basic_fields
    name = structured_name
    { name: @user.name, **name, email: @contact["email"], phone: @contact["phone"],
      address_line1: @contact["address_line1"], postal_code: @contact["postal_code"],
      phone_country_code: @contact["phone_country_code"], phone_area_code: @contact["phone_area_code"],
      phone_number: @contact["phone_number"] }
  end

  # Canonical resume exports have used both flat contact keys and a nested
  # name_parts object over time. Preserve either shape, and only fall back to
  # the display name for first/last; guessing a middle or preferred name is
  # worse than leaving the field for explicit review.
  def structured_name
    parts = @contact["name_parts"] || @contact["name"]
    parts = {} unless parts.is_a?(Hash)
    first = @contact["legal_first_name"] || parts["first"] || parts["first_name"]
    middle = @contact["legal_middle_name"] || parts["middle"] || parts["middle_name"]
    last = @contact["legal_last_name"] || parts["last"] || parts["last_name"]
    display_parts = @user.name.to_s.split
    first ||= display_parts.first
    last ||= display_parts.drop(1).last if display_parts.length > 1

    { first_name: first, middle_name: middle, last_name: last,
      preferred_name: @contact["preferred_name"] || parts["preferred_name"] }
  end

  def url_fields
    {
      github_url: @profile&.github_url || @contact.dig("github", "url"),
      linkedin_url: @contact.dig("linkedin", "url"),
      website_url: @contact.dig("website", "url")
    }
  end

  # Plenty of ATS forms split the address into City / State / Country rather
  # than taking one combined string, and location_info already stores those
  # parts -- only `display` was being surfaced, so the split fields had to be
  # retyped from memory every time.
  def location_fields
    location = @profile&.location_info || {}

    { location: location["display"], city: location["locality"],
      state: location["region"], country: location["country"] }
  end
end
