#!/usr/bin/env bash
############# CONFIGURATION ###########
ACCOUNTS=accounts.txt
SRC_HOST=
DST_HOST=
DOMAIN=
DATE=$(date -u +"%Y-%m-%d %H:%M:%S")
#######################################
if [[ -z $SRC_HOST || -z $DST_HOST  || -z $DOMAIN ]]; then
  if [[ -z $# ]]; then
    echo 'Use imapsync_docker.sh SRC_HOST DST_HOST DOMAIN'
  fi
  SRC_HOST=$1
  DST_HOST=$2
  DOMAIN=$3
fi

cat $ACCOUNTS | while IFS=$' \t\r\n' read USER PASSWD; do
  echo -e "\n\n\n[$DATE] sync $USER....\n\n\n"
  echo "SRC_HOST: $SRC_HOST; DST_HOST: $DST_HOST"
  echo "User: ${USER}@${DOMAIN} Passwd: $PASSWD"
  docker run --rm gilleslamiral/imapsync imapsync \
    --nosyncacls \
    --subscribe \
    --syncinternaldates \
    --nofoldersizes \
    --skipsize \
    --noauthmd5 \
    --nofoldersizes \
    --skipsize \
    --fast \
    --host1 $SRC_HOST --user1 ${USER}@${DOMAIN} --password1 ${PASSWD} \
    --host2 $DST_HOST --user2 ${USER}@${DOMAIN} --password2 ${PASSWD} --ssl2 \
    --automap
done

echo "[$DATE] sync dompleted"
exit 0
