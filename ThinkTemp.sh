#!/bin/bash

# ThinkTemp: Monitorizare temperatură în timp real
# Acest script monitorizează temperatura HDD-ului și a CPU-ului în timp real,
# înregistrează temperaturile într-un fișier și trimite notificări prin e-mail
# atunci când temperatura CPU depășește limita specificată.

# Dependințe:
# - hddtemp: Pentru citirea temperaturii HDD-ului
# - lm-sensors: Pentru citirea temperaturii CPU-ului
# - ssmtp: Pentru trimiterea de e-mail-uri (configurat corespunzător)
# Pentru instalare în Arch Linux: sudo pacman -S hddtemp lm_sensors ssmtp

# Verificăm dacă scriptul este rulat cu sudo
if [ "$EUID" -ne 0 ]; then
    echo "Acest script trebuie rulat cu sudo pentru a accesa toate informațiile."
    exit 1
fi

TEMPERATURE_LIMIT=80.0  # Limita de temperatură pentru avertizare (cu zecimale)
EMAIL_RECIPIENT="your_email@example.com"  # Adresa de e-mail pentru notificări

get_hdd_temperature() {
    local temperature
    temperature=$(hddtemp -n /dev/sda | awk -F'°' '{print $1}')
    echo "$temperature"
}

get_cpu_temperature() {
    local temperature
    temperature=$(sensors | grep 'Core 0:' | awk '{print $3}' | sed 's/+//' | cut -d '.' -f 1)
    echo "$temperature"
}

send_notification_email() {
    local subject="ATENȚIE: Temperatura CPU a depășit limita!"
    local message="Temperatura CPU este de $1 °C, care depășește limita de $TEMPERATURE_LIMIT °C."
    echo -e "Subject:$subject\n$message" | ssmtp "$EMAIL_RECIPIENT"
}

while true; do
    clear
    echo "Temp Watchdog: Monitorizare temperatură în timp real"
    echo
    
    hdd_temperature=$(get_hdd_temperature)
    cpu_temperature=$(get_cpu_temperature)
    
    if [ -n "$hdd_temperature" ]; then
        echo "Temperatura HDD: $hdd_temperature °C"
    else
        echo "Nu s-a putut citi temperatura HDD-ului."
    fi
    
    if [ -n "$cpu_temperature" ]; then
        echo "Temperatura CPU: $cpu_temperature °C"
        
        # Înregistrează temperatura în fișier
        echo "$(date '+%Y-%m-%d %H:%M:%S') - HDD: $hdd_temperature °C, CPU: $cpu_temperature °C" >> temperature_log.txt
        
        if [ "$cpu_temperature" -gt "${TEMPERATURE_LIMIT//./}" ]; then
            echo "ATENȚIE: Temperatura CPU a depășit limita de $TEMPERATURE_LIMIT °C!"
            send_notification_email "$cpu_temperature"
        fi
    else
        echo "Nu s-a putut citi temperatura CPU-ului."
    fi
    
    echo "Apăsați Enter pentru a opri scriptul..."
    read -t 2 -N 1 input  # Așteaptă 2 secunde sau apăsarea unei taste
    
    if [ "$input" ]; then
        break  # Ieși din bucla while dacă a fost apăsată o tastă
    fi
done
