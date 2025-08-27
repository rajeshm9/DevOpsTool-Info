#!/bin/bash
# Decode /proc/net/tcp and /proc/net/udp like netstat

decode_ip_port() {
    ip_hex=$1
    port_hex=$2

    # Convert IP (little endian)
    ip=$(printf "%d.%d.%d.%d" \
        0x${ip_hex:6:2} 0x${ip_hex:4:2} 0x${ip_hex:2:2} 0x${ip_hex:0:2})

    # Convert port
    port=$((16#$port_hex))

    echo "$ip:$port"
}

decode_file() {
    file=$1
    proto=$2

    echo "### $proto connections from $file"
    echo "Local Address        Remote Address       State"

    # Skip first line (header)
    tail -n +2 "$file" | while read -r line; do
        local_hex=$(echo $line | awk '{print $2}')
        remote_hex=$(echo $line | awk '{print $3}')
        state_hex=$(echo $line | awk '{print $4}')

        local_ip=$(decode_ip_port ${local_hex%:*} ${local_hex#*:})
        remote_ip=$(decode_ip_port ${remote_hex%:*} ${remote_hex#*:})

        # TCP state map
        case $state_hex in
            01) state="ESTABLISHED" ;;
            02) state="SYN_SENT" ;;
            03) state="SYN_RECV" ;;
            04) state="FIN_WAIT1" ;;
            05) state="FIN_WAIT2" ;;
            06) state="TIME_WAIT" ;;
            07) state="CLOSE" ;;
            0
