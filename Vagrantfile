# -*- mode: ruby -*-
# vi: set ft=ruby :


vagrant_dir = File.expand_path(File.dirname(__FILE__))

# Vagrantfile.custom contains user customization for the Vagrantfile
# You shouldn't have to edit the Vagrantfile, ever.
if File.exists?(File.join(vagrant_dir, 'Vagrantfile.custom'))
  eval(IO.read(File.join(vagrant_dir, 'Vagrantfile.custom')), binding)
end

NB_NODES ||= 5
FILE_SIZE ||= 1000
EMULATE_LATENCY ||= false
LINK_LATENCY ||= 50
JITTER ||= 1

LATENCY = LINK_LATENCY/2


Vagrant.configure("2") do |config|

  config.vm.box = "hashicorp/precise64"

  config.vm.box_check_update = false

  (0..(NB_NODES-1)).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "#{i}"
      node.vm.network "private_network", ip: "192.168.1.1#{i}" # eth1

      net_interface = "eth1"

      if EMULATE_LATENCY
        node.vm.provision "shell", inline: <<-SHELL
          NET_INTERFACE=\"#{net_interface}\"
          echo emulating network latency #{LINK_LATENCY}ms
          tc qdisc add dev $NET_INTERFACE root netem delay #{LATENCY}ms #{JITTER}ms distribution normal
        SHELL
      end

      node.vm.provision "shell", inline: <<-SHELL
        cp /vagrant/go-ipfs/ipfs /usr/local/sbin
        ipfs version --all
      SHELL

      node.vm.provision "shell", privileged: false, inline: <<-SHELL
        ipfs init
        ipfs bootstrap rm --all > /dev/null
        ipfs daemon &
        sleep 2
      SHELL


      net_script = <<-SHELL

        NET_INTERFACE=\"#{net_interface}\"

        get_network_data() {
          NET_STAT_PATH="/sys/class/net/$NET_INTERFACE/statistics"
          curr_tx_bytes=`cat $NET_STAT_PATH/tx_bytes`
          curr_rx_bytes=`cat $NET_STAT_PATH/rx_bytes`
        }
        save_prev_network_data() {
          prev_tx_bytes=$curr_tx_bytes
          prev_rx_bytes=$curr_rx_bytes
        }
        calc_diff_network_data() {
          diff_tx_bytes=$((curr_tx_bytes-prev_tx_bytes))
          diff_rx_bytes=$((curr_rx_bytes-prev_rx_bytes))
        }
      SHELL

      global_vars = %Q{
        addr_file=/vagrant/addr.txt
        hash_file=/vagrant/file_hash.txt
        stats_file=/vagrant/stats.txt
        stats_csv=/vagrant/stats.csv
      }

      if i == 0
        script = %Q{ #{global_vars}
          ipfs id -f=\"<addrs>\n\" | grep 192.168.1 > $addr_file
          dd if=/dev/urandom of=urand bs=1MB count=#{FILE_SIZE}
          ipfs add -q urand > $hash_file
          rm -f $stats_file
          echo "#" node_index,elapsed_time,received_bytes,repo_size > $stats_csv
        }
      else
        script = %Q{ #{net_script} #{global_vars}
          cat $addr_file | ipfs bootstrap add
          cat $addr_file | ipfs swarm connect
          ipfs id -f=\"<addrs>\n\" | grep 192.168.1 >> $addr_file

          echo pull data..
          get_network_data
          /usr/bin/time -o /tmp/tm -f "%e" ipfs cat `cat $hash_file` > /tmp/out 2> /dev/null
          save_prev_network_data
          get_network_data
          calc_diff_network_data

          elapsed=`cat /tmp/tm`

          repo_size=`ipfs repo stat | grep RepoSize | awk '{print $2}'`
          # repo_size=`"scale=2; $(repo_size) / 1024^2" | bc`
          repo_size=`echo $repo_size | awk '{$1/=1024; $1/=1024; $1/=1024; printf "%.2f",$1}'`
          # rx_bytes=`"scale=2; $(diff_rx_bytes) / 1024^2" | bc`
          rx_bytes=`echo $diff_rx_bytes | awk '{$1/=1024; $1/=1024; $1/=1024; printf "%.2f",$1}'`

          echo "---" $(hostname) >> $stats_file
          ipfs repo stat | grep RepoSize >> $stats_file
          ipfs stats bw | grep TotalIn >> $stats_file

          echo $(hostname),$elapsed,$rx_bytes,$repo_size >> $stats_csv
          echo done
        }
      end

      node.vm.provision "shell", privileged: false, inline: script

    end
  end
end
