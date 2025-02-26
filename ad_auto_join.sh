#!/bin/bash

set -e

DOMAIN="DEINE.DOMÄNE"
ADMIN_USER="Administrator" # AD-Admin-Konto für den Beitritt

# Erkennung der Linux-Distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  else
    echo "unbekannt"
  fi
}

DISTRO=$(detect_distro)
echo "Erkannte Distribution: $DISTRO"

# Paketinstallation basierend auf Distribution
install_packages() {
  case "$DISTRO" in
  ubuntu | debian)
    sudo apt update && sudo apt install -y realmd sssd samba-common-bin krb5-user adcli packagekit
    ;;
  fedora | centos | rhel)
    sudo dnf install -y realmd sssd samba-common krb5-workstation oddjob oddjob-mkhomedir adcli
    ;;
  arch)
    sudo pacman -Sy --noconfirm realmd sssd samba krb5 adcli
    ;;
  suse | opensuse)
    sudo zypper install -y realmd sssd samba krb5-client adcli
    ;;
  *)
    echo "Nicht unterstützte Distribution!"
    exit 1
    ;;
  esac
}

# AD-Integration durchführen
join_ad() {
  echo "DNS-Server auf AD setzen..."
  echo "nameserver <AD_IP>" | sudo tee /etc/resolv.conf

  echo "System in AD-Domäne einbinden..."
  echo "Bitte gib das Passwort für $ADMIN_USER ein:"
  sudo realm join "$DOMAIN" -U "$ADMIN_USER"

  echo "AD-Login aktivieren..."
  sudo realm permit --all
}

# Lokalen Benutzer entfernen
remove_local_user() {
  LOCAL_USER=$(whoami)
  echo "Lösche lokalen Benutzer: $LOCAL_USER"
  sudo deluser --remove-home "$LOCAL_USER" || sudo userdel -r "$LOCAL_USER"
}

install_packages
join_ad
remove_local_user

sudo systemctl restart sssd

echo "Fertig! Das System wird jetzt neu gestartet. Bitte mit einem AD-Konto anmelden."

# Neustart des Systems
sudo reboot
