#!/bin/bash

set -x

# input parameters
HANASID=${1}
HANAInstanceNumber=${2}
SAPMediaStore_container=${3}
SAPMediaStore_sas=${4}
OSadminUserName=${5}
OSadminPassword=${6}

# define log directory and log file
log_directory=/var/log
log_file=${log_directory}/${0}.log

# echo input parameters to log file for testing and debugging. delete the log file after successful deployment
echo $(date) INFO print input parameters >> ${log_file}
echo $(date) INFO HANASID=${HANASID} >> ${log_file}
echo $(date) INFO HANAInstanceNumber=${HANAInstanceNumber} >> ${log_file}
echo $(date) INFO SAPMediaStore_container=${SAPMediaStore_container} >> ${log_file}
echo $(date) INFO SAPMediaStore_sas=${SAPMediaStore_sas} >> ${log_file}
echo $(date) INFO OSadminUserName=${OSadminUserName} >> ${log_file}
echo $(date) INFO OSadminPassword=${OSadminPassword} >> ${log_file}

# set timezone
echo $(date) INFO set timezone >> ${log_file}
timedatectl set-timezone Europe/Dublin

# install packages
# only works when the OS image is PAYG and VM is successfully registered to SUSE Cloud Update Infrastructure
echo $(date) INFO install packages. See SAP Note 2886607 >> ${log_file}
# 2886607 - Linux: Running SAP applications compiled with GCC 9.x
zypper install -y libgcc_s1 libstdc++6 libatomic1
zypper install -y saptune

# configure saptune
# only works when the OS image is PAYG and VM is successfully registered to SUSE Cloud Update Infrastructure
echo $(date) INFO configure saptune >> ${log_file}
saptune solution apply HANA
saptune service takeover

# create SAP directories
echo $(date) INFO create SAP directories >> ${log_file}
mkdir /usr/sap
mkdir -p /hana/data
mkdir -p /hana/log
mkdir -p /hana/shared
mkdir -p /hana/backup

# create swap space via cloud-init per-boot script
# SAP HANA Database Server: swap file=2GiB
echo $(date) INFO create swap space >> ${log_file}
touch /var/lib/cloud/scripts/per-boot/create_swapfile.sh
cat >> /var/lib/cloud/scripts/per-boot/create_swapfile.sh <<EOF
#!/bin/sh
if [ ! -f "/mnt/swapfile" ]; then
fallocate --length 2GiB /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile; fi
swapon /mnt/swapfile
EOF
chmod +x /var/lib/cloud/scripts/per-boot/create_swapfile.sh
sh /var/lib/cloud/scripts/per-boot/create_swapfile.sh

# do not delete this sleep, otherwise pvcreate may fail!
sleep 10

# create pyhsical volumes from LUN0 to LUN9
echo $(date) INFO create physical volumes >> ${log_file}
for i in 9; do 
  pvcreate /dev/disk/azure/scsi1/lun${i}
  sleep 1
done

vg_sap=vgsap; lv_usrsap=lvusrsap
vg_hanadata=vgdata; lv_hanadata=lvdata
vg_hanalog=vglog; lv_hanalog=lvlog
vg_hanashared=vgshared; lv_hanashared=lvshared
vg_hanabackup=vgbackup; lv_hanabackup=lvbackup

# create volume groups and logical volumes
echo $(date) INFO create volume groups >> ${log_file}
vgcreate ${vg_sap} -s 16 /dev/disk/azure/scsi1/lun0
lvcreate -l 50%FREE -n ${lv_usrsap} ${vg_sap}
vgcreate ${vg_hanadata} -s 16 /dev/disk/azure/scsi1/lun1 /dev/disk/azure/scsi1/lun2 /dev/disk/azure/scsi1/lun3 /dev/disk/azure/scsi1/lun4
lvcreate -l 100%FREE --stripes 4 --stripesize 256 -n ${lv_hanadata} ${vg_hanadata}
vgcreate ${vg_hanalog} -s 16 /dev/disk/azure/scsi1/lun5 /dev/disk/azure/scsi1/lun6 /dev/disk/azure/scsi1/lun7
lvcreate -l 100%FREE --stripes 3 --stripesize 64 -n ${lv_hanalog} ${vg_hanalog}
vgcreate ${vg_hanashared} -s 16 /dev/disk/azure/scsi1/lun8
lvcreate -l 100%FREE -n ${lv_hanashared} ${vg_hanashared}
vgcreate ${vg_hanabackup} -s 16 /dev/disk/azure/scsi1/lun9
lvcreate -l 100%FREE -n ${lv_hanabackup} ${vg_hanabackup}

# create filesystems
echo $(date) INFO create filesystems >> ${log_file}
mkfs.xfs /dev/${vg_sap}/${lv_usrsap}
mkfs.xfs /dev/${vg_hanadata}/${lv_hanadata}
mkfs.xfs /dev/${vg_hanalog}/${lv_hanalog}
mkfs.xfs /dev/${vg_hanashared}/${lv_hanashared}
mkfs.xfs /dev/${vg_hanabackup}/${lv_hanabackup}

# mount filesystems
echo $(date) INFO mount filesystems >> ${log_file}
mount /dev/${vg_sap}/${lv_usrsap} /usr/sap
mount /dev/${vg_hanadata}/${lv_hanadata} /hana/data
mount /dev/${vg_hanalog}/${lv_hanalog} /hana/log
mount /dev/${vg_hanashared}/${lv_hanashared} /hana/shared
mount /dev/${vg_hanabackup}/${lv_hanabackup} /hana/backup

# adapt /etc/fstab
echo $(date) INFO adapt /etc/fstab >> ${log_file}
cp /etc/fstab /etc/fstab.changedby_${0}
echo "/dev/mapper/${vg_sap}-${lv_usrsap} /usr/sap xfs defaults,nofail 1 2" >> /etc/fstab
echo "/dev/mapper/${vg_hanadata}-${lv_hanadata} /hana/data xfs defaults,nofail 1 2" >> /etc/fstab
echo "/dev/mapper/${vg_hanalog}-${lv_hanalog} /hana/log xfs defaults,nofail 1 2" >> /etc/fstab
echo "/dev/mapper/${vg_hanashared}-${lv_hanashared} /hana/shared xfs defaults,nofail 1 2" >> /etc/fstab
echo "/dev/mapper/${vg_hanabackup}-${lv_hanabackup} /hana/backup xfs defaults,nofail 1 2" >> /etc/fstab

# adapt /etc/hosts file using instance metadata api
echo $(date) INFO adapt /etc/hosts >> ${log_file}
cp /etc/hosts /etc/hosts.changedby_${0}
virtualMachineIP=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-08-01&format=text")
virtualMachineName=$(hostname)
virtualMachineNameFQDN=${virtualMachineName}.contoso.com
cat >>/etc/hosts <<EOF
${virtualMachineIP} ${virtualMachineNameFQDN} ${virtualMachineName}
EOF

# create directory for SAP HANA software media
SAPBITSDIR="/hana/data/sapbits"
if [ ! -d ${SAPBITSDIR} ]; then
  mkdir ${SAPBITSDIR}
fi

cd ${SAPBITSDIR}
echo $(date) INFO download SAP HANA software media from storage account >> ${log_file}
/usr/bin/wget -O SAPCAR --quiet ${SAPMediaStore_container}/HANA2.0_SPS05_REV59/SAPCAR?${SAPMediaStore_sas}
/usr/bin/wget -O IMDB_SERVER20_059_1-80002031.SAR --quiet ${SAPMediaStore_container}/HANA2.0_SPS05_REV59/IMDB_SERVER20_059_1-80002031.SAR?${SAPMediaStore_sas}

echo $(date) INFO extract SAP HANA software media >> ${log_file}
chmod 755 ./SAPCAR
./SAPCAR -xvf ./IMDB_SERVER20_059_1-80002031.SAR
./SAPCAR -xvf ./IMDB_SERVER20_059_1-80002031.SAR SIGNATURE.SMF -manifest SIGNATURE.SMF

echo $(date) INFO dump SAP HANA installation configuration and password file template >> ${log_file}
${SAPBITSDIR}/SAP_HANA_DATABASE/hdblcm --action=install --dump_configfile_template=${SAPBITSDIR}/hdbinst-${HANASID}.cfg

echo $(date) INFO adjust SAP HANA installation password file template >> ${log_file}
sedcmd="s/\*\*\*/${OSadminPassword}/g"
cat ./hdbinst-${HANASID}.cfg.xml | sed $sedcmd > hdbinst-${HANASID}.cfg.pwd.xml

echo $(date) INFO SAP HANA installation started >> ${log_file}
cat ./hdbinst-${HANASID}.cfg.pwd.xml | ${SAPBITSDIR}/SAP_HANA_DATABASE/hdblcm --batch --action=install --components=server --sid=${HANASID} --number=${HANAInstance} --read_password_from_stdin=xml

echo $(date) INFO SAP HANA installation finished. See log directory under /var/tmp >> ${log_file}
echo $(date) INFO remove SAP HANA installation password file >> ${log_file}
rm ./hdbinst-${HANASID}.cfg.pwd.xml