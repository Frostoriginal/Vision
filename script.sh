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

#Podaj adres udzialu windows
echo -e "${GREEN}${NOW} [+] Podaj adres udzialu windows(//ip/folder): ${NC}"
echo -e "${GREEN}${NOW} [+] Przyklad: //192.168.0.5/SQLBackup ${NC}"
while read cifsdir; do
	if [[ $cifsdir = "" ]];
	then
	echo -e "${RED}${NOW} [!] Adres udziału nie moze byc pusty, podaj adres udzialu:${NC}"
	else
	break;
	fi
done

#Podaj login udzialu windows
echo -e "${GREEN}${NOW} [+] Podaj login udzialu: ${NC}"
while read cifslogin; do
	if [[ $cifslogin = "" ]];
	then
	echo -e "${RED}${NOW} [!] Login udziału nie moze byc pusty, podaj login udzialu:${NC}"
	else
	break;
	fi
done

#Podaj haslo udzialu windows
echo -e "${GREEN}${NOW} [+] Podaj haslo udzialu windows: ${NC}"
while read -s cifspass; do
	if [[ $cifspass = "" ]];
	then
	echo -e "${RED}${NOW} [!] Haslo udziału nie moze byc puste, podaj haslo udzialu:${NC}"
	else
	break;
	fi
done

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


echo -e "${GREEN}${NOW} [+] Adres serwera to: ${ipadress} ${NC}"

#Podaj nazwy baz danych
echo -e "${GREEN}${NOW} [+] Podaj nazwy baz danych, oddzielone spacjami: ${NC}"
while read -s databases; do
	if [[ $databases = "" ]];
	then
	echo -e "${RED}${NOW} [!] Nazwy baz danych nie moga byc puste, wpisz nazwy baz danych${NC}"
	else
	break;
	fi
done

echo -e "${GREEN}${NOW} [+] Zapisuje wszystkie ustawienia w /etc/vision/backup.ini ${NC}"
#resetuj ini i zapisz ustawienia
sudo rm /etc/vision/backup.ini
sudo touch /etc/vision/backup.ini
echo "sqllogin=sa" | sudo tee -a /etc/vision/backup.ini >/dev/null
echo "sqlpass=${sqlpass}" | sudo tee -a /etc/vision/backup.ini >/dev/null
echo "serveradress=${ipadress}" | sudo tee -a /etc/vision/backup.ini >/dev/null
echo "databases='${databases}'" | sudo tee -a /etc/vision/backup.ini >/dev/null


#zmiana locale
if locale | grep pl_PL -q;
  then
    echo -e "${GREEN}${NOW} [+] Lokalizacja jest poprawna${NC}"
  else
  echo -e "${RED}${NOW} [!] Niepoprawna lokalizacja!${NC}\n"
  echo -e "${GREEN}${NOW} [+] Zmieniam lokalizacje${NC}"
  sudo locale-gen pl_PL
  sudo locale-gen pl_PL.UTF-8
  sudo update-locale LC_ALL=pl_PL.UTF-8 LANG=pl_PL.UTF-8
  source /etc/default/locale
  sudo localectl set-locale LC_TIME="pl_PL.UTF-8" 
  sudo update-locale LC_TIME="pl-PL.UTF-8"
fi

#zmiana strefy czasowej
if date | grep -w 'CEST' -q;
  then
    echo -e "${GREEN}${NOW} [+] Strefa czasowa jest poprawna${NC}"
  else
  echo -e "${RED}${NOW} [!] Niepoprawna strefa czasowa!${NC}\n"
  
echo -e "${GREEN}${NOW} [+] Zmieniam strefę czasową${NC}"

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
			if locale | grep pl_PL -q;
			then
			(echo "5"; echo "No"; echo "Yes"; echo "1"; echo "${sqlpass}"; echo "${sqlpass}"; ) | sudo /opt/mssql/bin/mssql-conf setup
			else
			(echo "5"; echo "No"; echo "Yes"; echo "${sqlpass}"; echo "${sqlpass}"; ) | sudo /opt/mssql/bin/mssql-conf setup
			fi
			
			#sudo /opt/mssql/bin/mssql-conf setup
        else
		echo -e "${GREEN}${NOW} [+] MS SQL Server jest juz zainstalowany.${NC}"
            
    fi
    
#Uruchom MS SQL Server
sudo systemctl start mssql-server

#sprawdz czy MS SQL Server jest aktywny
echo -e "${GREEN}${NOW} [+] Sprawdź status:${NC}"
systemctl status mssql-server --no-pager

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
		sudo apt-get install mssql-tools18 unixodbc-dev -y
		sudo apt-get update
		sudo apt-get install mssql-tools18 -y
		echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bash_profile
		source ~/.bash_profile
        else
           echo -e "${GREEN}${NOW} [+] SQL Server command-line tools jest już zainstalowany${NC}"
    fi

# Sprawdz collation
echo -e "${GREEN}${NOW} [+] Sprawdam strone kodowania:${NC}"
if /opt/mssql-tools18/bin/sqlcmd -S ${ipadress} -U sa -P ${sqlpass} -C -Q "SELECT CONVERT (varchar(256), SERVERPROPERTY('collation'));" | grep -w 'Polish_CI_AS' -q;
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


#ustawianie instancji SQL
#ustawić pamięć
#ustawić logowanie mieszane
#ustawianie bazy
#wget skrypt -> /etc/vision/base.sql
#sqlcmd -S myServer\instanceName -i C:\scripts\myScript.sql -> utworz baze ze skryptu?
if /opt/mssql-tools18/bin/sqlcmd -S 192.168.68.92 -U sa -P Protel915930 -C -Q "SELECT name FROM master.sys.databases WHERE name = N'protel'" | grep -w 'protel' -q;
	then
	echo -e "${GREEN}${NOW} [+] Baza protel juz istnieje${NC}"
	else
	echo -e "${GREEN}${NOW} [+] Tworze bazy z pliku${NC}"
	if /opt/mssql-tools18/bin/sqlcmd -S ${ipadress} -U sa -P ${sqlpass} -C -i /etc/vision/base.sql
		then
		echo -e "${GREEN}${NOW} [+] Poprawnie wgrano baze ${dbname}${NC}"
		else
		echo -e "${RED}${NOW} [!] Blad przy dodawaniu bazy${NC}\n"
    fi

fi






#TO DO dodac skrypt do tworzenia bazy
#dodanie mountów
#pytanie czy chcesz dodać, muszą już istnieć foldery w windows i użytkownicy!
#podaj ip windowsa
#tworzę directory
# sudo mkdir -p /mnt/shared/SQLBackup
#cifsdir=10.16.5.5/SQLBackup
#cifslogin=linux_sql
#cifspass=Visiontime1.
#podaj login i haslo do smb
#TO DO dodac mount dla dysku windows

if sudo cat /etc/fstab  | grep ${cifsdir} -q;
  then
    echo -e "${GREEN}${NOW} [+] Udzial sieciowy jest juz dodany${NC}"
  else
    echo -e "${GREEN}${NOW} [+] Tworze folder${NC}"
    sudo mkdir -p /shared/windows_mount  
    echo -e "${GREEN}${NOW} [+] Dodaje udzial sieciowy${NC}"
	echo "${cifsdir} /shared/windows_mount cifs vers=3.0,username=${cifslogin},password=${cifspass},iocharset=utf8,file_mode=0777,dir_mode=0777,uid=998,gid=998,nofail 0 0" | sudo tee -a /etc/fstab
    echo -e "${GREEN}${NOW} [+] Testuje udzial sieciowy${NC}"
    if sudo mount -a ; then
	echo -e "${GREEN}${NOW} [+] Udzial dodany poprawnie${NC}"
	else
	echo -e "${RED}${NOW} [!] Blad udzialu, sprawdz /etc/fstab ${NC}"
	fi
fi



#echo "${cifsdir} /shared/windows_mount cifs vers=3.0,username=${cifslogin},password=${cifspass},iocharset=utf8,file_mode=0777,dir_mode=0777,uid=998,gid=998,nofail 0 0" | sudo tee -a /etc/fstab
#mount -a

#pobiez backup script
wget https://raw.githubusercontent.com/Frostoriginal/Vision/refs/heads/main/backup.sh
sudo chmod +x backup.sh
sudo cp backup.sh /etc/vision/backup.sh
rm backup.sh


#Dodaj skrypt do CRONa TODO - grep check czy nie ma juz w cronie
if sudo cat /var/spool/cron/crontabs/root  | grep -w '/etc/vision/backup.sh' -q;
  then
    echo -e "${GREEN}${NOW} [+] Skrypt do backupu jest juz dodany do CRONa${NC}"
  else  
    echo -e "${GREEN}${NOW} [+] Dodaje skrypt do backupu do CRONa${NC}"
    echo "0 * * * * /etc/vision/backup.sh" | sudo tee -a /var/spool/cron/crontabs/root #Cron job every hour

fi


# wykonaj skrypt po raz 1
sudo /etc/vision/backup.sh


#info - po reboocie sprawdź: godzinę, czy dysk się zamontował, czy system wykonuje backupy
echo -e "${GREEN}${NOW} [+] Skrypt zakonczył działanie${NC}"
echo -e "${GREEN}${NOW} [+] Po ponownym uruchomieniu sprawdz czy godzina/strefa czasowa jest poprawna oraz czy zamontowal sie dysk do backupow ${NC}"
for ((i = 10 ; i > 0 ; i-- )); do
echo -e "${GREEN}${NOW} [+] Ponowne uruchomienie za: ${i}s${NC}"
/bin/sleep 1 
 
 done
 sudo reboot
