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
echo -e "${GREEN}${NOW} [+] Przed kontynuowaniem:${NC}"
echo -e "${GREEN}${NOW} [+] Przygotuj licencje MS SQL i kod licencyjny jesli jest wymagany${NC}"
echo -e "${GREEN}${NOW} [+] Ustal haslo dla MS SQL${NC}"
echo -e "${GREEN}${NOW} [+] Udostepnij folder dla backupu i ustal login i haslo${NC}"
echo -e ""

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


# set -x #debug mode

#stworz foldery
sudo mkdir -p /etc/vision

#Podaj hasło do instancji mssql #TO DO password match
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

sudo touch /etc/vision/backup.ini
#echo "sqllogin=sa" | sudo tee -a /etc/vision/backup.ini
echo "sqllogin=sa" | sudo tee -a /etc/vision/backup.ini >/dev/null
echo "sqlpass=${sqlpass}" | sudo tee -a /etc/vision/backup.ini >/dev/null
echo "serveradress=${ipadress}" | sudo tee -a /etc/vision/backup.ini >/dev/null


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
            echo -e "${GREEN}${NOW} [+] MS SQL Server nie jest zainstalowany, instaluje.${NC}" 
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
		echo -e "${GREEN}${NOW} [+] MS SQL Server jest juz zainstalowany.${NC}"
            
    fi
    


#systemctl status mssql-server --no-pager

# Sprawdz collation - komenda do sprawdzenia
if /opt/mssql-tools18/bin/sqlcmd -S 192.168.68.85 -U sa -P Protel915930 -C -Q "SELECT CONVERT (varchar(256), SERVERPROPERTY('collation'));" | grep -w 'Polish_CI_AS' -q;
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

#pobiez backup script
wget https://raw.githubusercontent.com/Frostoriginal/Vision/refs/heads/main/backup.sh
sudo chmod +x /etc/vision/backup.sh
sudo cp backup.sh /etc/vision/backup.sh
rm backup.sh
#Dodaj skrypt do CRONa
echo "0 * * * * /etc/vision/backup.sh" | sudo tee -a /var/spool/cron/crontabs/root #Cron job every hour
# wykonaj skrypt po raz 1
sudo /etc/vision/backup.sh



#info - po reboocie sprawdź: godzinę, czy dysk się zamontował, czy system wykonuje backupy
#sudo reboot






