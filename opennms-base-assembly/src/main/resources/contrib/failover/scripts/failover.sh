#!/bin/bash
## sub definition
syncOn() {
        TEMP=$(mktemp)
        /usr/bin/crontab -l > $TEMP
        /bin/sed -i -e '/^\s*$/d'  $TEMP
        /bin/grep sync.sh $TEMP >/dev/null
        if [ $? != 0 ]; then
                cat  >> $TEMP <<AAAAA
0 0 * * *       /opt/opennms/contrib/failover/scripts/sync.sh
AAAAA
                /usr/bin/crontab -u root $TEMP
                service crond restart
        fi
        return $?
}
## start work
syncOn
/etc/rc.d/init.d/postgresql start
OPENNMS_DUMP=/var/opennms/rrd
DB_NAME=opennms

dropDb() {
        service jmp-watchdog stop
        service jmp-opennms stop
        psql -U opennms postgres -c 'drop database opennms;'
        psql -U opennms postgres -c "create database opennms encoding 'unicode'"
}

if [ -e $OPENNMS_DUMP/opennms.sql ]; then
	dropDb
       var1=$(stat -c%s $OPENNMS_DUMP/opennms.sql)
       var2=$(stat -c%s $OPENNMS_DUMP/opennms.sql.bk)
       if [[ "$var2" -gt "$var1" ]]; then
               echo "bk is bigger than sql, using bk version"
               /bin/cp $OPENNMS_DUMP/opennms.sql.bk $OPENNMS_DUMP/opennms.sql
       fi

       psql -U opennms $DB_NAME < $OPENNMS_DUMP/opennms.sql

	service jmp-watchdog start
fi
/etc/rc.d/init.d/opennms start

