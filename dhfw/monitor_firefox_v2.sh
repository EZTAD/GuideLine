#! /usr/bin/bash
# if user securelan run firefox then only add slice_local to iptables
securelan_uid=1001
internet_uid=1003
FIREFOX_PATH="/usr/lib/firefox-esr/firefox-esr"
CGROUP_PATH="user.slice/user-1001.slice/user@1001.service/my_firefox_local.slice"
CGROUP_PATH_INTERNET="user.slice/user-1003.slice/user@1003.service/my_firefox_internet.slice"
add_iptables=0
add_iptables_1003=0
IP_DST="192.168.0.0/16,172.16.0.0/12,10.0.0.0/8"
#---------------------------------------------------------------------------------------------------------------------------------------------#
#Rule Section
EXCLUDE_IP_VIRAWEB="10.17.40.77,10.17.40.75"

remove_iptables_rules_user_id_1003() {
  if  [ "$add_iptables_1003" -eq 1 ] ; then
  #internet------------------------------------
   iptables -D OUTPUT -d 10.17.16.2 -p tcp -m multiport --dports 8070,80,443 -m cgroup --path "$CGROUP_PATH_INTERNET" -j ACCEPT
   iptables -D OUTPUT -d "$EXCLUDE_IP_VIRAWEB" -p tcp  -m multiport --dports 80,443 -m cgroup --path "$CGROUP_PATH_INTERNET" -j ACCEPT
  fi
}

add_iptables_rules_user_id_1003() {
  if  [ "$add_iptables_1003" -eq 0 ] ; then
#internet--------------------------------------
   iptables -A OUTPUT -d 10.17.16.2 -p tcp  -m multiport --dports 8070,80,443 -m cgroup --path "$CGROUP_PATH_INTERNET" -j ACCEPT
   iptables -A OUTPUT -d "$EXCLUDE_IP_VIRAWEB" -p tcp  -m multiport --dports 80,443 -m cgroup --path "$CGROUP_PATH_INTERNET" -j ACCEPT
echo "add internet rule"
  fi
}


remove_iptables_rules_user_id_1001() {
  if  [ "$add_iptables" -eq 1 ] ; then
   iptables -D OUTPUT -d "$EXCLUDE_IP_VIRAWEB" -p tcp -m multiport --dports 80,443 -m cgroup --path  "$CGROUP_PATH" -j DROP
   iptables -D OUTPUT -d "$IP_DST" -p tcp -m multiport --dports 80,443 -m cgroup --path  "$CGROUP_PATH" -j ACCEPT
  fi
}

add_iptables_rules_user_id_1001() {
  if  [ "$add_iptables" -eq 0 ] ; then
   iptables -A OUTPUT -d "$EXCLUDE_IP_VIRAWEB" -p tcp -m multiport --dports 80,443 -m cgroup --path  "$CGROUP_PATH" -j DROP
   iptables -A OUTPUT -d "$IP_DST" -p tcp -m multiport --dports 80,443 -m cgroup --path  "$CGROUP_PATH" -j ACCEPT
  fi
}


#---------------------------------------------------------------------------------------------------------------------------------------------#
monitor_firefox_for_user_local() {
sleep 1
        PID=$(pgrep -u securelan -x -f "$FIREFOX_PATH")
        echo PID: $PID
sleep 1
     if [[ -n "$PID" ]]; then
         # Get the UID of the process owner
             echo "$PROCESS_NAME is running under securelan uid: ($PID). add slice_local to iptables"
             add_iptables_rules_user_id_1001
             add_iptables=1
        else 
    echo "$FIREFOX_PATH Not Found ($securelan_uid)"
     remove_iptables_rules_user_id_1001
     add_iptables=0
fi

}

monitor_firefox_for_user_internet() {
sleep 1
        PID_internet=$(pgrep -u internet -x -f "$FIREFOX_PATH")
        echo PID_internet: $PID_internet
sleep 1
     if [[ -n "$PID_internet" ]]; then
         # Get the UID of the process owner
             echo "$PROCESS_NAME is running under internet uid: ($PID_internet). add slice_internet to iptables"
             add_iptables_rules_user_id_1003
             add_iptables_1003=1
           echo "add_iptables_1003=1"
        else 
       echo "$FIREFOX_PATH Not Found ($internet_uid)"
       remove_iptables_rules_user_id_1003
       add_iptables_1003=0
       echo "add_iptables_1003=1"
fi
}

while true; do
monitor_firefox_for_user_local
monitor_firefox_for_user_internet
done
