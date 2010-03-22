class AddAutosnapToLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :autosnap, :boolean
  end

  def self.down
    remove_column :labels, :autosnap
  end
end
