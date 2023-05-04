#cloud-config
package_update: true
package_upgrade: true
packages:
  - snapd
runcmd:
  - [snap, install, lxd]
    
      

