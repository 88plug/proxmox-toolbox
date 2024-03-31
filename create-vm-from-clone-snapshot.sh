#Works with Debian12 that has snapshot. 
########REQUIRED#################################################################################
#Change base_id= to set the VM ids to use
#Change snapshot_name= to the snapshot on your base_id to clone to the new VM's
#Change vms= to the vm names you want to use
#Use ./create-vm-from-clone-snapshot.sh --delete to delete any VM's in vms=!
#Recommend you add SSH keys to ~/.ssh/authorized_keys on your base_id VM and include in snapshot!
########REQUIRED#################################################################################

#!/bin/bash
set -e

base_id=100 
snapshot_name="SSHAdded"
vms=(vm1 vm2 vm3)

# Check if the --cleanup flag is provided
if [[ "$1" == "--cleanup" || "$1" == "--delete" ]]; then
  for i in "${!vms[@]}"; do
    vmid=$((base_id+i+1))
    echo "Deleting VM: $vmid"
    qm stop $vmid --skiplock
    qm destroy $vmid
  done
  echo "Cleanup completed. Specified VMs deleted."
  exit 0
fi

function create(){
for i in "${!vms[@]}"; do
  vmid=$((base_id+i+1))
  node_name="node-${vms[i]}"
  # Clone the VM from the snapshot
  qm clone $base_id $vmid --name "$node_name" --snapname $snapshot_name --storage "NVMEFour"
  # Start the VM
  qm start $vmid
done
}
create


# Create inventory.ini file
echo "[nodes]" > inventory.ini

# Retrieve IP addresses and set hostnames
for i in "${!vms[@]}"; do
  vmid=$((base_id+i+1))
  node_name="node-${vms[i]}"

  # Wait for the VM to boot and obtain an IP address
  while true; do
    interfaces=$(qm guest cmd $vmid network-get-interfaces)
    ip_address=$(echo "$interfaces" | grep -oP '192\.168\.\d+\.\d+' | head -n1)
    if [[ -n "$ip_address" ]]; then
      break
    fi
    sleep 5
  done
  # Set the hostname on the VM
  qm guest exec $vmid -- hostnamectl set-hostname "$node_name" > /dev/null
  # Update the /etc/hosts file
  qm guest exec $vmid -- sed -i 's/127.0.1.1.*/127.0.1.1\t'$node_name'/' /etc/hosts > /dev/null
  echo "$node_name: $ip_address"

  # Append the node information to inventory.ini
  echo "$node_name ansible_host=$ip_address ansible_user=root" >> inventory.ini
done
