#!/usr/bin/env bash

healthcheck() {
  local interfaces result
  for i in $(ip route | grep -oP '(?<=dev )\w+(?= \w+ \d $)'); do
    echo "Found inteface: $i"
    interfaces+=("$i")
  done

  while true; do

    for i in interfaces; do
      result=$(ping -c 1 -I $i 1.1.1.1 | tail -n 2)
      echo "$result"
      if [[ $(echo $result | grep -oP \d(?= received)) -eq 0 ]]; then
        ifdown $i
        echo -e "Inteface $i has no internet connection! NIC has been disabled.\n Waiting for retry"

      fi
    done


    sleep 30
  done

}

declare -A  NIC_primary=( ["gateway"]="" ["iface"]="" ["weight"]= )
declare -A  NIC_secondary=( ["gateway"]="" ["iface"]="" ["weight"]= )



case $1 in
  "up")
    echo "Apply custom routes"
    ip route replace default scope global \
      nexthop via ${NIC_primary[gateway]} dev ${NIC_primary[iface]} weight ${NIC_primary[weight]} \
      nexthop via ${NIC_secondary[gateway]} dev ${NIC_secondary[iface]} weight ${NIC_secondary[weight]}
    echo "Start services"
    healthcheck
    ;;
  "down")
    echo "Removing custom routes"
    systemctl restart networking
    echo "Stopping healthcheck service"
    kill $$
    ;;
  "status")

    echo "Service status is $(systemctl status nic-reservation.service | grep -oP '(?<=Active: )\w* \(\w*\)')."

    if [[ $(ip route | grep -cP '^\tnexthop.+$') -eq 2 ]]; then
      echo "Custom routes applied."
    else
      echo "Custom routes not applied!"
    fi
    ;;
  "")
    echo "Usage:
          nic-reservation up - add routes and start healthcheck service.
          nic-reservation down - remove custom rotes and stop healthcheck service.
          nic-reservation status - get status of service."
    ;;
esac
