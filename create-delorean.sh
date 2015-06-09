#!/bin/bash

INSTANCE_NAME=delorean-test-3
VOLUME_NAME=delorean-volume

cinder create --display-name ${VOLUME_NAME} 160
sleep 10
VOLUME_STATUS=$(cinder list |grep ${VOLUME_NAME} | awk '{print $4}')
if [ ${VOLUME_STATUS} != "available" ]
then
    echo "There was an error creating the volume. Check and retry"
    exit 1
fi

nova boot --flavor m1.medium --image f2df087c-4e54-4047-98c0-8e03dbf6412b --security-groups jpena-secgroup --key-name jpena-key --user-data delorean-user-data.txt ${INSTANCE_NAME}
sleep 30
CINDER_ID=$(cinder show ${VOLUME_NAME} |grep -w id | awk '{print $4}')
nova volume-attach ${INSTANCE_NAME} ${CINDER_ID} /dev/vdb

# Note the following will not work when we have some floating IPs already allocated to instances,
# but it can do for now
FLOATING_IP=$(nova floating-ip-list | sed -e '1,3d' | head -n -1 | awk '{print $2}' | head -n 1)
nova floating-ip-associate ${INSTANCE_NAME} ${FLOATING_IP}
