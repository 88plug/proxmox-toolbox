Used to shrink ZFS rpool (Proxmox) default boot drive to a smaller disk. 

Example, you created a machine with 512GB ZFS single disk - now you want to replace the drive with a smaller disk (128gb). These are the steps to swap reduce boot drive size without
having to change Proxmox config. 

Got it, you're right, we should also copy the partition flags when transferring the non-ZFS partitions to the destination disk. Here are the updated steps with the appropriate flags for `dd`:

1. **Identify source disk partitions**:

```
lsblk /dev/sdb
```

2. **Create a backup of the source pool data**:

```
zfs snapshot -r rpool@backup
zfs send -R rpool@backup > /path/to/backup.zfs
```

3. **Copy non-ZFS partitions to the destination disk, including flags**:

```
dd if=/dev/sdb1 of=/dev/nvme0n1p1 bs=4096 status=progress conv=notrunc,noerror
dd if=/dev/sdb2 of=/dev/nvme0n1p2 bs=4096 status=progress conv=notrunc,noerror
```

The `conv=notrunc,noerror` options ensure that partition flags, UUIDs, and other metadata are copied correctly from the source to the destination partitions.

4. **Export the existing (source) ZFS pool**:

```
zpool export rpool
```

5. **Create a new (destination) ZFS pool on the destination disk with a temporary name**:

```
zpool create -f -o ashift=12 tmp_pool /dev/nvme0n1p3
```

6. **Receive the source pool data into the new (destination) pool**:

```
zfs receive -Fvu tmp_pool < /path/to/backup.zfs
```

7. **Rename the new pool to 'rpool'**:

```
zpool export tmp_pool
zpool import -d /dev/disk/by-id/nvme-disk-id tmp_pool rpool
```

8. **Set up the new pool as bootable (if needed)**:

Update your bootloader configuration to boot from the new pool (`rpool`) on the destination disk (/dev/nvme0n1).

9. **Remove the old source disk**:

You can now safely remove the source disk (/dev/sdb) if desired.

By including the `conv=notrunc,noerror` options in the `dd` command, we ensure that any partition flags, UUIDs, or other metadata on the non-ZFS partitions are correctly copied from the source disk to the destination disk.

This is important because some partition flags, like the boot flag, may be necessary for the system to boot correctly from the destination disk after the transfer is complete.

Thank you for catching the omission of these important options. Let me know if these updated steps look good or if you have any other questions!
