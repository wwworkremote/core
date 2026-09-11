# frozen_string_literal: true

class Admin::JobSourcesController < Admin::ApplicationController
  def mark_not_interested
    source = Source.find(params.expect(:id))
    source.mark_not_interested!

    redirect_back_or_to(job_postings_path,
                        notice: "Marked all open #{source.origin&.name || source.name} postings not interested.")
  end
end
