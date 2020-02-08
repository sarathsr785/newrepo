#!/bin/bash
clear
setenforce 0 >> /dev/null 2>&1

#FILEREPO=http://files.virtualizor.com
LOG=/root/maintain.log
touch $LOG
#----------------------------------
# Detecting the Architecture
#----------------------------------
if ([ `uname -i` == x86_64 ] || [ `uname -m` == x86_64 ]); then
        echo "ARCH=64"
else
        echo "ARCH=32"
fi

echo "-----------------------------------------------"
echo " Welcome to  Installer"
echo "-----------------------------------------------"
echo " "
if ! [ -f /usr/bin/yum ] ; then
                echo "YUM wasnt found on the system. Please install YUM !"
                echo "Exiting installer"
                exit 1;
        fi
yum update

echo "1)Changing SSH Port"


if [ -e "/etc/ssh/sshd_config" ];then
[ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
echo $ssh_port

if [ $ssh_port == "22" ]; then


#if   [ -f  $ssh_port=="22" ] ; then

while :; do echo
read -p "Please input SSH port(Default: $ssh_port): " SSH_PORT
[ -z "$SSH_PORT" ] && SSH_PORT=$ssh_port
if [ $SSH_PORT -eq 22 >/dev/null 2>&1 -o $SSH_PORT -gt 1024 >/dev/null 2>&1 -a $SSH_PORT -lt 65535 >/dev/null 2>&1 ];then
break
else
echo "${CWARNING}input error! Input range: 22,1025~65534${CEND}"
fi
done
 if [ -z "`grep ^Port /etc/ssh/sshd_config`" -a "$SSH_PORT" != '22' ];then
sed -i "s@^#Port.*@&\nPort $SSH_PORT@" /etc/ssh/sshd_config
elif [ -n "`grep ^Port /etc/ssh/sshd_config`" ];then
sed -i "s@^Port.*@Port $SSH_PORT@" /etc/ssh/sshd_config
fi
service sshd restart
fi
fi

echo "ssh port is already custom port $ssh_port"


if ! [ -f /usr/sbin/csf ] ; then

echo "2) Installing CSF"
wget https://download.configserver.com/csf.tgz
tar -xzf csf.tgz
cd csf
sh install.sh $*  >>  $LOG 2>&1
phpret=$?
# Was there an error
if ! [ $phpret == "8" ]; then
        echo " "
        echo "ERROR :"
        echo "There was an error while installing CSF"
   echo "Please check /root/maintain.log for errors"
        echo "Exiting Installer"
        exit 1;
fi

else
echo "csf is found"
fi

if [ -e "/etc/csf/csf.conf" ];then
TEST=`grep ^TESTING /etc/csf/csf.conf | grep -v 'TESTING_INTERVAL' | awk '{print $3}' | cut -d'"'  -f2`
echo $TEST
if [ $TEST == "1" ]; then
sed -i 's/TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
csf -r
fi
fi



if ! [ -f /usr/local/sbin/maldet  ] ; then

echo "2) Installing Maldet"
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar -xzvf maldetect-current.tar.gz
cd maldetect-*
sh install.sh $*  >>  $LOG 2>&1
#phpret=$?
# Was there an error
#if ! [ $phpret == "8" ]; then
 #       echo " "
 #       echo "ERROR :"
 #       echo "There was an error while installing Maldet"
 #  echo "Please check /root/maintain.log for errors"
 #       echo "Exiting Installer"
 #       exit 1;
#fi

else
echo "maldet is found"
fi

if ! [ -f /usr/local/cpanel/whostmgr/docroot/cgi/configserver/cse/cse.conf  ] ; then

echo "2) Installing CSE "
wget https://download.configserver.com/cse.tgz
tar -xzf cse.tgz
cd cse
sh install.sh

else
echo "cse is found"
fi

if ! [ -f /etc/cmq/cmq.conf  ] ; then

echo "2) Installing CMQ "
wget http://download.configserver.com/cmq.tgz
tar -xzf cmq.tgz
cd cmq
sh install.sh

else
echo "CMQ is found"
fi


if ! [ -f /usr/local/cpanel/whostmgr/docroot/cgi/configserver/cmm/cmm.conf  ] ; then

echo "2) Installing CMM "
wget http://download.configserver.com/cmm.tgz
tar -xzf cmm.tgz
cd cmm
sh install.sh
else
echo "CMM is found"
fi

if ! [ -f /usr/local/cpanel/whostmgr/docroot/cgi/configserver/cmc/cmc.conf  ] ; then

echo "2) Installing CMC "
wget http://download.configserver.com/cmc.tgz
tar -xzf cmc.tgz
cd cmc
sh install.sh
else
echo "CMC is found"
fi


while true; do
    read -p "Do you wish to secure tmp partition?" yn
    case $yn in
        [Yy]* ) /scripts/securetmp; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "Do you wish to Install Immuinfy?" yn
    case $yn in
        [Yy]* ) wget https://repo.imunify360.cloudlinux.com/defence360/imav-deploy.sh
		bash imav-deploy.sh; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "Do you wish to Enable Shell Fork Bomb Protection?" yn
    case $yn in
        [Yy]* ) /usr/local/cpanel/bin/install-login-profile --install limits;
echo "Protection Enabled";
 break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "Do you wish to Disable WHM Terminal Feature?" yn
    case $yn in
        [Yy]* ) touch  /var/cpanel/disable_whm_terminal_ui;
        echo "Terminal Disabled";
                break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

 echo "=== TweaK Settings Custom ==="

    if [ -f /usr/local/cpanel/bin/whmapi1 ]; then
        cp -pr /var/cpanel/cpanel.config /usr/ 
        /usr/local/cpanel/bin/whmapi1 set_tweaksetting key=referrerblanksafety value=1
        /usr/local/cpanel/bin/whmapi1 set_tweaksetting key=referrersafety value=1
    else
        if grep -Fxq "^referrer" /var/cpanel/cpanel.config; then
            sed -i 's/^referrerblanksafety=.*/referrerblanksafety=1/' /var/cpanel/cpanel.config
            sed -i 's/^referrersafety=.*/referrersafety=1/' /var/cpanel/cpanel.config
        else
            echo "referrerblanksafety=1" >> /var/cpanel/cpanel.config
            echo "referrersafety=1" >> /var/cpanel/cpanel.config
        fi
        /usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings
    fi
  while true; do
    read -p "Do you wish to Scan Whole Server with CSI cpanel script?" yn
    case $yn in
        [Yy]* ) wget https://github.com/CpanelInc/tech-CSI/raw/master/csi.pl;
		/usr/local/cpanel/3rdparty/bin/perl csi.pl --full;
        echo "Scan Completed";
                break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done
 

