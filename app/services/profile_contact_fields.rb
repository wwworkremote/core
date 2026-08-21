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
    { name: @user.name, email: @contact["email"], phone: @contact["phone"] }
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
