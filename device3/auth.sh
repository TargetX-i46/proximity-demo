#!/bin/bash

ROOT=/opt/proximity/device3

KEY_FILE=$ROOT/secret-keys.csv
NEXT_FILE=$ROOT/next.txt

if [ -s $KEY_FILE ]  && [ -s $NEXT_FILE ]; then
 KEY=$(cat $NEXT_FILE)
 KEY=${KEY:0:16}
 echo "Current key" $KEY
   
 #my key
 LINE=$(awk '/'$KEY'/{ print NR; exit }' $KEY_FILE)
 NEXT=$((LINE + 1))
 MY_NEXT_KEY=$(awk 'NR == '$NEXT $KEY_FILE)
 echo $MY_NEXT_KEY | tee $NEXT_FILE >> /dev/null
 MY_NEXT_KEY=${MY_NEXT_KEY:0:16}
 echo "Next key" $MY_NEXT_KEY

 sed -i '1d' $KEY_FILE
  
 nmcli connection down $KEY
 nmcli connection delete $KEY

 nmcli dev wifi hotspot con-name $MY_NEXT_KEY ifname wlo1 ssid i46-$MY_NEXT_KEY password "proximity-test@!"
 nmcli connection show | grep $MY_NEXT_KEY

else
  echo "Key file not found"
fi
