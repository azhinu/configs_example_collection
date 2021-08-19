#!/usr/bin/env bash

action = $1
dlist = $2
user = $3

case $action in
  add )
  if [[ dist != '' ]]; then
    if [[ user != '' ]]; then
      zmprov grr dl $dlist usr $user sendAsDistList
    else
      echo "No user selected"
    fi
  else
    echo "No distribution list selected"
  fi

    ;;
  rm )
  zmprov rvr dl $dlist usr $user sendAsDistList
    ;;
  * )
  echo 'Use dlish [\"add\" or \"rm\"] \"distribution list\" \"user\"'
esac
