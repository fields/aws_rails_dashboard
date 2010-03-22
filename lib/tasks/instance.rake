require 'instance_util'
include InstanceUtil

namespace :instance do
  ### somewhat tested. I think this should work. Use at your own risk.
  desc "Clone an instance"
  task :clone_instance => :environment do
    unless Label.exists? (:aws_source_id => ENV['AWS_ID'])
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
  desc "Snapshot an instance"
  task :snap_instance => :environment do
    make_snapshot_of_all_volumes(ENV['AWS_ID'])
  end

  desc "Prune old snapshots of an instance"
  task :prune_snapshots => :environment do
    delete_old_snapshots(ENV['AWS_ID'], 2)
  end

  desc "Snapshot all autosnap instances"
  task :autosnap => :environment do
    Label.find_all_by_autosnap(true).each{|label|
      puts "Snapshotting instance #{label.aws_id}"
      make_snapshot_of_all_volumes(label.aws_id)
      delete_old_snapshots(label.aws_id, 2)
    }
  end

end