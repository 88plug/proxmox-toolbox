# Scenario : You want to move a disk(osd) that is part of a ceph cluster to another physical machine.  

### 1. Stop / Out the OSD/drive you want to move
### 2. Physically move drive to new node
### 3. In Proxmox, goto the node with the new drive > Open a shell and type:
```
pvscan
ceph-volume lvm activate --all
```
## 4. Have some patience, it can take at least 30 seconds - after some time, check Ceph > OSD (reload) and you should see the OSD's start to appear on the new node!
