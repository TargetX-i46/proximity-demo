## Proximity Sequence v4

There are 3 device directories in the project. 1 directory per device.
Each directory contains a list of keys. The keys are used to broadcast as ssid name to see if the devices are within range.
The gateway contains the keys they want to detect.
The gateway can detect multiple devices.


Goal:
Each device will broadcast their SSID and the gateway will check if it can see the devices (within range) or not.

Setup:
1 IoT Gateway
1~n Devices

Requirements:
1. Given 3 raspberry pi devices, assign one that will act as a gateway (device0)
2. The rest of the devices, assign as device1 and device2. You only need to copy 1 directory per device.
   Example, copy device0 only for the gateway. For the other device, copy only the device1 directory.
3. Check device{id}/auth.sh file and rename the line to the correct path in the device
   ROOT=/opt/proximity/device1

Files:

Own keys - next.txt, secret-keys.csv
Other device keys - device{id}_next.txt, device{id}_secret-keys.csv

Each directory, has a file name next.txt, secret-keys.csv -> it means, it's the device's own keys.
So the gateway device0 for example, it contains next.txt, secret-key.csv and also the other device's keys it needs to detect.

Script:
auth.sh <device 1> <device n optional>

It takes the device id as parameter. Put the id only.
Example:
/path-of-the-project/device0/auth.sh 1 2

/path-of-the-project/device1/auth.sh

Initialize:

Run commands manually to detect initial key (gateway crontab triggers first so it needs to find the initial devices). See device{id}_next.txt
./init.sh

EDIT: No need to run below. Just ./init.sh
On device1
nmcli dev wifi hotspot con-name 213e878008846004 ifname wlan0 ssid i46-213e878008846004 password "proximity-test@!"

On device2
nmcli dev wifi hotspot con-name 73c570dc74b2b6af ifname wlan0 ssid i46-73c570dc74b2b6af password "proximity-test@!"

Note: the device0_next.txt should be the 2nd line of secret-keys of the gateway
root@IoT-Gateway:/home/i46# head -n 2 /opt/proximity/device0/secret-keys.csv
aeb995e09006857e
2dcd2ff2201c4fce


Manual testing
Run from gateway:
sudo su
/opt/proximity/device0/auth.sh 1 2

Run from the other device (1, etc.):
sudo su
/opt/proximity/device1/auth.sh

How it works:
After you initialize and broadcast each SSIDs, run the command from each device manually (run the command from gateway to detect device1. Then run the command from device1 to broadcast ssid).
Check if the gateway detected the devices.
If not, you need to replace the values in the next.txt and device{id}_next.txt of both devices and make sure they see each other's keys.


Check the current SSID broadcasted by the device
nmcli connection show

If you need to reset, you can remove the SSID
nmcli connection down <SSID>
nmcli connection delete <SSID>

You need to make sure next.txt and device{id}_next.txt on both devices are pointing to the correct keys.

To check the SSIDs available nearby:
nmcli dev wifi

If you understand how the manual test works, you can add the command to the crontab.
The crontab of the devices will trigger 30 seconds after the gateway allowed the ip, so it will also detect the gateway and
try to connect to the proxy. It will show in the logs if it is in range and succeeded the connection test.

From gateway:
sudo su
crontab -e
*/2 * * * * sleep 30 &&  /opt/proximity/device0/auth.sh 1 2 >> /opt/gateway.log

From the other device (1, etc.):
sudo su
crontab -e
*/2 * * * * /opt/proximity/device1/auth.sh >> /opt/device1.log


Check the logs (per device):
/opt/gateway.log
/opt/device1.log
/opt/device2.log

DOWNLOAD KEYS:

Commands to reset keys per device:
If you reset the keys in the iot device, reset also the matching keys in the gateway.
You must know the UUID

Reset
sudo curl -u "admin:<password>" -X PUT https://target-x.i46.io/safekey/keys/download?uuid=uuid -o /opt/proximity/deviceN/secret-keys.csv

In device 1 - 696fb51c-514b-44fb-b6fb-43d873613b49
sudo curl -u "admin:<password>" -X PUT https://target-x.i46.io/safekey/keys/download?uuid=696fb51c-514b-44fb-b6fb-43d873613b49 -o /opt/proximity/device1/secret-keys.csv

In device 2 - d035eae5-62f8-4084-8088-d927560385c3
sudo curl -u "admin:<password>" -X PUT https://target-x.i46.io/safekey/keys/download?uuid=d035eae5-62f8-4084-8088-d927560385c3 -o /opt/proximity/device2/secret-keys.csv

In device 0 - gateway
sudo curl -u "admin:<password>" -X PUT https://target-x.i46.io/safekey/keys/download?uuid=696fb51c-514b-44fb-b6fb-43d873613b49 -o /opt/proximity/device0/device1_secret-keys.csv
sudo curl -u "admin:<password>" -X PUT https://target-x.i46.io/safekey/keys/download?uuid=d035eae5-62f8-4084-8088-d927560385c3 -o /opt/proximity/device0/device2_secret-keys.csv

See working example:
RSSH to
4186 - gateway - tail -f /opt/gateway.log
3301 - device 1 - tail -f /opt/device1.log
4098 - device 2 - tail -f /opt/device2.log

Path: /opt/proximity

CREATE NEW KEYS:

To generate a new device - new uuid:
[POST] https://target-x.i46.io/safekey/device
body:
{
"deviceName": "iot 1",
"description": "test device"
}
Authorization: Basic
admin:<password>

It will return a uuid

Then do the steps above to download key.

device0, device1, device2 are just arbritrary names of the directories to make everything simple.
You can name it deviceMyDevice but you need to provide the name after device<name> in the crontab:
/opt/proximity/device0/auth.sh 1 2 IoTJanine

/opt/proximity/deviceIoTJanine/auth.sh

Basically, replace all device<name> with the name you want to set.


#curl -u "admin:<password>" -X GET https://target-x.i46.io/safekey/keys/download?uuid=5a189b05-488a-4e67-b89e-16a9764a68ce -o device2_secret-keys.csv
#echo $(head -n 1 device2_secret-keys.csv) | tee device2_next.txt >> /dev/null
#sed -i '1d' device2_secret-keys.csv


If you have questions:
janine@i46.cz



