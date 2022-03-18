#!/bin/bash
yum update -y
sudo mkfs -t xfs /dev/xvdb
sudo mkdir /data
sudo mount /dev/xvdb /data
id=$(blkid|grep xvdb|cut -d " " -f 2|cut -d "=" -f 2)
echo "UUID=${id:1:-1}  /data  xfs  defaults,nofail  0  2" >> /etc/fstab
yum -y install iscsi-initiator-utils
systemctl enable --now iscsid
