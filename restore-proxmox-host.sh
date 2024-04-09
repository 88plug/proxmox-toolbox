#!/bin/bash

# Set backup directory
BACKUP_DIR=/path/to/backup

# Restore storage configuration
while read line; do
  eval "pvesm add $line"
done < $BACKUP_DIR/storage.txt

# Restore templates
cp -rp $BACKUP_DIR/templates/* /var/lib/vz/template/

# Restore disk images
for storage in $(ls $BACKUP_DIR/disks); do
  cp -rp $BACKUP_DIR/disks/$storage/* /var/lib/vz/$storage/
done

# Restore LXC containers
for ct in $(cat $BACKUP_DIR/lxc/cts.txt); do
  pct create $ct --ostemplate local:vztmpl/$(grep -Po '(?<=local:vztmpl/)[^,]*' $BACKUP_DIR/lxc/$ct.conf) --hostname $(grep -Po '(?<=hostname: )[^,]*' $BACKUP_DIR/lxc/$ct.conf) --cores $(grep -Po '(?<=cores: )[^,]*' $BACKUP_DIR/lxc/$ct.conf) --memory $(grep -Po '(?<=memory: )[^,]*' $BACKUP_DIR/lxc/$ct.conf) --swap $(grep -Po '(?<=swap: )[^,]*' $BACKUP_DIR/lxc/$ct.conf) --net0 $(grep -Po '(?<=net0: )[^,]*' $BACKUP_DIR/lxc/$ct.conf) --storage $(grep -Po '(?<=rootfs: )[^,]*' $BACKUP_DIR/lxc/$ct.conf | awk '{print $1}') --rootfs $(grep -Po '(?<=rootfs: )[^,]*' $BACKUP_DIR/lxc/$ct.conf | awk '{print $2}')
done

# Restore KVM virtual machines
for vm in $(cat $BACKUP_DIR/kvm/vms.txt); do
  qm create $vm --name $(grep -Po '(?<=name: )[^,]*' $BACKUP_DIR/kvm/$vm.conf) --cores $(grep -Po '(?<=cores: )[^,]*' $BACKUP_DIR/kvm/$vm.conf) --memory $(grep -Po '(?<=memory: )[^,]*' $BACKUP_DIR/kvm/$vm.conf) --net0 $(grep -Po '(?<=net0: )[^,]*' $BACKUP_DIR/kvm/$vm.conf)
  for disk in $(grep -Po '(?<=virtio)[0-9]+' $BACKUP_DIR/kvm/$vm.conf); do
    qm set $vm --virtio$disk $(grep -Po "(?<=virtio${disk}: ).*" $BACKUP_DIR/kvm/$vm.conf)
  done
done
