cluster:
  enabled: true
  server_address: ${ip_address}:8443
  cluster_token: ${join_token}
  member_config:
    - entity: storage-pool
      name: local
      key: size
      value: ${storage_size}GiB
      description: '"size" property for storage pool "local"'
    - entity: storage-pool
      name: local
      key: source
      value: ""