# Set ARC max size to 8GB temporarily
echo 8589934592 > /sys/module/zfs/parameters/zfs_arc_max

# Create the ZFS striped pool
zpool create -o ashift=12 -O compression=off zfsraid /dev/sdX /dev/sdX /dev/sdX

# To permanently set the ZFS ARC maximum size to 8 GB on a Linux system, you can use a one-liner that creates or appends to a configuration file in /etc/modprobe.d. This will ensure the setting is applied every time the system boots.
echo "options zfs zfs_arc_max=8589934592" | tee /etc/modprobe.d/zfs.conf
