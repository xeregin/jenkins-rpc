IMAGE_NAME="cirros-0.3.3"
INSTANCE_NAME="$IMAGE_NAME-sanity-test"

nova boot --image $IMAGE_NAME --flavor 1 --poll --nic net-id=`neutron net-list | grep private | awk '{print $2}'` $INSTANCE_NAME
IP=$( nova list | grep $INSTANCE_NAME | awk '{print $12}' | sed 's/private=//' )
P_ID=$( neutron port-list | grep $IP | awk '{print $2}' )
F_ID=$( neutron floatingip-create public | grep " id" | awk '{print $4}' )
F_IP=$( neutron floatingip-show $F_ID | grep floating_ip_address | awk '{print $4}' )

neutron floatingip-associate $F_ID $P_ID

if [[ `ping -c 1 $F_IP | grep "100%"` ]]; then
    echo "Failed to ping instance!"
    echo "Will not clean up automagically..."
    echo "Command for manual deletion:"
    echo "neutron floatingip-delete $F_ID; nova delete $INSTANCE_NAME"
    exit
else
    echo "Succeeded in pinging instance!"
fi

neutron floatingip-delete $F_ID
nova delete $INSTANCE_NAME
