#!/bin/bash

# Variables
TARGET_POOL="akash"  # Rename akash to a variable
CACHE_POOL_NAME="speedpass"  # Cache pool name

# Function to create RAM drive or use NVMe device
create_storage() {
    if [[ "$1" == "--ramdrive" ]]; then
        # Create a RAM drive of 128GB
        sudo mkdir -p /mnt/ramdrive
        sudo mount -t tmpfs -o size=128G tmpfs /mnt/ramdrive
        echo "RAM drive created at /mnt/ramdrive."
        STORAGE_PATH="/mnt/ramdrive"
    elif [[ "$1" == "--nvme" ]]; then
        # Use specified NVMe device
        sudo mkfs.ext4 -F "$2"
        sudo mkdir -p /mnt/nvme
        sudo mount "$2" /mnt/nvme
        echo "NVMe device $2 mounted at /mnt/nvme."
        STORAGE_PATH="/mnt/nvme"
    else
        echo "Invalid storage option. Use --ramdrive or --nvme /dev/nvme0n1."
        exit 1
    fi
}

# Function to create fstab entry
create_fstab_entry() {
    # Add fstab entry for RAM drive or NVMe device
    echo "$1   $STORAGE_PATH   $1   defaults   0 0" | sudo tee -a /etc/fstab
    echo "Fstab entry for $1 created."
}

# Function to create cache pool
create_cache_pool() {
    # Add cache pool
    sudo ceph osd lspools
    sudo ceph osd pool create "$CACHE_POOL_NAME" 32  # Use CACHE_POOL_NAME variable

    # Set up cache pool as a tier
    sudo ceph osd tier add "$TARGET_POOL" "$CACHE_POOL_NAME"  # Use TARGET_POOL and CACHE_POOL_NAME variables
    sudo ceph osd tier cache-mode "$CACHE_POOL_NAME" writeback
    sudo ceph osd tier set-overlay "$TARGET_POOL" "$CACHE_POOL_NAME"

    # Configure caching parameters
    sudo ceph osd pool set "$CACHE_POOL_NAME" hit_set_type bloom
    sudo ceph osd pool set "$CACHE_POOL_NAME" hit_set_count 12
    sudo ceph osd pool set "$CACHE_POOL_NAME" hit_set_period 14400
    sudo ceph osd pool set "$CACHE_POOL_NAME" target_max_bytes 1099511627776
    sudo ceph osd pool set "$CACHE_POOL_NAME" target_max_objects 1000000
    sudo ceph osd pool set "$CACHE_POOL_NAME" min_read_recency_for_promote 2
    sudo ceph osd pool set "$CACHE_POOL_NAME" min_write_recency_for_promote 2
    sudo ceph osd pool set "$CACHE_POOL_NAME" cache_target_dirty_ratio 0.4
    sudo ceph osd pool set "$CACHE_POOL_NAME" cache_target_dirty_high_ratio 0.6
    sudo ceph osd pool set "$CACHE_POOL_NAME" cache_target_full_ratio 0.8
    sudo ceph osd pool set "$CACHE_POOL_NAME" cache_min_flush_age 600
    sudo ceph osd pool set "$CACHE_POOL_NAME" cache_min_evict_age 1800

    # Remove cache pool overlay temporarily
    sudo ceph osd tier cache-mode "$CACHE_POOL_NAME" readproxy

    # Wait for cache to flush
    # You can also monitor using `sudo rados -p "$CACHE_POOL_NAME" ls`
}

# Function to delete storage
delete_storage() {
    # Unmount and remove the storage
    sudo umount "$STORAGE_PATH"
    sudo rm -rf "$STORAGE_PATH"
    echo "Storage at $STORAGE_PATH removed."
}

# Function to delete fstab entry
delete_fstab_entry() {
    # Remove fstab entry for storage
    sudo sed -i "/$1/d" /etc/fstab
    echo "Fstab entry for $1 removed."
}

# Function to delete cache pool
delete_cache_pool() {
    # Remove cache pool overlay
    sudo ceph osd tier remove-overlay "$TARGET_POOL"

    # Remove cache pool tier
    sudo ceph osd tier remove "$TARGET_POOL" "$CACHE_POOL_NAME"

    # Delete cache pool
    sudo ceph tell mon.* injectargs '--mon-allow-pool-delete=true'
    sudo ceph osd pool delete "$CACHE_POOL_NAME" "$CACHE_POOL_NAME" --yes-i-really-really-mean-it
    sudo ceph tell mon.* injectargs '--mon-allow-pool-delete=false'
    echo "Cache pool '$CACHE_POOL_NAME' deleted successfully."
}

# Function to add node capacity to cache pool
add_node_capacity() {
    if ! sudo ceph osd tier find "$TARGET_POOL" "$CACHE_POOL_NAME" | grep -q "$CACHE_POOL_NAME"; then
        sudo ceph osd tier add "$TARGET_POOL" "$CACHE_POOL_NAME"
        echo "Node's capacity added to cache pool."
    else
        echo "Node's capacity already added to cache pool."
    fi
}

# Main script
case "$1" in
    --create)
        create_storage "$2" "$3"
        create_fstab_entry "$2"
        create_cache_pool
        echo "Cache setup completed successfully."
        ;;
    --teardown)
        delete_cache_pool
        delete_storage
        delete_fstab_entry "$2"
        echo "Cache teardown completed successfully."
        ;;
    --node)
        create_storage "$2" "$3"
        create_fstab_entry "$2"
        add_node_capacity
        echo "Node setup completed successfully."
        ;;
    *)
        echo "Usage: $0 {--create [--ramdrive | --nvme /dev/nvme0n1] | --teardown [--ramdrive | --nvme /dev/nvme0n1] | --node [--ramdrive | --nvme /dev/nvme0n1]}"
        exit 1
        ;;
esac
