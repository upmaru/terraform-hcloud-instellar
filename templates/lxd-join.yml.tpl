cluster:
  enabled: true
  server_address: ${ip_address}:8443
  cluster_token: ${join_token}
  member_config:
  - entity: storage-pool
    name: local
    key: source
    value: ""