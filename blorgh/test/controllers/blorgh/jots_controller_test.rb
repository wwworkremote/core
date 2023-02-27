# frozen_string_literal: true

require 'test_helper'

module Blorgh
  class JotsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @jot = blorgh_jots(:one)
    end

    test 'should get index' do
      get jots_url
      assert_response :success
    end

    test 'should get new' do
      get new_jot_url
      assert_response :success
    end

    test 'should create jot' do
      assert_difference('Jot.count') do
        post jots_url, params: { jot: { data: @jot.data } }
      end

      assert_redirected_to jot_url(Jot.last)
    end

    test 'should show jot' do
      get jot_url(@jot)
      assert_response :success
    end

    test 'should get edit' do
      get edit_jot_url(@jot)
      assert_response :success
    end

    test 'should update jot' do
      patch jot_url(@jot), params: { jot: { data: @jot.data } }
      assert_redirected_to jot_url(@jot)
    end

    test 'should destroy jot' do
      assert_difference('Jot.count', -1) do
        delete jot_url(@jot)
      end

      assert_redirected_to jots_url
    end
  end
end
