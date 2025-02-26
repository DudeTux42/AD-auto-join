# Active Directory Integration für Linux

Dieses Skript automatisiert die Integration eines Linux-Rechners in eine Windows Active Directory (AD)-Domäne, sodass sich Benutzer mit ihren AD-Anmeldeinformationen am Linux-Rechner anmelden können.

## Voraussetzungen

- Ein funktionierendes Active Directory (AD) mit einem verfügbaren DNS-Server.
- Die IP-Adresse des AD-Servers.
- Ein **Administrator**-Konto für das Joinen der Domäne.
- Die Linux-Distribution muss eine der unterstützten Versionen sein (Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, openSUSE).

## Voraussetzungen auf dem Linux-Rechner

- Der Linux-Rechner muss eine Netzwerkverbindung zum AD-Server haben.
- Die Uhrzeit des Linux-Rechners muss mit dem AD-Server synchronisiert sein (wichtig für Kerberos).
- Der Linux-Rechner muss den DNS-Server des AD-Servers nutzen können.

### Unterstützte Distributionen

Das Skript funktioniert mit folgenden Distributionen:
- Ubuntu/Debian
- Fedora/CentOS/RHEL
- Arch Linux
- openSUSE/SUSE

### Installierte Pakete

- `realmd`: Ermöglicht das Beitreten zu einer AD-Domäne.
- `sssd`: Verwendet Kerberos für die Authentifizierung und stellt die Benutzerinformationen bereit.
- `krb5-user`: Kerberos-Pakete für die Kommunikation mit dem AD-Server.
- `adcli`: Hilft beim Beitritt zu einer AD-Domäne.
- `samba`: Notwendig für die Interaktion mit Windows-Servern.

## Verwendung

### 1. Klonen des Repositories

Zuerst müssen Sie das Repository auf Ihrem Linux-Rechner klonen:

```bash
git clone https://github.com/DudeTux42/vb-auto-join.git
cd vb-auto-join
```

### 2. Skript ausführen

Stellen Sie sicher, dass das Skript ausführbar ist:

```bash
chmod +x ad_auto_join.sh
```

Führen Sie dann das Skript mit Administratorrechten aus:

```bash
sudo ./ad_auto_join.sh
```

Das Skript wird die folgenden Schritte ausführen:
1. Erkennung der Distribution und Installation der notwendigen Pakete.
2. Konfiguration der DNS-Auflösung für den AD-Server.
3. Beitritt des Linux-Rechners zur Active Directory-Domäne.
4. Aktivierung der Anmeldung mit AD-Konten.
5. Löschen des lokalen Benutzers und Neustart des Systems, sodass sich der Benutzer mit seinen AD-Anmeldeinformationen anmelden kann.

### 3. Eingabeaufforderungen

Während des Skriptlaufs müssen Sie:
- Das **Administrator-Passwort** für das Active Directory eingeben, um den Rechner in die Domäne aufzunehmen.
- Das Skript wird dann den lokalen Benutzer löschen und den Rechner neu starten.

### 4. Anmeldung mit AD-Konto

Nach dem Neustart können sich alle Benutzer, die in der AD-Domäne existieren, mit ihren AD-Anmeldeinformationen am Linux-Rechner anmelden.

## Serverseitige Anforderungen

Auf der Serverseite müssen folgende Punkte beachtet werden:
1. **Active Directory Benutzer**: Alle Benutzer, die sich am Linux-Rechner anmelden möchten, müssen im AD vorhanden sein.
2. **DNS-Konfiguration**: Der DNS-Server des AD muss korrekt konfiguriert sein, damit der Linux-Rechner den AD-Server auflösen kann.
3. **Zeit-Synchronisation**: Der Linux-Rechner muss mit dem AD-Server in der Zeit synchronisiert sein (wichtig für Kerberos).
4. **Gruppen und Berechtigungen**: Standardmäßig dürfen sich alle AD-Benutzer anmelden. Wenn Sie den Zugang auf bestimmte Gruppen beschränken möchten, können Sie dies mit `realm permit` tun.

### Konfiguration der Berechtigungen

Um den Zugriff auf bestimmte Gruppen zu beschränken, können Sie beispielsweise nur den "Domain Admins"-Benutzern die Anmeldung erlauben:

```bash
sudo realm permit -g "Domain Admins"
```

### SSH-Zugriff (optional)

Wenn Benutzer über SSH auf den Linux-Rechner zugreifen möchten, stellen Sie sicher, dass **PAM** (Pluggable Authentication Modules) korrekt konfiguriert ist:

- Überprüfen Sie, dass in der `/etc/ssh/sshd_config` Datei die Zeile `UsePAM yes` gesetzt ist.
- Überprüfen Sie die `/etc/sssd/sssd.conf` Datei, um sicherzustellen, dass die AD-Konfiguration korrekt ist.

### Testen der Anmeldung

Nach erfolgreichem Abschluss des Skripts und dem Neustart des Systems können sich Benutzer über den Login-Bildschirm oder per SSH mit ihren AD-Konten anmelden.

## Fehlerbehebung

- **"Could not resolve DNS" Fehler**: Stellen Sie sicher, dass der DNS-Server korrekt auf den AD-Server zeigt.
- **"Kerberos authentication failed"**: Überprüfen Sie die Zeit des Linux-Rechners und stellen Sie sicher, dass sie mit dem AD-Server synchronisiert ist.
- **SSSD-Fehler**: Wenn SSSD nach dem Beitritt zur Domäne nicht funktioniert, versuchen Sie, den Dienst manuell neu zu starten:
  ```bash
  sudo systemctl restart sssd
  ```

## So könnte ein PowerShell-Skript zur Vorbereitung von Active Directory für Linux-Clients aussehen

``` powershell
# 1. Domänen-Admin für Linux-Beitritte erstellen
$LinuxAdminUser = "linuxjoin"
$LinuxAdminPass = ConvertTo-SecureString "DeinSicheresPasswort" -AsPlainText -Force
New-ADUser -Name $LinuxAdminUser -SamAccountName $LinuxAdminUser -UserPrincipalName "$LinuxAdminUser@deine.domain" -PasswordNeverExpires $true -PassThru | Enable-ADAccount
Set-ADUser -Identity $LinuxAdminUser -Password $LinuxAdminPass
Add-ADGroupMember -Identity "Domain Admins" -Members $LinuxAdminUser

# 2. Computer-Konto für Linux erlauben (optional)
Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $false -MinPasswordLength 8

# 3. DNS-Forwarding für Linux-Clients sicherstellen
Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru

# 4. Kerberos für Linux-Clients konfigurieren
Set-ADServiceAccount -Identity krbtgt -ServicePrincipalNames @{Add="HTTP/deine.domain"}
Restart-Service KDC

# 5. Gruppenrichtlinien für Linux-Clients anpassen (GPO, optional)
New-GPO -Name "Linux-Clients" | New-GPLink -Target "OU=Linux,DC=deine,DC=domain"

Write-Host "Active Directory ist für Linux-Clients vorbereitet!"
```

## Lizenz

Dieses Projekt ist unter der Beerware-Lizenz lizenziert - siehe die [LICENSE](LICENSE)-Datei für Details.

---
