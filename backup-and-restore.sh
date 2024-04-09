#!/bin/bash
set -e
# Set backup directory
BACKUP_DIR=/root/backup_proxmox
mkdir -p $BACKUP_DIR

backup() {
  # Create backup directory
  mkdir -p $BACKUP_DIR

  # Backup root directory - incase custom files or configs
  echo "Backup root directory"
  mkdir -p $BACKUP_DIR/root
  rsync -a --exclude="$BACKUP_DIR" /root/ "$BACKUP_DIR/root/"

  # Backup LXC configs
  echo "Backup LXC configs"
  mkdir -p $BACKUP_DIR/lxc
  pct list | awk 'NR>1{print $1}' > $BACKUP_DIR/lxc/cts.txt
  for ct in $(cat $BACKUP_DIR/lxc/cts.txt); do
    pct config $ct > $BACKUP_DIR/lxc/$ct.conf
  done

  # Backup KVM configs
  echo "Backup KVM configs"
  mkdir -p $BACKUP_DIR/kvm
  qm list | awk 'NR>1{print $1}' > $BACKUP_DIR/kvm/vms.txt
  for vm in $(cat $BACKUP_DIR/kvm/vms.txt); do
    qm config $vm > $BACKUP_DIR/kvm/$vm.conf
  done

  # Backup storage configuration
  echo "Backup storage configuration"
  cat /etc/fstab > $BACKUP_DIR/fstab
  cp /etc/pve/storage.cfg $BACKUP_DIR/storage.cfg
  pvesm status > $BACKUP_DIR/storage_status.txt

  # Backup network configuration
  echo "Backup network configuration"
  mkdir -p $BACKUP_DIR/network
  cp /etc/network/interfaces $BACKUP_DIR/network/
  cp /etc/hostname $BACKUP_DIR/network/
  cp /etc/hosts $BACKUP_DIR/network/

  # Backup templates
  echo "Backup templates"
  mkdir -p $BACKUP_DIR/templates
  cp -r /var/lib/vz/template/cache/ $BACKUP_DIR/templates/
}

restore() {
  # Restore storage configuration
  cp $BACKUP_DIR/storage.cfg /etc/pve/storage.cfg

  # Restore network configuration
  cp $BACKUP_DIR/network/interfaces /etc/network/
  cp $BACKUP_DIR/network/hostname /etc/
  cp $BACKUP_DIR/network/hosts /etc/

  # Restore templates
  cp -r $BACKUP_DIR/templates/cache/ /var/lib/vz/template/

  # Restore LXC containers
  for ct in $(cat $BACKUP_DIR/lxc/cts.txt); do
    conf=$BACKUP_DIR/lxc/$ct.conf
    cp $conf /etc/pve/lxc/
  done

  # Restore KVM virtual machines
  for vm in $(cat $BACKUP_DIR/kvm/vms.txt); do
    conf=$BACKUP_DIR/kvm/$vm.conf
    cp $conf /etc/pve/qemu-server/
  done

  # Zpool and vgscan as required
  echo "Don't forget Zpool import"
  echo "Scanning for available ZFS pools and list them"
  zpool import
  echo "Then run : zpool import pool_name -f"
  echo "We need -f since we changed systems"
  echo "Checking for volume groups with vgscan"
  vgscan
  
}

if [[ "$1" == "--backup" ]]; then
  backup
elif [[ "$1" == "--restore" ]]; then
  restore
else
  echo "Usage: $0 --backup|--restore"
  exit 1
fi
