# frozen_string_literal: true

class Api::V0::GeoController < ApiController
  def index
    @geo = lookup_by_ip(resolved_ip)
  end

  private

  def resolved_ip
    ip = params[:ip].to_s.strip
    ip = nil if ip.empty?
    ip || request.remote_ip
  end

  def lookup_by_ip(ip)
    return { message: "You didn't supply an IP to geocode." } unless ip

    geocode(ip)
  end

  def geocode(ip)
    GEOIP.city(ip) || { ip: ip }
  rescue StandardError => e
    Rails.logger.warn("[GeoController] geoip_lookup_error=#{e.class} ip=#{ip.inspect} message=#{e.message.inspect}")
    { ip: ip }
  end
end
