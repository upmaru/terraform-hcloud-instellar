config:
  cluster.https_address: ${ip_address}:8443
  core.https_address: "[::]:8443"
networks:
- config:
    bridge.mode: fan
    fan.underlay_subnet: 10.0.0.0/16
  description: ""
  name: lxdfan0
  type: ""
  project: default
storage_pools:
- config:
    size: ${storage_size}GiB
  description: ""
  name: local
  driver: zfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdfan0
      type: nic
    root:
      path: /
      pool: local
      type: disk
  name: default
projects: []
cluster:
  server_name: ${server_name}
  enabled: true