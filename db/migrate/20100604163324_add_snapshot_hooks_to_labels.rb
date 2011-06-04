class AddSnapshotHooksToLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :before_snapshot_code, :text
    add_column :labels, :after_snapshot_code, :text
  end

  def self.down
    remove_column :labels, :after_snapshot_code
  end
end
