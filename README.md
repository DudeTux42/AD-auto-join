
## **1. Was machen die verwendeten Programme?**  

### **a) Authentifizierung & Domänenbeitritt**  
| **Paket**            | **Funktion** |
|----------------------|-------------|
| **realmd**          | Erlaubt es, Linux einfach in eine Windows-Domäne aufzunehmen. |
| **sssd**            | (System Security Services Daemon) Verwaltet Benutzer- und Gruppendaten aus AD und sorgt für Authentifizierung. |
| **krb5-user**       | Stellt die Kerberos-Client-Tools bereit, die für AD-Logins benötigt werden. |
| **adcli**           | Ein Tool, das den Computer in die Domäne aufnimmt (Beitritt, Accounts verwalten, etc.). |
| **samba-common-bin**| Enthält `net` und `wbinfo`, um Domänen-Informationen abzufragen. |
| **packagekit**      | Wird von `realmd` genutzt, um automatisch die richtigen Pakete zu installieren. |
| **oddjob & oddjob-mkhomedir** (bei RHEL) | Erstellt automatisch Home-Verzeichnisse für AD-Benutzer. |

### **b) Gruppenrichtlinien (GPO) & Netzwerklaufwerke (optional)**
| **Paket**            | **Funktion** |
|----------------------|-------------|
| **cifs-utils**      | Ermöglicht das Einhängen von Windows-Netzlaufwerken. |
| **samba**           | Falls Drucker- oder Dateifreigaben nötig sind. |
| **krb5-workstation** (RHEL) | Erlaubt Kerberos-Anfragen (z. B. Single Sign-On für Netzwerkdienste). |

---

## **2. Was muss serverseitig angepasst werden?**  

Damit sich Linux-Clients erfolgreich mit AD verbinden können, sind folgende Schritte notwendig:

### **a) Active Directory vorbereiten**  
1. **DNS-Einträge prüfen:**  
   - Linux-Clients müssen den AD-Server als DNS-Server nutzen.  
   - Überprüfen mit:  
     ```powershell
     nslookup domain.local
     ```
   - Falls Linux den AD-Server nicht auflösen kann, müssen die DNS-Zonen in AD überprüft werden.

2. **Zeitsynchronisation sicherstellen:**  
   - AD verwendet Kerberos, das strikte Zeitvorgaben hat.  
   - Linux muss mit dem AD-Zeitserver synchronisiert sein:  
     ```bash
     sudo timedatectl set-ntp on
     ```

3. **Computerobjekte in AD erlauben:**  
   - Standardmäßig dürfen normale Benutzer **max. 10 PCs** in die Domäne aufnehmen.  
   - Falls nötig, ein Admin-User anlegen, der unbeschränkt PCs hinzufügen darf.

4. **Kerberos & GPO-Support für Linux aktivieren (optional):**  
   - Falls du Gruppenrichtlinien für Linux nutzen willst, brauchst du eine **Samba-GPO-Erweiterung**.  
   - Überprüfen, ob die `sysvol`-Freigabe auf dem AD-Server erreichbar ist:  
     ```bash
     smbclient -L //domain.local -U Administrator
     ```

---

## **3. Wie läuft der Prozess ab?**
1. **Linux-Client installiert oder Skript ausgeführt**
2. **Linux setzt den DNS-Server auf den AD-Server**
3. **Kerberos prüft den AD-Server & erstellt ein Ticket**
4. **Mit `adcli` wird der Rechner der Domäne hinzugefügt**
5. **`sssd` konfiguriert die Authentifizierung für AD-Nutzer**
6. **Login mit Windows-Domänenaccount ist möglich!**



##  So könnte ein PowerShell-Skript zur Vorbereitung von Active Directory für Linux-Clients aussehen

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
