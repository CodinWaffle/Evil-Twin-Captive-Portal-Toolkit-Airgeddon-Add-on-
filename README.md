# Evil Twin Captive Portal Toolkit (Airgeddon Add-on)

> Automated deployment of custom captive-portal templates for Evil Twin Wi-Fi social-engineering attacks, built to integrate with [Airgeddon](https://github.com/v1s1t0r1sh3ll/airgeddon).

---

## ⚠️ Legal & Ethical Disclaimer

**This project is for educational and authorized security testing purposes only.**

- Only use this tool against networks and devices you **own** or have **explicit written authorization** to test.
- Deploying an Evil Twin access point / captive portal against a network you do not control is illegal in most jurisdictions (e.g. under the U.S. Computer Fraud and Abuse Act, UK Computer Misuse Act, and equivalent laws in the Philippines under the Cybercrime Prevention Act of 2012, RA 10175).
- This technique relies on **social engineering** — it deceives real people into entering credentials on a fake page. Even in authorized engagements, always operate within the agreed Rules of Engagement (RoE) and scope.
- The author assumes **no liability** for misuse of this code. This repository exists to demonstrate offensive security concepts as part of a cybersecurity learning portfolio.

If you are not legally authorized to test a given network, **do not run this tool against it.**

---

## Overview

This toolkit extends Airgeddon's Evil Twin attack module with custom-branded captive portal templates designed to look like legitimate Wi-Fi login/update pages. When a target device connects to the rogue access point, it is redirected to the captive portal, which:

1. Displays a convincing lure page (e.g. "Router Firmware Update" or "Mobile Hotspot" login).
2. Prompts the victim for their Wi-Fi password (pretexted as required for "verification" or "update").
3. Validates the entered password by checking it against a **WPA/WPA2 4-way handshake** already captured by Airgeddon.
4. Automatically logs the target's **ESSID**, **BSSID**, and handshake file path for reporting.

This mirrors real-world attacks used by tools like WiFiPhisher and the built-in Airgeddon Evil Twin + captive portal modules, and is commonly taught in WiFi penetration testing courses (e.g. OSWP-adjacent material).

---

## How It Works

```
┌─────────────┐     deauth      ┌──────────────┐
│   Target     │ ─────────────► │  Real AP      │
│   Client     │                └──────────────┘
└──────┬───────┘
       │ associates to rogue AP (same ESSID, spoofed BSSID)
       ▼
┌─────────────────────┐
│  Evil Twin AP        │  (hostapd, same SSID as target network)
│  + DNS redirection    │  (dnsmasq intercepts all DNS → captive portal IP)
└──────┬───────────────┘
       ▼
┌─────────────────────┐
│  Captive Portal       │  (check.htm / index.htm / portal.js / portal.css)
│  "Enter Wi-Fi         │
│   password to         │
│   continue"            │
└──────┬───────────────┘
       ▼
┌─────────────────────┐
│  Password Verification │  Compares submitted password against the
│  Engine                 │  pre-captured handshake using aircrack-ng
└──────┬───────────────┘
       ▼
   Correct? → Log credentials, ESSID, BSSID, handshake path → Attack success
   Incorrect? → Show "wrong password" error, retry
```

### Key components

| File | Purpose |
|---|---|
| `check.htm` | Backend-facing endpoint that receives the submitted password and triggers handshake validation |
| `index.htm` | The lure page shown to the victim (e.g. fake router firmware update UI) |
| `portal.css` | Styling to make the page look like a legitimate vendor/carrier page |
| `portal.js` | Client-side logic — form handling, AJAX submission to `check.htm`, error/success states |
| `deploy_portal.sh` | Deployment script that copies a chosen template into Airgeddon's active portal directory and wires it up for the current Evil Twin session |

### Included templates

- **Mobile Hotspot** — impersonates a mobile carrier hotspot login/verification page.
- **Router Firmware Update** — impersonates a router vendor firmware update prompt, a common pretext that induces urgency ("your router needs this password to complete the update").

---

## Requirements

- Kali Linux (or similar pentesting distro)
- [Airgeddon](https://github.com/v1s1t0r1sh3ll/airgeddon) with Evil Twin + captive portal modules
- `aircrack-ng` suite
- `hostapd`, `dnsmasq`
- A wireless adapter supporting monitor mode + AP mode injection
- A pre-captured WPA/WPA2 handshake for the target network (captured via Airgeddon's handshake capture module)

---

## Usage

1. Use Airgeddon to put your wireless interface into monitor mode and capture a handshake for the target network (Airgeddon's own workflow handles this).
2. Start Airgeddon's Evil Twin + "Captive Portal" attack module and let it reach the point where it's waiting for a portal to be served from its working directory (typically `/tmp/ag<session>/www`).
3. In a separate terminal, deploy your chosen template into that directory:

```bash
sudo ./deploy_portal.sh "/home/kali/Downloads/Exploit/Mobile Hotspot Attack" /tmp/ag1/www
```

   - **Argument 1**: path to the template folder you want to deploy (e.g. `Mobile Hotspot` or `Router Firmware update`)
   - **Argument 2**: Airgeddon's active portal `www` directory for the current session (this path changes per session — check Airgeddon's terminal output for the correct `/tmp/agN/www` path)

4. Airgeddon will serve the deployed portal to any client that associates with the rogue AP and gets DNS-redirected.
5. When a victim submits a password, `check.htm` validates it against the captured handshake. On success, Airgeddon logs the cracked/verified password; this toolkit additionally records the ESSID, BSSID, and handshake file path for your engagement report.

---

## Sample Output / Reporting

Each successful capture logs:

```
[+] ESSID: <target network name>
[+] BSSID: <target AP MAC address>
[+] Handshake: /tmp/ag1/handshake-01.cap
[+] Captured password: (verified against handshake)
[+] Timestamp: <capture time>
```

This is useful for compiling into a pentest report showing time-to-compromise and the social-engineering pretext used.

---

## Detection & Defense (Blue Team Notes)

- **Wireless IDS (WIDS)**: Tools like Kismet or commercial WIDS can detect duplicate ESSIDs with mismatched BSSIDs, a hallmark of Evil Twin attacks.
- **802.11w (Management Frame Protection)**: Mitigates deauthentication-based forcing of clients off the legitimate AP.
- **Client-side awareness**: Legitimate routers/ISPs never ask you to re-enter your Wi-Fi password to "complete an update" through a captive portal — this pretext itself is a red flag worth user-awareness training.
- **Certificate/HTTPS warnings**: Since captive portals typically can't present valid certs for arbitrary HTTPS domains, forced HTTP downgrade or certificate warnings are a detection opportunity.
- **Network monitoring**: Sudden appearance of a new AP broadcasting an existing corporate SSID should trigger alerts in enterprise WIPS.

---

## Project Structure

```
.
├── Mobile hotspot/
│   ├── check.htm
│   ├── index.htm
│   ├── portal.css
│   └── portal.js
├── Router Firmware update/
│   ├── check.htm
│   ├── index.htm
│   ├── portal.css
│   └── portal.js
├── deploy_portal.sh
└── README.md
```

---

## Roadmap / Possible Extensions

- [ ] Additional lure templates (e.g. hotel guest Wi-Fi, coffee shop portal)
- [ ] Logging output in JSON for easier report automation
- [ ] Optional Slack/webhook notification on successful capture (for live CTF/lab demos)
- [ ] Automated detection script demonstrating the "duplicate SSID/BSSID" blue-team defense above

---

## About This Project

Built as part of my cybersecurity learning journey and portfolio while pursuing a career in SOC analysis / penetration testing. Feedback, issues, and responsible-use discussion are welcome via GitHub Issues.

