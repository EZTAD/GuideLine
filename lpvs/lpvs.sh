#!/usr/bin/bash
today=$(date)
VALID_CMD='a9="/usr/lib/firefox-esr/firefox-esr"'
VALID_CMD2='a9="/usr/bin/chromium"'
VALID_CMD3='a9="/usr/share/code/code"'
VALID_CMD4='a9="/usr/bin/libreoffice"'
VALID_CMD5='a9="/usr/bin/horizon-client"'
RESULT=''
CMD_ARRAY=("$VALID_CMD" "$VALID_CMD2" "$VALID_CMD3" "$VALID_CMD4" "$VALID_CMD5")

log_function(){
    echo -e "Invalid Systemd run found in" $today >> /var/log/my_systemd-run.log
    PID=$(ausearch -ts recent -k access_systemd-run -i | grep -i type=SYSCALL | \
    awk  '{ \ 
       for (i=1;i<=NF;i++) \ 
        { \
           split($i,a,"="); \
           {if (a[1]=="ppid"){print a[2]} \
           }  \
        }    \
      } '   \
       )

    echo "PID=" $PID >> /var/log/my_systemd-run.log
    arraypid=($PID)
    echo -e "------------------------------------\n"
    ausearch -ts recent -k access_systemd-run -i >> /var/log/my_systemd-run.log
    echo -e "\n" >> /var/log/my_systemd-run.log
    echo -e "------------------------------------\n" >> /var/log/my_systemd-run.log
    for itempid in ${arraypid[@]};do echo -e \ 
      "PID:"$itempid >> /var/log/my_systemd-run.log ; \
      ps -p $itempid -o user:20,lstart,ppid,pid,cmd:200 >> /var/log/my_systemd-run.log;done
      
    echo -e "------------------------------------------------------------------------------------------------------\n"
    echo "-<begin proccess log>-" >>/var/log/my_systemd-run.log
    ps -aux --forest >> /var/log/my_systemd-run.log
    echo "-<end proccess log>-" >>/var/log/my_systemd-run.log
}

action_function(){
chmod oug-x /usr/bin/systemd-run
systemctl restart lightdm
systemctl stop my_systemd_run_validator.service
}
 
#################################
monitor_function() {
mapfile -t result < <(ausearch -ts recent -k access_systemd-run -c systemd-run | awk '/type=EXECVE/ { $1=$2=$3=$4=$5=$6=$7=$8=$9=$10=$11=$12=$14=$15=$16=""; sub(/^    /,""); print }')

for row in "${result[@]}"; do
    clean_row=$(echo "$row" | tr -d '\r' | tr -cd '[:print:]' | sed 's/^[ \t]*//; s/[ \t]*$//; s/[[:space:]]\+/ /g')
    match_found=0
    for cmd in "${CMD_ARRAY[@]}"; do
        if [[ "$clean_row" == "$cmd" ]]; then
            echo "Match found: $clean_row"
            match_found=1
            break   
        fi
     done

    if [[ $match_found -eq 0 ]]; then
        echo -e "===============>Systemd-run LPVS violation <=============== \n"
        date
        echo "Invalid systemd-run command detected: $clean_row"
        echo -e "===============>Systemd-run LPVS violation <=============== \n"
        log_function;sleep 1;action_function;
    fi
 done

#################################
}

while true 
do
   monitor_function
sleep 1
 done
