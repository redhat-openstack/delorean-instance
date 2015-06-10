#!/bin/bash

INSTANCE_NAME=rdo-delorean-instance
VOLUME_NAME=rdo-delorean-volume
IMAGE_ID=f2df087c-4e54-4047-98c0-8e03dbf6412b
SECGROUP_NAME=jpena-secgroup
KEY_NAME=jpena-key

#cinder create --display-name ${VOLUME_NAME} 160
#sleep 30
VOLUME_STATUS=$(cinder list |grep ${VOLUME_NAME} | awk '{print $4}')
if [ ${VOLUME_STATUS} != "available" ]
then
    echo "There was an error creating the volume. Check and retry"
    exit 1
fi

nova boot --flavor m1.medium --image ${IMAGE_ID} --security-groups ${SECGROUP_NAME} --key-name ${KEY_NAME} --user-data delorean-user-data.txt ${INSTANCE_NAME}
sleep 30
CINDER_ID=$(cinder show ${VOLUME_NAME} |grep -w id | awk '{print $4}')
nova volume-attach ${INSTANCE_NAME} ${CINDER_ID} /dev/vdb

# Note the following will not work when we have some floating IPs already allocated to instances,
# but it can do for now
FLOATING_IP=$(nova floating-ip-list | sed -e '1,3d' | head -n -1 | awk '{print $2}' | head -n 1)
nova floating-ip-associate ${INSTANCE_NAME} ${FLOATING_IP}
