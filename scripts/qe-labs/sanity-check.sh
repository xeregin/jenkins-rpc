IMAGE_NAME=""
INSTANCE_NAME=""
IP=""
P_ID=""
F_ID=""
F_IP=""

boot_vm() {
    nova boot --image $IMAGE_NAME --flavor 1 --poll --nic net-id=`neutron net-list | grep private | awk '{print $2}'` $INSTANCE_NAME
}

check_status() {
    if [[ `ping -c 1 $1 | grep "100%"` ]]; then
        echo "Failed to ping instance!"
        echo "Will not clean up automagically..."
        echo "Command for manual deletion:"
        echo "neutron floatingip-delete $F_ID; nova delete $INSTANCE_NAME"
        exit
    else
        echo "Succeeded in pinging instance!"
    fi
}

cleanup() {
    neutron floatingip-delete $F_ID
    nova delete $INSTANCE_NAME
}

store_floatingip() {
    F_IP=$( neutron floatingip-show $F_ID | grep floating_ip_address | awk '{print $4}' )
}

store_floatingip_id() {
    F_ID=$( neutron floatingip-create public | grep " id" | awk '{print $4}' )
}

store_port_id() {
    P_ID=$( neutron port-list | grep $IP | awk '{print $2}' )
}

store_vm_ip() {
    IP=$( nova list | grep $INSTANCE_NAME | awk '{print $12}' | sed 's/private=//' )
}

IMAGE_NAME="cirros-0.3.3"
INSTANCE_NAME="$IMAGE_NAME-sanity-test"

boot_vm
store_vm_ip
store_port_id
store_floatingip_id
store_floatingip

neutron floatingip-associate $F_ID $P_ID

check_status $F_IP
cleanup
