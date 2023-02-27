# frozen_string_literal: true

require 'application_system_test_case'

module Blorgh
  class JotsTest < ApplicationSystemTestCase
    setup do
      @jot = blorgh_jots(:one)
    end

    test 'visiting the index' do
      visit jots_url
      assert_selector 'h1', text: 'Jots'
    end

    test 'should create jot' do
      visit jots_url
      click_on 'New jot'

      fill_in 'Data', with: @jot.data
      click_on 'Create Jot'

      assert_text 'Jot was successfully created'
      click_on 'Back'
    end

    test 'should update Jot' do
      visit jot_url(@jot)
      click_on 'Edit this jot', match: :first

      fill_in 'Data', with: @jot.data
      click_on 'Update Jot'

      assert_text 'Jot was successfully updated'
      click_on 'Back'
    end

    test 'should destroy Jot' do
      visit jot_url(@jot)
      click_on 'Destroy this jot', match: :first

      assert_text 'Jot was successfully destroyed'
    end
  end
end
