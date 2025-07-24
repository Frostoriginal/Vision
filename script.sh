#!/bin/bash
#init color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#init variables
sqlpass=default
sqllicense=3
sqllicensecode=0

#Ekran powitalny
echo -e "${GREEN}[+] Skrypt przeprowadzi cie przez instalacje MSSQL.${NC}"
echo -e "${GREEN}[+] Skryp jest przygotowany dla ubuntu w wersji 22.04, czy chcesz kontynuować?${NC}"

#Czy chcesz kontynuować
select continue in "Tak" "Nie"; do
		case $continue in
		Tak ) 		
		echo -e "${GREEN}[+] Kontynuujemy.${NC}\n"
		break;;
	
		Nie ) exit;;
		esac
		done	

#Podaj hasło do instancji mssql
while read -s pass; do
	if [[ $pass = "" ]];
	then
	echo -e "${RED}[!] Password cannot be empty, please type in your password:${NC}"
	else
	break;
	fi
done
sqlpass=$pass

#zmiana czasu
sudo dpkg0reconfigure tzdata

#rozpoczęcie instalacji
echo -e "${GREEN}[+] Instaluje MSSQL zgodnie z artykułem: https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu?view=sql-server-linux-ver16&preserve-view=true&tabs=ubuntu2204.${NC}"

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list

sudo apt-get update
sudo apt-get install -y mssql-server
# {echo 'pass'; echo 'pass; } | sudo /opt/mssql/bin/mssql-conf setup
sudo /opt/mssql/bin/mssql-conf setup

systemctl status mssql-server --no-pager

#zmiana kodowania
echo -e "${GREEN}[+] Zmieniam kodowanie${NC}"

sudo systemctl stop mssql-server
echo "Polish_CI_AS" | sudo /opt/mssql/bin/mssqql-conf set-collation
sudo systemctl start mssql-server
#ustawianie instancji SQL
#ustawić pamięć
#ustawić logowanie mieszane


#ustawianie bazy

#dodanie mountów

#backup bazy
# dodaj do crona
#In Ubuntu and many other distros, you can just put a file into the /etc/cron.d directory containing a single line with a valid crontab entry. No need to add a line to an existing file.
#If you just need something to run daily, just put a file into /etc/cron.daily. Likewise, you can also drop files into /etc/cron.hourly, /etc/cron.monthly, and /etc/cron.weekly.

#baza
#sqlcmd -S localhost -U sa -P passforsql -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
#logi
#sqlcmd -S localhost -U sa -P passforsql -Q "BACKUP LOG [protel] TO DISK = N'/mnt/shared/SQLBackup/protel_log.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-log', SKIP, NOREWIND, NOUNLOAD, STATS = 5"






