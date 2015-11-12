#!/bin/bash
DNSMASQ_CONFIG_DIR=/etc/dnsmasq.d

if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo.  It is needed to modify your DNSMasq config"
  exit
fi

ask_bool_question() {
  question=$1

  echo
  read -e -n 1 -p "$question [y/n]: " ANSWER
  case $ANSWER in
    [yY] ) return 0
      ;;
    [nN] ) return 1
      ;;
    * ) 
        ask_bool_question "$question"
        ;;
  esac
}

ask_routers() {
  echo
  read -e -p "What is the IP address of your first backend? " ROUTERIP
  if /bin/ping -c 1 "$ROUTERIP" &> /dev/null
  then
    BACKENDS="core:$ROUTERIP"
  else
    echo "We couldn't ping that.  Sorry, we can't proceed."
    exit
  fi
  n=0
  while $(ask_bool_question "Add another?")
  do
    ((n++))
    echo
    read -e -p "What is the IP address of your next backend? " ROUTERIP
    if /bin/ping -c 1 "$ROUTERIP" &> /dev/null
    then
      BACKENDS="$BACKENDS,router$n:$ROUTERIP"
    else
      echo "Could not ping that IP.  It will not be added."
      echo
    fi
  done
}

setup(){
  echo
  echo "===== LB Setup ====="
  if $(ask_bool_question "Do you want to terminate SSL?")
  then
    TERMINATE_SSL="y"
    SSL_ENV="-e SSL=1"
  else
    TERMINATE_SSL="n"
    SSL_ENV=""
  fi

  echo
  read -e -p "Enter a hostname for your LB (leave off api.): " LB_HOSTNAME
  echo
  
  echo
  ask_routers
  echo


  echo
  echo "==========="
  echo "Hostname: $LB_HOSTNAME"
  echo "Terminate SSL? $TERMINATE_SSL"
  echo "Backends:"
  echo $BACKENDS|perl -F',' -lane 'foreach my $x (@F){$x=~s/\:/ /g;print "\t$x"};'
  echo
  echo

  if ! $(ask_bool_question "Does this look right?")
  then
    exit 1
  fi
}

main_loop(){
  CID=$(docker run -d --hostname="${LB_HOSTNAME}" ${SSL_ENV} -e BACKENDS="${BACKENDS}" haproxy-cf-loadbalancer)
  CIP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CID})

  echo "Preparing DNS Masq with *.${LB_HOSTNAME} to resolve to ${CIP}"
  echo "address=/.${LB_HOSTNAME}/${CIP}" > ${DNSMASQ_CONFIG_DIR}/${CID}.conf
  systemctl restart dnsmasq
  echo "Restarted DNS Masq."
  echo
  echo "Container ID ${CID}"
  echo "Container IP ${CIP}"
  echo "Backends:"
  echo $BACKENDS|perl -F',' -lane 'foreach my $x (@F){$x=~s/\:/ /g;print "\tserver $x:80 check"};'
  echo ""
  echo "Press 1 to kill the LB"
  echo "Press 2 to quit but keep LB running in background"
  echo "Press 3 to SSH into the VM"
  echo "Press 4 to restart dnsmasq"
  echo
  read -n 1 -p "Input:" maininput
  case $maininput in
    1)
      rm ${DNSMASQ_CONFIG_DIR}/${CID}.conf
      systemctl restart dnsmasq.service
      docker kill ${CID}
      ;;
    2)
      ;;
    3)
      docker exec -it ${CID} /bin/bash
      main_loop
      ;;
    4)
      systemctl restart dnsmasq.service
      main_loop
      ;;
    *)
      read -n 1
      clear
      main_loop
      ;;
  esac
}

setup
main_loop

