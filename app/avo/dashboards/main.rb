# frozen_string_literal: true

class Avo::Dashboards::Main < Avo::Dashboards::BaseDashboard
  self.id = "main"
  self.name = "Main Dashboard"

  def cards
    card Avo::Cards::JobLocationsMap, cols: 3, rows: 2
  end
end
