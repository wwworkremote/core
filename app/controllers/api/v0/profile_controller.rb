# frozen_string_literal: true

class Api::V0::ProfileController < ApiController
  def show
    render json: ProfileContactFields.call(User.first)
  end

  def update
    user = User.first
    profile = user.career_profile || user.create_career_profile!
    contact = (profile.contact_info || {}).deep_dup
    permitted = params.expect(profile: %i[first_name middle_name last_name preferred_name email address_line1
                                          postal_code phone_country_code phone_area_code phone_number])
    %i[email address_line1 postal_code phone_country_code phone_area_code phone_number].each do |key|
      contact[key.to_s] = permitted[key] if permitted.key?(key)
    end
    contact["legal_first_name"] = permitted[:first_name] if permitted.key?(:first_name)
    contact["legal_middle_name"] = permitted[:middle_name] if permitted.key?(:middle_name)
    contact["legal_last_name"] = permitted[:last_name] if permitted.key?(:last_name)
    contact["preferred_name"] = permitted[:preferred_name] if permitted.key?(:preferred_name)
    profile.update!(contact_info: contact)
    render json: ProfileContactFields.call(user)
  end
end
