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
NOW="$(date +"%Y-%m-%d %T")"
ipadress=$(hostname -I)

#Ekran powitalny
echo -e "${GREEN}${NOW} [+] Skrypt przeprowadzi cie przez instalacje MSSQL.${NC}"
#przed kontynuowaniem przygotuj
#licencje sql
#haslo dla sql
#user i haslo dla smb

if hostnamectl | grep '22.04' -q;
  then
    echo -e "${GREEN}${NOW} [+] Wersja systemu jest poprawna${NC}"
  else
  echo -e "${RED}${NOW} [!] Niepoprawna wersja systemu!${NC}\n"
  echo -e "${GREEN}${NOW} [+] Skrypt jest przygotowany dla ubuntu w wersji 22.04, czy chcesz kontynuować?${NC}"

#Czy chcesz kontynuować
select continue in "Tak" "Nie"; do
		case $continue in
		Tak ) 		
		echo -e "${GREEN}${NOW}[+] Kontynuujemy.${NC}\n"
		break;;
	
		Nie ) exit;;
		esac
		done	
fi


#Podaj hasło do instancji mssql
echo -e "${GREEN}${NOW} [+] Podaj hasło dla SQL Server, minimum 8 znaków, małe i duże litery, cyfry:${NC}"
while read -s pass; do
	if [[ $pass = "" ]];
	then
	echo -e "${RED}${NOW} [!] Password cannot be empty, please type in your password:${NC}"
	else
	break;
	fi
done
sqlpass=$pass

echo -e "${GREEN}${NOW} [+] Adres serwera to: ${ipadress} ${NC}"

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

#zmiana czasu
if date | grep -w 'CEST' -q;
  then
    echo -e "${GREEN}${NOW} [+] Strefa czasowa jest poprawna${NC}"
  else
  echo -e "${RED}${NOW} [!] Niepoprawna strefa czasowa!${NC}\n"
  #zmiana czasu
echo -e "${GREEN}${NOW} [+] Zmieniam strefę czasową${NC}"
#zmiana lokalizacji, zegar na 24h //czy jest to potrzebne?
#localectl set-locale LC_TIME="en_GB.UTF-8" 
sudo timedatectl set-timezone Europe/Warsaw
echo -e "${Orange}${NOW} [+] Sprawdz czy data jest poprawna${NC}"
date
fi

#sprawdz czy juz nie ma MSSQL Server
dpkg -s mssql-server &> /dev/null  

    if [ $? -ne 0 ]

        then
            echo "not installed" 
	    #rozpoczęcie instalacji
	echo -e "${GREEN}${NOW} [+] Instaluje MSSQL zgodnie z artykułem: https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu?view=sql-server-linux-ver16&preserve-view=true&tabs=ubuntu2204.${NC}"

	echo -e "${GREEN}${NOW} [+] Pobieram GPG${NC}"
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
	curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
	
	echo -e "${GREEN}${NOW} [+] Dodaje repozytorium${NC}"
	curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list
	
	echo -e "${GREEN}${NOW} [+] Instaluje MS SQL Server${NC}"
	sudo apt-get update
	sudo apt-get install -y mssql-server
	echo -e "${GREEN} [+] MSSQL Server zainstalowany, przechodzę do konfiguracji:${NC}"

	#{echo "${sqllicense}"; echo "Yes";echo "${sqlpass}"; echo "${sqlpass}"; } | sudo /opt/mssql/bin/mssql-conf setup
	sudo /opt/mssql/bin/mssql-conf setup
            

        else
            echo    "MS SQL Server jest juz zainstalowany."
    fi
    


#systemctl status mssql-server --no-pager

if sqlcmd -S 192.168.68.85 -U sa -P Protel915930 -C -Q "SELECT CONVERT (varchar(256), SERVERPROPERTY('collation'));" | grep -w 'Polish_CI_AS' -q;
	then
	echo -e "${GREEN}${NOW} [+] Strona kodowania jest poprawna${NC}"
	else
	echo -e "${RED}${NOW} [!] Strona kodowania nie jest poprawna${NC}\n"
	#zmiana kodowania
	echo -e "${GREEN}${NOW} [+] Zatrzymuję server SQL${NC}"
	sudo systemctl stop mssql-server
	echo -e "${GREEN}${NOW} [+] Zmieniam kodowanie${NC}"
	echo "Polish_CI_AS" | sudo /opt/mssql/bin/mssql-conf set-collation
	echo -e "${GREEN}${NOW} [+] Uruchamiam server SQL${NC}"
	sudo systemctl start mssql-server
fi


echo -e "${GREEN}${NOW} [+] Sprawdź status:${NC}"
systemctl status mssql-server --no-pager
#TO DO dodac grep check
#sprawdz toolsetu czy juz nie ma
dpkg -s mssql-tools18 &> /dev/null  

    if [ $? -ne 0 ]

        then
           echo -e "${RED}${NOW} [!]  SQL Server command-line tools nie jest zainstalowany${NC}\n"
	    #instalacja toolsetu
		echo -e "${GREEN}${NOW} [+] Instaluje SQL Server command-line tools${NC}"
		curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
		curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
		sudo apt-get update
		sudo apt-get install mssql-tools18 unixodbc-dev
		sudo apt-get update
		sudo apt-get install mssql-tools18
		echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bash_profile
		source ~/.bash_profile
            

        else
           echo -e "${GREEN}${NOW} [+] SQL Server command-line tools jest już zainstalowany${NC}"
    fi




#ustawianie instancji SQL
#ustawić pamięć
#ustawić logowanie mieszane


#ustawianie bazy
#TO DO dodac skrypt do tworzenia bazy
#dodanie mountów
#pytanie czy chcesz dodać, muszą już istnieć foldery w windows i użytkownicy!
#podaj ip windowsa
#tworzę directory
# sudo mkdir -p /mnt/shared/SQLBackup

#podaj login i haslo do smb
#TO DO dodac mount dla dysku windows
# sudo echo "//{IP}/SQLBackup /mnt/shared/SQLBackup cifs credentials=/etc/samba/passwd_file 0 0" >> /etc/fstab 
#sudo mkdir /etc/samba
#echo -e "username=test\npassword=test" | sudo tee -a /etc/samba/passwd_file

#set -x
#debug
#wykonaj pierwszy backu
echo -e "${GREEN}${NOW} [+] Tworzę pierwszy backup${NC}"
sqlcmd -S $ipadress -U sa -P $sqlpass -C -Q 'BACKUP DATABASE [protel] TO DISK = N'\''/mnt/shared/SQLBackup/protel.bak'\'' WITH NOFORMAT, NOINIT, NAME = '\''protel-full'\'', SKIP, NOREWIND, NOUNLOAD, STATS = 10'
set +x
#baza
echo -e "${GREEN}${NOW} [+] Dodaje backup do CRONa${NC}"
#dobowe pełne
#sqlcmd -S IP! -U sa -P passforsql -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
command='sqlcmd -S '$ipadress' -U sa -P '$sqlpass' -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"'
job="0 0 * * 0 $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

#logi
#sqlcmd -S IP! -U sa -P passforsql -C -Q "BACKUP LOG [protel] TO DISK = N'/mnt/shared/SQLBackup/protel_log.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-log', SKIP, NOREWIND, NOUNLOAD, STATS = 5"
command='sqlcmd -S '$ipadress' -U sa -P '$sqlpass' -C -Q "BACKUP LOG [protel] TO DISK = N'/mnt/shared/SQLBackup/protel_log.bak' WITH NOFORMAT, NOINIT, NAME = 'protel-log', SKIP, NOREWIND, NOUNLOAD, STATS = 5"'
job="0 0 * * 0 $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -
#godzinne
#sqlcmd -S localhost -U sa -P passforsql -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"
command='sqlcmd -S '$ipadress' -U sa -P '$sqlpass' -C -Q "BACKUP DATABASE [protel] TO DISK = N'/mnt/shared/SQLBackup/protel.bak' WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = 'protel-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"'
job="0 0 * * 0 $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -

#info - po reboocie sprawdź: godzinę, czy dysk się zamontował, czy system wykonuje backupy
#sudo reboot






