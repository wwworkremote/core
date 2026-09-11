# frozen_string_literal: true

# LLM::ArtifactGenerator's cover letter was being appended into the
# free-text notes column via string concatenation (a "[GENERATED_COVER_LETTER]"
# marker), same anti-pattern match_score/match_tags fixed for match data --
# a real column so it can be displayed and updated as its own thing.
class AddCoverLetterToUserJobPostings < ActiveRecord::Migration[8.1]
  def change
    add_column :user_job_postings, :cover_letter, :text
  end
end
