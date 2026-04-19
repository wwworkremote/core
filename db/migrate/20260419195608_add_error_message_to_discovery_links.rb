class AddErrorMessageToDiscoveryLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :discovery_links, :error_message, :text
  end
end
