#!/usr/bin/env bash
#Docker is required!
############# CONFIGURATION ###########
ACCOUNTS=accounts.txt
SCR_HOST=domain_or_ip
DST_HOST=domain_or_ip
DOMAIN=xchangefinance.uk
DATE=$(date -u +"%Y-%m-%d %H:%M:%S")
#######################################


cat $ACCOUNTS | while IFS= read USER PASSWD; do
  echo -e "\n\n\n[$DATE] Run sync $USER....\n\n\n"
  docker run --rm gilleslamiral/imapsync imapsync \
      --nosyncacls \
      --subscribe \
      --syncinternaldates \
      --nofoldersizes \
      --skipsize \
      --noauthmd5 \
      --host1 $SCR_HOST --user1 ${USER}@${DOMAIN} --password1 $PASSWD \
      --host2 $DST_HOST --user2 ${USER}@${DOMAIN} --password2 $PASSWD --ssl2 --port2 7993 \
      --automap
      #In my case I need to use 7993 port
done
echo "[$DATE] sync completed"
exit 0
