# frozen_string_literal: true

class CreateLLMChats < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_chats, &:timestamps
  end
end
