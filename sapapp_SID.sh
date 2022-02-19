#!/bin/bash

set -x

# define log directory and log file
log_directory=/var/log
log_file=${log_directory}/${0}.log

# set timezone
echo $(date) INFO set timezone >> ${log_file}
timedatectl set-timezone Europe/Dublin

# install packages
# only works when the OS image is PAYG and VM is successfully registered to SUSE Cloud Update Infrastructure
echo $(date) INFO install packages >> ${log_file}
zypper install -y saptune

# configure saptune
# only works when the OS image is PAYG and VM is successfully registered to SUSE Cloud Update Infrastructure
echo $(date) INFO configure saptune >> ${log_file}
saptune solution apply NETWEAVER
saptune service takeover

# create SAP directories
echo $(date) INFO create SAP directories >> ${log_file}
mkdir /usr/sap
mkdir /sapmnt

# create swap space via cloud-init per-boot script
# 1597355 - Swap-space recommendation for Linux
# SAP Application Server: swap file=64GiB
echo $(date) INFO create swap space >> ${log_file}
touch /var/lib/cloud/scripts/per-boot/create_swapfile.sh
cat >> /var/lib/cloud/scripts/per-boot/create_swapfile.sh <<EOF
#!/bin/sh
if [ ! -f "/mnt/swapfile" ]; then
fallocate --length 64GiB /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile; fi
swapon /mnt/swapfile
EOF
chmod +x /var/lib/cloud/scripts/per-boot/create_swapfile.sh
sh /var/lib/cloud/scripts/per-boot/create_swapfile.sh

# do not delete this sleep, otherwise pvcreate may fail!
sleep 10

# create pyhsical volumes
echo $(date) INFO create physical volumes >> ${log_file}
for i in 0; do 
  pvcreate /dev/disk/azure/scsi1/lun${i}
done

vg_sap=vgsap
lv_usrsap=lvusrsap
lv_sapmnt=lvsapmnt

# create volume groups
echo $(date) INFO create volume groups >> ${log_file}
vgcreate ${vg_sap} -s 16 /dev/disk/azure/scsi1/lun0
lvcreate -l 50%FREE -n ${lv_usrsap} ${vg_sap}
lvcreate -l 50%FREE -n ${lv_sapmnt} ${vg_sap}

# create filesystems
echo $(date) INFO create filesystems >> ${log_file}
mkfs.xfs /dev/$vg_sap/$lv_usrsap
mkfs.xfs /dev/$vg_sap/$lv_sapmnt

# mount filesystems
echo $(date) INFO mount filesystems >> ${log_file}
mount /dev/${vg_sap}/${lv_usrsap} /usr/sap
mount /dev/${vg_sap}/${lv_sapmnt} /sapmnt

# adapt /etc/fstab
echo $(date) INFO adapt /etc/fstab >> ${log_file}
cp /etc/fstab /etc/fstab.changedby_${0}
echo "/dev/mapper/${vg_sap}-${lv_usrsap} /usr/sap xfs defaults,nofail 1 2" >> /etc/fstab
echo "/dev/mapper/${vg_sap}-${lv_sapmnt} /sapmnt xfs defaults,nofail 1 2" >> /etc/fstab

# adapt /etc/hosts file using instance metadata api
echo $(date) INFO adapt /etc/hosts >> ${log_file}
cp /etc/hosts /etc/hosts.changedby_${0}
virtualMachineIP=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text")
virtualMachineName=$(hostname)
virtualMachineNameFQDN=${virtualMachineName}.contoso.com
cat >>/etc/hosts <<EOF
${virtualMachineIP} ${virtualMachineNameFQDN} ${virtualMachineName}
EOF
