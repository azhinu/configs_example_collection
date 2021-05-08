#!/usr/bin/env bash

#Config vars:
declare -A  NIC_primary=( ["gateway"]="" ["iface"]="" ["weight"]= )
declare -A  NIC_secondary=( ["gateway"]="" ["iface"]="" ["weight"]= )
idle_timeout=30
retry_timeout=60


healthcheck() {
  local result ifdead=false
  #Get NICs list
  # for i in $(ip route | grep -oP '(?<=dev )\w+(?= \w+ \d $)'); do
  #   echo "Found inteface: $i"
  #   interfaces+=("$i")
  # done

  while true; do

    for iface in ${NIC_primary[iface]} ${NIC_secondary[iface]}; do
      #Ping CloudFlare
      result=$(ping -c 1 -I ${iface} 1.1.1.1 | sed -n 5p)
      #Check if no package received
      if [[ $(echo $result | grep -oP '\d(?= received)') -eq 0 ]]; then
        #Check is primary of secondary interface dead
        #Set live inteface higher priority
        if [[ $iface -eq ${NIC_primary[iface]} ]]; then
          ip route replace default scope global \
            nexthop via ${NIC_primary[gateway]} dev ${NIC_primary[iface]} weight 100 \
            nexthop via ${NIC_secondary[gateway]} dev ${NIC_secondary[iface]} weight 1
        else
          ip route replace default scope global \
            nexthop via ${NIC_primary[gateway]} dev ${NIC_primary[iface]} weight 1 \
            nexthop via ${NIC_secondary[gateway]} dev ${NIC_secondary[iface]} weight 100
        fi
        echo -e "Inteface $iface has no internet connection! NIC has been disabled.\n Waiting for retry"
        ifdead=true
        while [[ $ifdead ]]; do
          sleep $retry_timeout
          #Ping CloudFlare
          result=$(ping -c 1 -I ${iface} 1.1.1.1 | sed -n 5p)
          #Check if package received
          if [[ $(echo $result | grep -oP \d(?= received)) -eq 1 ]]; then
            ifdead=false
            ip route replace default scope global \
              nexthop via ${NIC_primary[gateway]} dev ${NIC_primary[iface]} weight ${NIC_primary[weight]} \
              nexthop via ${NIC_secondary[gateway]} dev ${NIC_secondary[iface]} weight ${NIC_secondary[weight]}
            echo "Interface $iface alive! Restoring routes."
          fi
        done
      fi
    done
    sleep $idle_timeout
  done
}

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
