# Set ARC max size to 8GB temporarily
echo 8589934592 > /sys/module/zfs/parameters/zfs_arc_max

# Create the ZFS striped pool
zpool create -o ashift=12 -O compression=off zfsraid /dev/sdX /dev/sdX /dev/sdX

# To permanently set the ZFS ARC maximum size to 8 GB on a Linux system, you can use a one-liner that creates or appends to a configuration file in /etc/modprobe.d. This will ensure the setting is applied every time the system boots.

echo "options zfs zfs_arc_max=8589934592" | tee /etc/modprobe.d/zfs.conf  # Max ARC size 8 GB
echo "options zfs zfs_arc_min=2147483648" | tee -a /etc/modprobe.d/zfs.conf  # Min ARC size 2 GB
echo "options zfs zfs_arc_meta_limit=6442450944" | tee -a /etc/modprobe.d/zfs.conf  # 6 GB for metadata / smaller files
echo "options zfs zfs_prefetch_disable=0" | tee -a /etc/modprobe.d/zfs.conf  # Enable prefetch
echo "options zfs zfs_txg_timeout=5" | tee -a /etc/modprobe.d/zfs.conf  # More frequent commits
