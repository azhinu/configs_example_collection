#!/usr/bin/env bash

#Check permissions
if [ `whoami` != 'zimbra' ] ; then
    echo "Run script as \"zimbra\" user"
    exit 0
fi


#Loop for users
for ACCOUNT in $(zmprov -l gaa); do

  if [[ $ACCOUNT == *"mail.local" || $ACCOUNT == "azhinu"* ]]; then
    echo "Skipping system account, $ACCOUNT…"
  else
    echo "Modifying $ACCOUNT password…"
    zmprov sp "$ACCOUNT" "123456Qq"
    zmprov ma "$ACCOUNT" zimbraPasswordMustChange TRUE
    echo "Done"
  fi

done
