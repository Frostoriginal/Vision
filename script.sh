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
sqllicense=5
sqllicensecode=0
smblogin=login
smbpass=smbpass

#Ekran powitalny
echo -e "${GREEN}[+] Skrypt przeprowadzi cie przez instalacje MSSQL.${NC}"
#przed kontynuowaniem przygotuj
#licencje sql
#haslo dla sql
#user i haslo dla smb
echo -e "${GREEN}[+] Skrypt jest przygotowany dla ubuntu w wersji 22.04, czy chcesz kontynuować?${NC}"

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
echo -e "${GREEN}[+] Podaj hasło dla SQL Server, minimum 8 znaków, małe i duże litery, cyfry:${NC}"
while read -s pass; do
	if [[ $pass = "" ]];
	then
	echo -e "${RED}[!] Password cannot be empty, please type in your password:${NC}"
	else
	break;
	fi
done

ip a

echo -e "${GREEN}[+] Podaj adres ip:${NC}"
while read -s ipadress; do
	if [[ $ipadress = "" ]];
	then
	echo -e "${RED}[!] Adres serwera nie może być pusty, podaj IP jeszcze raz:${NC}"
	else
	break;
	fi
done

echo -e "${GREEN}[+] Adres serwera to to:${ipadress} ${NC}"

#while [ -z "$sqlpass" ]; do
#  echo "Wpisz haslo do sql: "
#  read -s first
#  read -s -p "Wpisz haslo ponownie by potwierdzic: " second
#  if [ $first == $second ];
#  then
#    sqlpass=$first
#    echo "Hasla sa takie same, kontynuuje."
#  else
#    echo "Hasla sa inne, sprobuj jeszcze raz."
#    continue
#  fi
#  break
#done
sqlpass=$pass

#zmiana czasu
echo -e "${GREEN}[+] Zmieniam strefę czasową${NC}"
#zmiana lokalizacji, zegar na 24h //czy jest to potrzebne?
localectl set-locale LC_TIME="en_GB.UTF-8" 

#sudo dpkg0reconfigure tzdata
sudo timedatectl set-timezone Europe/Warsaw
echo -e "${GREEN}[+] Czy data jest poprawna${NC}"
date
#yes/no
echo -e "${GREEN}[+] Tak / nie${NC}"

#rozpoczęcie instalacji
echo -e "${GREEN}[+] Instaluje MSSQL zgodnie z artykułem: https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu?view=sql-server-linux-ver16&preserve-view=true&tabs=ubuntu2204.${NC}"

echo -e "${GREEN}[+] Pobieram GPG${NC}"
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

echo -e "${GREEN}[+] Dodaje repozytorium${NC}"
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list

echo -e "${GREEN}[+] Instaluje MS SQL Server${NC}"
sudo apt-get update
sudo apt-get install -y mssql-server
echo -e "${GREEN}[+] MSSQL Server zainstalowany, przechodzę do konfiguracji:${NC}"

#{echo "${sqllicense}"; echo "Yes";echo "${sqlpass}"; echo "${sqlpass}"; } | sudo /opt/mssql/bin/mssql-conf setup
sudo /opt/mssql/bin/mssql-conf setup

#systemctl status mssql-server --no-pager

#zmiana kodowania
echo -e "${GREEN}[+] Zatrzymuję server SQL${NC}"
sudo systemctl stop mssql-server
echo -e "${GREEN}[+] Zmieniam kodowanie${NC}"
echo "Polish_CI_AS" | sudo /opt/mssql/bin/mssql-conf set-collation
echo -e "${GREEN}[+] Uruchamiam server SQL${NC}"
sudo systemctl start mssql-server
echo -e "${GREEN}[+] Sprawdź status:${NC}"
systemctl status mssql-server --no-pager

#instalacja toolsetu
echo -e "${GREEN}[+] Instaluje SQL Server command-line tools${NC}"
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo apt-get install mssql-tools18 unixodbc-dev
sudo apt-get update
sudo apt-get install mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bash_profile
source ~/.bash_profile


#ustawianie instancji SQL
#ustawić pamięć
#ustawić logowanie mieszane


#ustawianie bazy

#dodanie mountów
#pytanie czy chcesz dodać, muszą już istnieć foldery w windows i użytkownicy!
#podaj ip windowsa
#tworzę directory
# sudo mkdir -p /mnt/shared/SQLBackup

#podaj login i haslo do smb

# sudo echo "//{IP}/SQLBackup /mnt/shared/SQLBackup cifs credentials=/etc/samba/passwd_file 0 0" >> /etc/fstab 
#sudo mkdir /etc/samba
#echo -e "username=test\npassword=test" | sudo tee -a /etc/samba/passwd_file

#backup bazy
# dodaj do crona
#In Ubuntu and many other distros, you can just put a file into the /etc/cron.d directory containing a single line with a valid crontab entry. No need to add a line to an existing file.
#If you just need something to run daily, just put a file into /etc/cron.daily. Likewise, you can also drop files into /etc/cron.hourly, /etc/cron.monthly, and /etc/cron.weekly.

#initial backup
echo -e "${GREEN}[+] Tworzę pierwszy backup${NC}"
sqlcmd -S IP! -U sa -P passforsql -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

#baza
echo -e "${GREEN}[+] Dodaje backup do CRONa${NC}"
#dobowe pełne
#sqlcmd -S IP! -U sa -P passforsql -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
command='sqlcmd -S IP! -U sa -P passforsql -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"'
job="0 0 * * 0 $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

#logi
#sqlcmd -S IP! -U sa -P passforsql -C -Q "BACKUP LOG [protel] TO DISK = N'/mnt/shared/SQLBackup/protel_log.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-log', SKIP, NOREWIND, NOUNLOAD, STATS = 5"
command='sqlcmd -S IP! -U sa -P passforsql -C -Q "BACKUP LOG [protel] TO DISK = N'/mnt/shared/SQLBackup/protel_log.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-log', SKIP, NOREWIND, NOUNLOAD, STATS = 5"'
job="0 0 * * 0 $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
#godzinne
#sqlcmd -S localhost -U sa -P passforsql -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
command='sqlcmd -S localhost -U sa -P passforsql -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"'
job="0 0 * * 0 $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -


#info - po reboocie sprawdź: godzinę, czy dysk się zamontował, czy system wykonuje backupy
#sudo reboot






