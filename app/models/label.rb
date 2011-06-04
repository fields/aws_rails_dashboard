class Label < ActiveRecord::Base
  def before_snapshot
    eval self.before_snapshot_code unless self.before_snapshot_code.blank?
  end
  
  def after_snapshot
    eval self.after_snapshot_code unless self.after_snapshot_code.blank?
  end

end
