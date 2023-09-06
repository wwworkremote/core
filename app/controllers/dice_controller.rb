# frozen_string_literal: true

class DiceController < ApplicationController
  def roll = render(json: rand(1..6).to_s)
end
