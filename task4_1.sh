#!/bin/bash

         #/usr/bin/env bash

# Redirecting output
exec 4<&1
exec 1>task4_1.out

# # Redirecting errors
# exec 5<&2
# exec 2>errors4_1.log


echo "--- Hardware ---"
echo "CPU: $(cat /proc/cpuinfo | grep -m 1 'model name' | sed 's/model name//' | sed 's/: //' | sed 's/\t//')"
echo "RAM: $(cat /proc/meminfo | grep 'MemTotal' | sed 's/MemTotal//' | tr -d ':' | tr -d ' ' | tr '[:lower:]' '[:upper:]' ) "
exec 6<&1
exec 1>/dev/null
# Finding information about the motherboard. Поиск сведений о материнской плате.
if dmidecode -q -s baseboard-manufacturer ; then
    baseboardmanufacturer=$(dmidecode -s baseboard-manufacturer)
elif echo $? !=0 ; then
    if cat /sys/devices/virtual/dmi/id/board_vendor ; then
        baseboardmanufacturer=$(cat /sys/devices/virtual/dmi/id/board_vendor)
    elif echo $? !=0 ; then
        baseboardmanufacturer=Unknown
    else
        baseboardmanufacturer=Unknown
    fi
else
    baseboardmanufacturer=Unknown
fi
if dmidecode -s baseboard-product-name ; then
    baseboardproductname=$(dmidecode -s baseboard-product-name)
elif echo $? !=0 ; then
    if cat /sys/devices/virtual/dmi/id/board_name ; then
        baseboardproductname=$(cat /sys/devices/virtual/dmi/id/board_name)
    elif echo $? !=0 ; then
        baseboardproductname=Unknown
    else
        baseboardproductname=Unknown
    fi
else
    baseboardproductname=Unknown
fi
# Availability of serial number Наличие серийного номера
if [[ $(dmidecode -q -s system-serial-number) = 'To Be Filled By O.E.M.' ]];then
    syssernum=Unknown
elif echo $? != 0 ; then
    if [ ! -e /sys/devices/virtual/dmi/id/product_serial ] ; then
        syssernum=Unknown
    elif  grep -s -q 'To Be Filled By O.E.M.' /sys/devices/virtual/dmi/id/product_serial ; then
        syssernum=Unknown
    else syssernum=$(cat /sys/devices/virtual/dmi/id/product_serial)
    fi
else
    syssernum=$( dmidecode -q -s system-serial-number) 
fi
exec 1<&6

echo "Motherboard: $baseboardmanufacturer $baseboardproductname"  #$(cat /sys/devices/virtual/dmi/id/board_vendor) / $(cat /sys/devices/virtual/dmi/id/board_name) / $(cat /sys/devices/virtual/dmi/id/board_version)"
echo "System Serial Number: $syssernum"

echo "--- System ---"
echo "OS Distribution: $(cat /etc/*-release | grep -m 1 'PRETTY_NAME' | sed 's/PRETTY_NAME=//'| sed 's/"//' | sed 's/"//')"
echo "Kernel version: $(uname -r)" #$(cat /proc/version | grep -m 1 'Linux version' | awk '{$1=""; $2=""; $4=""; $5=""; $6="";$7="";$8=""; $9="";$10=""; $11="";$12="";$13="";$14=""; $15="";$16=""; $17="";print $0}')

# The two files determine the date of creation (installation) Эти два файла определяют дату создания (установки)
datelsb=$(stat -c%z /etc/lsb-release | cut -c -19)
dateos=$(stat -c%z /etc/os-release | cut -c -19)
if [ "$datelsb" = "$dateos" ]; then
    insdate=$datelsb
else
    insdate=Unknown
fi
echo "Installation date: $insdate"
echo "Hostname: $HOSTNAME"
echo "Uptime: $(uptime -p | sed 's/up //')"
proc=$(ps -e | wc -l)
proc=$(($proc-1))
echo "Processes running: $proc"
echo "User logged in: $(who -q | grep '=' | sed 's/=/ /' | awk ' {print $3} ')"
echo "--- Network ---"
declare -a namenet
i=0
# Finds the name of the device Находит название устройств
for word in $(ip address | awk -F': '  ' {print $2} ')
    do
    namenet[$i]=$word
    ((i ++))
done
i=0
# Finds addresses Находит адреса
for word in "${namenet[@]}"
    do
    addressnet[$i]="$word:"
    # Checks if the @ symbol is in the name, then reads it before it. Проверяет есть ли в названии символ @, тогда читает до него.
    if ! [ -z $( echo $word | grep -m 1 '@' ) ] ; then
        word=$( echo $word | grep -m 1 '@' | sed 's/@/ /' | awk '{print $1}' )
    fi
    # Checks for IP4 if there is no "-" Проверяет наличие IP4, если нет "-"
    if [ -z $( ip address show $word | grep -T 'inet '| awk '{print $2}' ) ] ; then
        addressnet[$i]=${addressnet[i]}' -'
    fi
    # By name search all IP4По названию ищет все IP4
    j=0
    for numip in $( ip address show $word | grep -T 'inet '| awk '{print $2}' )
        do
        addressnet[$i]=${addressnet[i]}' '${numip}
        if [[ $j > 0 ]] ; then
            addressnet[$i]=${addressnet[i]}','
        ((j ++))
        fi
    done
    ((i ++))
done

for addressline  in "${addressnet[@]}"
    do
    echo "$addressline"
done

# Redirecting output
exec 1<&4

# # Redirecting errors
# exec 2<&5

if [ -e task4_1.out ] ; then
    exit 0
fi
exit 1


