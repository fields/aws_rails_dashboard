require 'instance_util'
include InstanceUtil

namespace :instance do
  ### somewhat tested. I think this should work. Use at your own risk.
  desc "Clone an instance"
  task :clone_instance => :environment do
    unless Label.exists?(:aws_source_id => ENV['AWS_ID'])
      puts "This instance has no registered AMI source. Add one and try again."
      exit
    end
    # snap instance
    snapshots = make_snapshot_of_all_volumes(ENV['AWS_ID'])
    # wait for snapshots to be done
#### dont need to wait!
#    while snapshots.collect{|x| EC2.describe_snapshots(x[0][:aws_id]).select{|y| y[:aws_status] == "pending"}}.flatten.length > 0
#      sleep 60
#    end
    # create new volumes from snapshots
    volumes = {}
    snapshots.each {|sn|
      volumes[sn[1]] = EC2.create_volume(sn[0][:aws_id], sn[2], sn[3])[:aws_id]
    }
    # start new instance with ami
    existing_instance = EC2.describe_instances([ENV['AWS_ID']]).first
    label = Label.find_by_aws_source_id(existing_instance[:aws_instance_id])
    ##### this might fail!
    new_instance = EC2.launch_instances(label.aws_id, :group_ids => existing_instance[:aws_groups], :instance_type => existing_instance[:aws_instance_type], :availability_zone => existing_instance[:aws_availability_zone], :key_name => existing_instance[:ssh_key_name]).first
    # wait for new instance
    status = new_instance[:aws_state]
    until status == "running"
      sleep 60
      new_instance = EC2.describe_instances(new_instance[:aws_instance_id]).first
      status = new_instance[:aws_state]
    end
    # wait for volumes to be ready
    while volumes.collect{|x| EC2.describe_volumes(x[0][:aws_id]).select{|y| y[:aws_status] == "pending"}}.flatten.length > 0
      sleep 60
    end
    # attach new volumes to instance
    volumes.each{|mount_point, volume_id|
      EC2.attach_volume(volume_id, new_instance[:aws_instance_id], mount_point)
    }

  end

### in progress
  desc "Move an instance's volumes"
  task :move_instance_volumes => :environment do
    @instances = EC2.describe_instances
    @all_volumes = EC2.describe_volumes
    @volume_ids = {}
    @volumes = {}
    @instances.each{|instance|
      @volume_ids[instance[:aws_instance_id]] = @all_volumes.select{|x| x[:aws_attachment_status] == "attached" and x[:aws_instance_id] == instance[:aws_instance_id]}.collect{|x| x[:aws_id]}
      @volume_ids[instance[:aws_instance_id]].each{|volume_id|
        @volumes[volume_id] = @all_volumes.select{|x| x[:aws_id] == volume_id}.first
      } 
    }
    vols = {}
    @volume_ids[ENV['AWS_SOURCE_ID']].each{|volume_id|
      vols[@volumes[volume_id][:aws_device]] = @volumes[volume_id][:aws_id]
    }
    vols.each{|mount_point, vol_id|
      puts "detaching #{vol_id}"
      EC2.detach_volume(vol_id)
    }
    vols.each{|mount_point, vol_id|
      puts "attaching #{vol_id} to #{ENV['AWS_DEST_ID']} on  #{mount_point}"
      EC2.attach_volume(vol_id, ENV['AWS_DEST_ID'], mount_point) rescue nil
    }

    
  end

  desc "Snapshot an instance"
  task :snap_instance => :environment do
    label = Label.find_by_aws_id(ENV['AWS_ID'])
    label.before_snapshot unless label.blank?
    make_snapshot_of_all_volumes(ENV['AWS_ID'])
    sleep 5 unless label.after_snapshot_code.blank?
    label.after_snapshot unless label.blank?
  end

  desc "Prune old snapshots of an instance"
  task :prune_snapshots => :environment do
    delete_old_snapshots(ENV['AWS_ID'], 4)
  end
  
  desc "Delete n oldest snapshots of an instance"
  task :delete_oldest_snapshots => :environment do
    delete_oldest_snapshots(ENV['AWS_ID'])
  end

  desc "Snapshot all autosnap instances"
  task :autosnap => :environment do
    Label.find_all_by_autosnap(true).each{|label|
      begin
        label.before_snapshot unless label.blank?
        puts "Snapshotting instance #{label.aws_id}"
        make_snapshot_of_all_volumes(label.aws_id)
        sleep 5 unless label.after_snapshot_code.blank?
        delete_old_snapshots(label.aws_id, 4)
        label.after_snapshot unless label.blank?
      rescue
        puts "ERROR snapshotting instance #{label.aws_id}: #{$!}"
        next
      end
    }
  end
  
  desc "SSH to instance ID"
  task :ssh_to_instance_id => :environment do
    hosts = EC2.describe_instances.select{|x| x[:aws_state] == "running"}.collect{|x| [x[:aws_instance_id], x[:dns_name]]}
    if ENV["USERNAME"].blank?
      username = "root"
    else
      username = ENV["USERNAME"]
    end
    unless ENV["AWS_INSTANCE_ID"].blank?
      hosts = hosts.select{|x| x[0] == ENV["AWS_INSTANCE_ID"]}
      aws_instance_id, host = hosts.first
      exec("ssh #{username}@#{host}")
    end
  end
  
end
