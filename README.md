Custom captive portal templates and deploy script for Airgeddon Evil Twin attacks. Built for authorized wireless pentesting and security research.

## Requirements

- Linux (Kali Linux or Parrot OS recommended)
- Airgeddon
- aircrack-ng suite
- hostapd, dnsmasq
- A wireless adapter supporting monitor mode and packet injection

## Installation

Clone this repo and make the deploy script executable:


```bash

    git clone https://github.com/CodinWaffle/Evil-Twin-Captive-Portal-Toolkit-Airgeddon-Add-on-.git

    cd evil-twin-captive-portal-toolkit

    chmod +x deploy_portal.sh

```

## Setting Up

 Let Airgeddon run until it's actively waiting to serve a portal At this point it creates a session working directory 

```bash
/tmp/ag<session_number>/www

```
Check Airgeddon's terminal output to confirm the exact path for your session.

##
In a separate terminal, deploy a template into that directory
```
sudo ./deploy_portal.sh "/path/to/this/repo/Mobile hotspot" /tmp/ag1/www

```
This copies `check.htm`, `index.htm`, `portal.css`, and `portal.js` into Airgeddon's session directory, replacing its default portal with yours.
##
Airgeddon will now serve your custom portal to any client that connects to the rogue AP.
