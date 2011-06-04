module InstanceUtil
  
  ### untested!
  def increase_volume_size(volume_id, add_size)
    snapshot_info = {}
    EC2.describe_volumes.select{|x| x[:aws_id] == volume_id}.each {|vol|
        snapshot_info = {:snapshot => EC2.create_snapshot(vol[:aws_id]),
                         :instance_id => vol[:aws_instance_id],
                         :device => vol[:aws_device],
                         :size => vol[:aws_size], 
                         :zone => vol[:zone]} 
    }
    new_volume = EC2.create_volume(snapshot_info[:snapshot][:aws_id], snapshot_info[:size].to_i + add_size.to_i, snapshot_info[:zone])
    EC2.detach_volume(volume_id)
    EC2.attach_volume(new_volume[:aws_id], snapshot_info[:instance_id], snapshot_info[:device])
    EC2.delete_volume(volume_id)
    
  end
  
  def make_snapshot_of_all_volumes(instance_id)
    label = Label.find_by_aws_id(instance[:aws_instance_id]).label rescue nil
    unless label.blank?
      label.before_snapshot
    end
    snapshots = []
    EC2.describe_volumes.select{|x| x[:aws_attachment_status] == "attached" and x[:aws_instance_id] == instance_id}.each {|vol|
        snapshots << [EC2.create_snapshot(vol[:aws_id]), vol[:aws_device], vol[:aws_size], vol[:zone]] 
    }
    unless label.blank?
      label.after_snapshot
    end
    snapshots
  end

  def delete_snapshot(snapshot_id)
    EC2.delete_snapshot(snapshot_id)
  end

  def delete_old_snapshots(instance_id, num_to_keep)
    @all_snapshots = EC2.describe_snapshots
    snapshots = []
    index_to_keep = -1 - num_to_keep
    EC2.describe_volumes.select{|x| x[:aws_attachment_status] == "attached" and x[:aws_instance_id] == instance_id}.each {|volume|
         @all_snapshots.select{|x| x[:aws_volume_id] == volume[:aws_id]}.sort_by{|x| x[:aws_started_at]}[0..index_to_keep].collect{|x| x[:aws_id]}.each{|snapshot_id|
           delete_snapshot(snapshot_id)
           snapshots << snapshot_id
          }
    }
    snapshots
  end

  def delete_oldest_snapshots(instance_id, num_to_delete = 1)
    return if num_to_delete < 1
    @all_snapshots = EC2.describe_snapshots
    snapshots = []
    EC2.describe_volumes.select{|x| x[:aws_attachment_status] == "attached" and x[:aws_instance_id] == instance_id}.each {|volume|
         snaps = @all_snapshots.select{|x| x[:aws_volume_id] == volume[:aws_id]}.sort_by{|x| x[:aws_started_at]}
         begin
           snaps.values_at(0..num_to_delete - 1).collect{|x| x[:aws_id]}.each{|snapshot_id|
           delete_snapshot(snapshot_id)
           snapshots << snapshot_id
          }
        rescue
          next
        end
    }
    snapshots    
  end


end