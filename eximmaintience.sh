#!/bin/bash
clear
queue=$(exim -bpc)
echo " Current mail queue is:" $queue
echo "Mail summary in queue is"
exim -bp|grep "<"|awk {'print $4'}|cut -d"<" -f2|cut -d">" -f1|sort -n|uniq -c|sort -nr

if ! [ "$queue" -le "10" ]; then
while true; do
frozen=$(exim -bpu | grep frozen | awk {'print $3'}   | wc -l)
echo "total frozen mails:" $frozen

    read -p "Do you wish to  remove frozen mails ?" yn
    case $yn in
        [Yy]* ) exim -bpu | grep frozen | awk {'print $3'} | xargs exim -Mrm; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done
fi

while true; do
bounce=$(exim -bp | grep '<>'  | wc -l)
echo " Total bounced mail in the queue is:" $bounce
    read -p "Do you wish to  remove bounce mails ?" yn
    case $yn in
        [Yy]* ) exim -bp | grep '<>' | awk '/^ *[0-9]+[mhd]/{print "exim -Mrm " $3}' | bash; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Highest number of mail senders via dovecot login:"
egrep -o 'dovecot_login[^ ]+' /var/log/exim_mainlog | sort|uniq -c|sort -nk 1  | tail -n 5

echo " CWD Higest Mails"
awk '$3 ~ /^cwd/{print $3}' /var/log/exim_mainlog | sort | uniq -c | sed "s|^ *||g" | sort -nr | head -6


echo "Imap Bruteforce  IP Lists"
awk '/auth failed/ {for (i=1;i<=NF;i=i+1) if ($i~/rip/) print $i}' /var/log/maillog |sort|uniq -c|sort -n| tail 
echo "Imap Bruteforce  Email Acct  Lists"
awk '/auth failed/ {for (i=1;i<=NF;i=i+1) if ($i~/user/) print $i}' /var/log/maillog |sort|uniq -c|sort -n| tail



