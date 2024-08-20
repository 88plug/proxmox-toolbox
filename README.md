# proxmox-toolbox


## Fix clones not getting new dhcp

rm /etc/machine-id
systemd-machine-id-setup

best : 

sudo truncate -s 0 /etc/machine-id
