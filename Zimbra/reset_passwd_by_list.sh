#!/usr/bin/env bash

#Check permissions
if [ `whoami` != 'zimbra' ] ; then
    echo "Run script as \"zimbra\" user"
    exit 0
fi

############# CONFIGURATION ###########
ACCOUNTS=accounts.txt
DOMAIN=domain_or_ip
DATE=$(date -u +"%Y-%m-%d %H:%M:%S")
#######################################


cat $ACCOUNTS | while IFS= read USER PASSWD; do

  echo "Changing PASSWD for ${USER}@${DOMAIN}"
  zmprov sp ${USER}@${DOMAIN} $PASSWD

  echo "Unlock for  ${USER}@${DOMAIN}"
  zmprov ma ${USER}@${DOMAIN} zimbraAccountStatus active
done

echo "[$DATE] sync completed"
exit 0
