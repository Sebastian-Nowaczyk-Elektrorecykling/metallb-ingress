# Rook storage notes

The Ceph cluster values live in:

```text
infrastructure/rook-ceph-cluster/values.yaml
```

The default in this repo is intentionally visible and easy to change:

```yaml
storage:
  useAllNodes: true
  useAllDevices: true
```

This is convenient for a lab with dedicated empty disks, but dangerous on mixed-use machines. Before first sync, change it to explicit nodes/devices when needed.

Example shape:

```yaml
storage:
  useAllNodes: false
  useAllDevices: false
  nodes:
    - name: talos-worker-1
      devices:
        - name: /dev/disk/by-id/ata-YOUR_DISK_ID
    - name: talos-worker-2
      devices:
        - name: /dev/disk/by-id/ata-YOUR_DISK_ID
    - name: talos-worker-3
      devices:
        - name: /dev/disk/by-id/ata-YOUR_DISK_ID
```

The repo creates these storage classes:

```text
rook-ceph-block
rook-ceph-filesystem
```

CloudNativePG and Gitea currently use `rook-ceph-block`.
