#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export DISPLAY=:0.0

#import variables                                                                                                                       
source /etc/vision/script.ini 

# Define the backup directory
backup_dir="/mnt/shared/SQLBackup"
fulldir=$backup_dir/full
diffdir=$backup_dir/diff
logdir=$backup_dir/log

# Create the backup directory if it doesn't exist
mkdir -p $fulldir
mkdir -p $diffdir
mkdir -p $logdir

# Define timestamps
timestamp=$(date +'%Y%m%d')
timestampfull=$(date +'%Y%m%d_%H')
timestamplog=$(date +'%Y.%m.%d_%H:%M:%S')

touch $backup_dir/${timestamp}log.txt

#Protel
#Backup dobowy
 if ls $fulldir | grep -w ${timestamp}protel.bak -q;
  then
    echo "${timestamplog}|Dzisiejszy backup bazy protel juz istnieje" >> $backup_dir/${timestamp}log.txt
  else
    echo "${timestamplog}|Stworzylem dzisiejszy backup bazy protel" >> $backup_dir/${timestamp}log.txt  
    /opt/mssql-tools18/bin/sqlcmd -S ${serveradress} -U ${sqllogin} -P ${sqlpass} -C -Q "BACKUP DATABASE [protel] TO DISK = N'${fulldir}/${timestamp}protel.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10" 
    echo "${timestamplog}|Stworzylem dzisiejszy backup" >> $backup_dir/${timestamp}log.txt
 fi

#logi
 if ls $logdir | grep -w ${timestamp}protel_log.bak -q;
  then
    echo "${timestamplog}|Dzisiejszy backup logow juz istnieje" >> $backup_dir/${timestamp}log.txt
  else
    echo "${timestamplog}|Stworzylem dzisiejszy backup logow" >> $backup_dir/${timestamp}log.txt
    /opt/mssql-tools18/bin/sqlcmd -S ${serveradress} -U ${sqllogin} -P ${sqlpass} -C -Q "BACKUP LOG [protel] TO DISK = N'${logdir}/${timestamp}protel_log.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-log', SKIP, NOREWIND, NOUNLOAD, STATS = 5"     
	echo "${timestamplog}|Stworzylem dzisiejszy backup logow" >> $backup_dir/${timestamp}log.txt
 fi

#Backup godzinny
 if ls $diffdir | grep -w ${timestampfull}protel.bak -q;
  then
    echo "${timestamplog}|Backup z godziny juz istnieje" >> $backup_dir/${timestamp}log.txt
  else
    if /opt/mssql-tools18/bin/sqlcmd -S ${serveradress} -U ${sqllogin} -P ${sqlpass} -C -Q "BACKUP DATABASE [protel] TO DISK = N'${diffdir}/${timestampfull}protel.bak' WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS  = 10"; then
	echo "${timestamplog}|Stworzylem backup z godziny" >> $backup_dir/${timestamp}log.txt
    else
    echo "${timestamplog}|Blad przy tworzeniu backupu z godziny" >> $backup_dir/${timestamp}log.txt
    fi
 fi

#Usun starsze niz 3 dni 
find ${backup_dir} -mtime +2 -type f -delete

#Zmiana uprawnien
echo "${timestamplog}|Zmieniam uprawnienia" >> $backup_dir/${timestamp}log.txt
chmod -R 777 /mnt/shared

echo "${timestamplog}|Koniec skryptu" >> $backup_dir/${timestamp}log.txt
echo "${timestamplog}|==================================================" >> $backup_dir/${timestamp}log.txt


