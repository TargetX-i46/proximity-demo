#!/bin/bash

ROOT=/opt/proximity/device0

if [ -z "$1" ]; then
 echo "Enter the device ids you want to detect. Ex. 3005 3006 3007"
 exit 1
fi

 missing_id_list=""
 wrong_key_id_list=""
 unknown_key_id_list=""

  #finding the other devices
  for i in "$@"
  do
     OTHER_KEY_FILE_ORIG=$ROOT/device"$i"_secret-keys-orig.csv
     OTHER_KEY_FILE=$ROOT/device"$i"_secret-keys.csv
     OTHER_NEXT_FILE=$ROOT/device"$i"_next.txt

     if [ -s $OTHER_KEY_FILE ]  && [ -s $OTHER_NEXT_FILE ]; then
         OTHER_KEY=$(cat $OTHER_NEXT_FILE)
         OTHER_KEY=${OTHER_KEY:0:16}
         echo ""
         echo "Device "$i" Current key" $OTHER_KEY

         CHECK_CSV=$(cat /opt/lba_sensor/jar/*.csv)
         RESULT_CSV=$?   
         if [ $RESULT_CSV -ne 0 ]; then
           echo "No csv...retrying..."
           sleep 5
           $ROOT/auth.sh $@
           exit 1
         fi
         
		 RESPONSE=$(cat /opt/lba_sensor/jar/*.csv | grep $OTHER_KEY)
		 RESULT=$?   
		 if [ $RESULT -eq 0 ]; then
		    RESPONSE_KEY=$(echo $RESPONSE | rev | cut -d, -f2 | rev)
		    echo $RESPONSE_KEY
		    echo "Device "$i" is within range"
		      
		    OTHER_NEXT_KEY=$(head -n 1 $OTHER_KEY_FILE)
		    echo $OTHER_NEXT_KEY | tee $OTHER_NEXT_FILE >> /dev/null
		    OTHER_NEXT_KEY=${OTHER_NEXT_KEY:0:16}
		    echo "Device "$i" next key" $OTHER_NEXT_KEY

		    sed -i '1d' $OTHER_KEY_FILE
		 else
		     QUERY=$(cat /opt/lba_sensor/jar/*.csv | grep i46 | cut -d, -f22 | sort -u | cut -d'-' -f 2 | xargs | sed 's/ /\\|/g')
		     echo $QUERY
		     if [ -z "$QUERY" ]; then
		         echo "No match"
		         missing_id_list=$missing_id_list,"\""$i"\""
		         echo "Device "$i" not found"
		     else
			CURRFILE=$(cat $OTHER_KEY_FILE | grep "$QUERY")
			RESULT_CURR=$?
			if [ $RESULT_CURR -eq 0 ]; then
			        #gateway is behind
			        
			        nextline=$(awk '/'$CURRFILE'/{ print NR; exit }' $OTHER_KEY_FILE)
			        echo "Next key detected on line "$nextline
			        if [ $nextline -gt 1 ]; then
			         nextline=$nextline-1
			         sed -i '1,'$nextline'd' $OTHER_KEY_FILE
			         
			         echo "Keys file corrected"
			        fi
			       
			        OTHER_NEXT_KEY=$(head -n 1 $OTHER_KEY_FILE)
				echo $OTHER_NEXT_KEY | tee $OTHER_NEXT_FILE >> /dev/null
				OTHER_NEXT_KEY=${OTHER_NEXT_KEY:0:16}
				echo "Device "$i" next key" $OTHER_NEXT_KEY
                                sed -i '1d' $OTHER_KEY_FILE
                                
                                             
                                sleep 5
				$ROOT/auth.sh $i
	
			else 
			   ORIGFILE=$(cat $OTHER_KEY_FILE_ORIG | grep "$QUERY")
			   RESULT_ORIG=$?
			   if [ $RESULT_ORIG -eq 0 ]; then
				wrong_key_id_list=$wrong_key_id_list,"\""$i"\""
				echo "Device "$i" not found"
			   else 
				unknown_key_id_list=$unknown_key_id_list,"\""$i"\""
				echo "Device "$i" not found"
			   fi 
			fi 
		      fi
		 fi  
 
       else
         if [ ! -s $OTHER_KEY_FILE ]; then
           echo "Key file empty - contact system administrator to generate new keys"
	   missing_id_list=$missing_id_list,"\""$i"\""
         fi
         echo "Device "$i" key file not found"
       fi
  done
  
  #send report   
  if [ ! -z "$missing_id_list" ]; then
    missing_id_list="${missing_id_list:1}"
  fi
  if [ ! -z "$wrong_key_id_list" ]; then
    wrong_key_id_list="${wrong_key_id_list:1}"
  fi
  if [ ! -z "$unknown_key_id_list" ]; then
    unknown_key_id_list="${unknown_key_id_list:1}"
  fi
     
  echo "Missing devices " $missing_id_list
  echo "Wrong keys " $wrong_key_id_list
  echo "Unknown keys " $unknown_key_id_list
  
  url=https://target-x.i46.io/status/proximity-report
  body_file='/opt/statusreport'  
  uuid=$(grep 'uuid=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)
  password=$(grep 'password=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)
  org=$(grep 'organizationId=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)

  postDataJson='{
       "device": {
          "uuid": "'$uuid'",
          "password": "'$password'",
          "organizationId": "'$org'"
        },"missingDevices": '[$missing_id_list]' ,"wrongKeys": '[$wrong_key_id_list]' ,"unknownKeys": '[$unknown_key_id_list]' }'
  curl -X POST "${url}" -H "Content-Type: application/json" -u "admin:2aXQ2UjyJaHMyxJeb6VIvLXQLHHSxqI9" -d "${postDataJson}"    

