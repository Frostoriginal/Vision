#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export DISPLAY=:0.0

#import variables                                                                                                                       
source /etc/vision/backup.ini 

# Define the backup directory
backup_dir="/shared/windows_mount/"
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

touch $backup_dir/${timestamp}_log.txt

### Backupy ###
#Petla backup 
for dbname in $databases
do
if /opt/mssql-tools18/bin/sqlcmd -S ${serveradress} -U ${sqllogin} -P ${sqlpass} -C -Q "SELECT name FROM master.sys.databases WHERE name = N'${dbname}'" | grep -w '${dbname}' -q; then
echo "${timestamplog}|Baza danych ${dbname} istnieje, tworze backupy" >> $backup_dir/${timestamp}_log.txt    
#Backup dobowy
 if ls $fulldir | grep -w ${timestamp}${dbname}.bak -q;
  then
    echo "${timestamplog}|Dzisiejszy backup bazy ${dbname} juz istnieje" >> $backup_dir/${timestamp}_log.txt
  else
    if /opt/mssql-tools18/bin/sqlcmd -S ${serveradress} -U ${sqllogin} -P ${sqlpass} -C -Q "BACKUP DATABASE [${dbname}] TO DISK = N'${fulldir}/${timestamp}${dbname}.bak' WITH NOFORMAT, NOINIT, NAME = '${dbname}-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10" ; then
    echo "${timestamplog}|Stworzylem dzisiejszy backup bazy ${dbname}" >> $backup_dir/${timestamp}_log.txt  
    else
	echo "${timestamplog}|Blad przy tworzeniu backupu bazy ${dbname}" >> $backup_dir/${timestamp}_log.txt
	fi
 fi

#logi
 if ls $logdir | grep -w ${timestamp}${dbname}_log.bak -q;
  then
    echo "${timestamplog}|Dzisiejszy backup logow bazy ${dbname} juz istnieje" >> $backup_dir/${timestamp}_log.txt
  else
    if /opt/mssql-tools18/bin/sqlcmd -S ${serveradress} -U ${sqllogin} -P ${sqlpass} -C -Q "BACKUP LOG [${dbname}] TO DISK = N'${logdir}/${timestamp}${dbname}_log.bak' WITH NOFORMAT, NOINIT, NAME = '${dbname}-log', SKIP, NOREWIND, NOUNLOAD, STATS = 5"; then     
	echo "${timestamplog}|Stworzylem dzisiejszy backup logow bazy ${dbname}" >> $backup_dir/${timestamp}_log.txt
    else
	echo "${timestamplog}|Blad przy tworzeniu backupu logow bazy ${dbname}" >> $backup_dir/${timestamp}_log.txt
	fi
 fi

#Backup godzinny
 if ls $diffdir | grep -w ${timestampfull}${dbname}.bak -q;
  then
    echo "${timestamplog}|Backup bazy ${dbname} z godziny juz istnieje" >> $backup_dir/${timestamp}_log.txt
  else
    if /opt/mssql-tools18/bin/sqlcmd -S ${serveradress} -U ${sqllogin} -P ${sqlpass} -C -Q "BACKUP DATABASE [${dbname}] TO DISK = N'${diffdir}/${timestampfull}${dbname}.bak' WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = '${dbname}-full', SKIP, NOREWIND, NOUNLOAD, STATS  = 10"; then
	echo "${timestamplog}|Stworzylem backup z godziny" >> $backup_dir/${timestamp}_log.txt
    else
    echo "${timestamplog}|Blad przy tworzeniu backupu z godziny" >> $backup_dir/${timestamp}_log.txt
    fi
 fi
else
echo "${timestamplog}|Baza danych protel nie istnieje" >> $backup_dir/${timestamp}_log.txt
fi
done

#Usun starsze niz 3 dni 
find ${backup_dir} -mtime +2 -type f -delete

#Zmiana uprawnien
echo "${timestamplog}|Zmieniam uprawnienia plikow w ${backup_dir}" >> $backup_dir/${timestamp}_log.txt
chmod -R 777 /shared/windows_mount/

echo "${timestamplog}|Koniec skryptu" >> $backup_dir/${timestamp}_log.txt
echo "${timestamplog}|==================================================" >> $backup_dir/${timestamp}_log.txt


