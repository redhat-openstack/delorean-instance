#!/bin/bash

INSTANCE_NAME=rdo-delorean-instance
VOLUME_NAME=rdo-delorean-volume
# _OS1_Fedora-Cloud-Base-20141203-21.x86_64
IMAGE_ID=5c2eb013-e727-4aeb-868b-5798f8ef0064
SECGROUP_NAME=rdo-secgroup
KEY_NAME=rdo-team-key
# trunk.rdoproject.org
FLOATING_IP=209.132.178.14

CINDER_ID=$(cinder show ${VOLUME_NAME} |grep ' id ' | awk '{print $4}')
if [ -z "${CINDER_ID}" ]; then
    set -x
    cinder create --display-name ${VOLUME_NAME} 160
    set +x
    sleep 30
    VOLUME_STATUS=$(cinder list |grep ${VOLUME_NAME} | awk '{print $4}')
    if [ ${VOLUME_STATUS} != "available" ]
    then
        echo "There was an error creating the volume. Check and retry"
        exit 1
    fi
else
    echo "Reusing existing volume ${VOLUME_NAME}"
fi

openstack server create --flavor m1.medium --image ${IMAGE_ID} --security-group ${SECGROUP_NAME} --key-name ${KEY_NAME} --user-data delorean-user-data.txt ${INSTANCE_NAME}
sleep 30
if cinder show ${CINDER_ID}|grep -q 'in-use'; then
    echo "WARN: volume ${VOLUME_NAME} is in use and was not attached to ${INSTANCE_NAME}"
else
    openstack server add volume --device /dev/vdb ${INSTANCE_NAME} ${CINDER_ID}
fi

SERVER_ID=$(openstack ip floating list | grep ${FLOATING_IP} |awk '{print $10}')
if [ ${SERVER_ID} = 'None' ]; then
    openstack ip floating add ${FLOATING_IP} ${INSTANCE_NAME}
else
    echo "WARN: floating ${VOLUME_NAME} is in use by ${SERVER_ID} and was not associated with ${INSTANCE_NAME}"
fi
