#!/usr/bin/env bash

DOMAIN=
#######################################
if [[ -z $DOMAIN ]]; then
  if [[ -z $1 ]]; then
    echo 'Use reset_selected_passwords.sh DOMAIN'
    exit 1
  fi
  DOMAIN=$1
fi
#Check permissions
if [[ $(whoami) != 'zimbra' ]] ; then
    echo "Run script as \"zimbra\" user"
    exit 1
fi


#Loop for users
for USER in $(zmprov -l gaa ${DOMAIN}); do
    echo "$USER = $(zmmailbox -z -m ${USER} gms)"
    echo "Done"
done
