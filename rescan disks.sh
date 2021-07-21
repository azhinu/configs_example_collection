#!/usr/bin/env


read -sp 'Password: ' password
echo 'privilege escalation'
sudo --login -p
read -p 'privilege escalation' disk
echo 'Start rescan disk'
echo 1>/sys/class/block/sdd/device/rescan
cfdisk
 
