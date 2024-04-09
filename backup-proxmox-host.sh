#!/bin/bash

# Set backup directory
BACKUP_DIR=/path/to/backup

# Backup LXC configs
mkdir -p $BACKUP_DIR/lxc
pct list | awk 'NR>1{print $1}' > $BACKUP_DIR/lxc/cts.txt
for ct in $(cat $BACKUP_DIR/lxc/cts.txt); do
  pct config $ct > $BACKUP_DIR/lxc/$ct.conf  
done

# Backup KVM configs
mkdir -p $BACKUP_DIR/kvm  
qm list | awk 'NR>1{print $1}' > $BACKUP_DIR/kvm/vms.txt
for vm in $(cat $BACKUP_DIR/kvm/vms.txt); do  
  qm config $vm > $BACKUP_DIR/kvm/$vm.conf
done

# Backup templates
cp -rp /var/lib/vz/template/ $BACKUP_DIR/templates/

# Backup disk configurations
pvesm status > $BACKUP_DIR/storage.txt

# Backup each VM/CT disk  
for storage in $(pvesm status | awk 'NR>1{print $1}'); do
  mkdir -p $BACKUP_DIR/disks/$storage
  cp -rp /var/lib/vz/$storage/* $BACKUP_DIR/disks/$storage/  
done
