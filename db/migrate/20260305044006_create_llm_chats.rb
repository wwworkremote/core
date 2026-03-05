# frozen_string_literal: true

class CreateLlmChats < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_chats, &:timestamps
  end
end
