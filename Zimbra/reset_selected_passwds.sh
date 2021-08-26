#!/usr/bin/env bash
#Account.txt = username : password
ACCOUNTS=accounts.txt
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
cat $ACCOUNTS | tr -d : | while IFS=$' \t\r\n' read USER PASSWD; do
    echo "Modifying $USER password…"
    zmprov sp ${USER}@${DOMAIN} ${PASSWD}
    echo "Done"
done
