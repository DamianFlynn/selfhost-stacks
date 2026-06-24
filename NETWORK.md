# Network Infrastructure Map

**Last Updated:** 2026-06-11  
**Network:** 172.16.1.0/24  
**VLAN:** Default (single VLAN currently)

**See also:** [DEVICE-INVENTORY.md](DEVICE-INVENTORY.md) for complete device tables and naming plan

## Core Infrastructure

### Network Gateway
- **Device:** UniFi Cloud Gateway Max (UCG Max)
- **IP:** 172.16.1.1
- **Role:** Router, DHCP Server, Firewall
- **Version:** UniFi OS 5.1.15, Network 10.4.57
- **Access:** SSH enabled, Web UI
- **Credentials:** `<Sc0rp10n!/>`
- **WAN:** Westnet Broadband (88.81.97.90)
- **DHCP Range:** 83/249 leases active, 162 available
- **Port Forwarding:**
  - Traefik-Ingress: TCP/UDP 443 → 172.16.1.159:443
  - Rustdesk: TCP/UDP 21115-21119 → 172.16.1.159:21115-21119

### WiFi Networks
- **Deer Crest** (Main): WPA2, 2.4GHz + 5GHz, 49 clients
- **Deer Crest Guests**: Open, Main Building (5 APs)

## Compute Infrastructure

### Proxmox Cluster
**Host: atlantis** (Minisforum NS5Pro)
- **IP:** 172.16.1.158
- **Hardware:** Minisforum NS5Pro
- **OS:** Proxmox VE 9.1.6
- **SSH:** root@172.16.1.158
- **Containers:**
  - **LXC 100 "selfhost"** (172.16.1.159)
    - Role: Main Docker host for selfhosted services
    - Containers: 78+ Docker containers
    - Stacks: Traefik, Authelia, *arr stack, media, automation
    - Storage: /mnt/fast/stacks, /mnt/fast/appdata
    - Service Account: apps:apps (568:568)
    - GPU: AMD iGPU passthrough (video:44, render:110)
    
  - **LXC 101 "cerebro"** - REMOVED 2026-06-11
    - Decommissioned - AI/memory workload moved to Oracle vault
    - Memories backed up to agent-os/Archives/Projects/Oracle-Agent-Platform/cerebro-notes/cerebro-memories-20260611/

### Home Automation
**Host: Home Assistant** (Intel NUC)
- **IP:** 172.16.1.31
- **Hostname:** a0d7b954-ssh
- **OS:** Home Assistant OS (Linux 6.12.85-haos)
- **SSH:** sysadmin@172.16.1.31
- **Role:** Home automation hub
- **Notes:** Docker not accessible via sysadmin account (runs HA Supervisor)

### Raspberry Pi Hosts

**zgate** (Z-Wave/Zigbee Gateway)
- **IP:** 172.16.1.135 (Fixed)
- **Hostname:** zwave2mqtt
- **Hardware:** Raspberry Pi
- **SSH:** pi@172.16.1.135
- **Role:** Z-Wave and Zigbee gateway
- **Expected Containers:** 2 (zwave2mqtt, zigbee2mqtt)
- **Integration:** WebSocket and/or MQTT to Home Assistant

**cgate** (C-Bus Gateway)
- **IP:** 172.16.1.128 (Dynamic) / 172.16.1.250 (Fixed alias)
- **Hostname:** iot-gate-cbus
- **Hardware:** Raspberry Pi
- **SSH:** pi@172.16.1.128
- **Role:** C-Bus lighting control gateway
- **Expected Containers:** 3
- **Status:** Recently configured/worked on

## Key Network Devices

### Access Points (UniFi)
Multiple APs broadcasting "Deer Crest" SSID across building locations:
- UAP-Kitchen (28 clients)
- UAP-Laundry (15 clients)
- UAP-Bed2 (9 clients)
- UAP-BBQ (3 clients)
- UAP-Cinema (2 clients)

### IoT Devices by Category

**ESPHome Devices** (should be managed via Home Assistant ESPHome integration):
- Multiple ESP32/ESP8266 devices with naming pattern: `esyminiV2-RHID1`, `espressif`, etc.
- Located in various rooms (Kitchen, Laundry, Cinema, Bed2, BBQ)

**Sonos Audio**
- amp-kitchen (SonosZP) - 172.16.1.143
- amp-outside (SonosZP) - 172.16.1.141
- Multiple Sonos speakers distributed across locations

**Cameras (Hikvision + USW)**
- Multiple IP cameras on 172.16.1.222-234 range
- USW-Cameras, USW-Cinema, USW-Closet, USW-Office, USW-Attic

**Smart Home Devices**
- Philips Hue bridge: 172.16.1.28
- Reolink cameras
- LG washer: 172.16.1.183
- Multiple Amazon Echo/Assist devices
- Apple devices (iPhones, iPads, MacBooks, Apple TV, HomePods)
- Google Chromecast devices (stream-*)

**Network Equipment**
- Multiple UniFi switches and access points
- Texas Instruments devices (FPP-K64D)
- Raspberry Pi devices (Raspbian Pi Foundation)
- SiliconDust HDHomeRun (HDHR-12513C2F) - 172.16.1.161

## Device Naming Standards

From the UniFi data, current naming patterns include:
- **Cameras:** `cam-{location}` (cam-backyard, cam-backdoor, cam-frontgate, etc.)
- **Streaming:** `stream-{location}` (stream-basement, stream-cinema, stream-laundry, stream-living)
- **Rooms/Locations:** kitchen, laundry, cinema, bed2, bbq, office, basement, living, sitting
- **IoT Gateways:** `iot-gate-{protocol}` (iot-gate-cbus)
- **ESPHome:** Various (needs standardization)
- **Sonos:** `amp-{location}`, speaker names
- **Assists:** `assist-{location}` (Amazon devices)

## Network Hygiene Issues (To Address)

1. **IP Address Management:**
   - Mix of fixed and dynamic IPs (37 fixed, 48 dynamic)
   - Some devices have multiple IPs (iot-gate-cbus: 128 + 250)
   - 19 offline devices cluttering the table

2. **Naming Inconsistency:**
   - ESPHome devices using auto-generated names
   - Some devices unnamed or showing MAC addresses
   - Inconsistent location naming (Kitchen vs kitchen)

3. **Single VLAN:**
   - Everything on 172.16.1.0/24
   - No segmentation between IoT, infrastructure, user devices, cameras

4. **Device Organization:**
   - Auto-discovered hardware showing incorrect vendor info
   - ESPHome devices should be managed via Home Assistant
   - Offline devices need cleanup

## Suggested VLAN Segmentation (Future)

1. **Management VLAN (10):** 172.16.10.0/24
   - UniFi gateway, switches, APs
   - Proxmox host
   
2. **Server VLAN (20):** 172.16.20.0/24
   - LXC containers (selfhost, cerebro)
   - Home Assistant
   - Pi gateways (zgate, cgate)
   
3. **IoT VLAN (30):** 172.16.30.0/24
   - ESPHome devices
   - Sonos speakers
   - Smart home devices (Hue, switches, sensors)
   
4. **Camera VLAN (40):** 172.16.40.0/24
   - All IP cameras
   - NVR systems
   
5. **User VLAN (50):** 172.16.50.0/24
   - Phones, tablets, laptops
   - Apple devices
   - Guest WiFi isolated

## Quick Reference

### SSH Access Summary
| Host | IP | User | Purpose |
|------|-------|------|---------|
| atlantis (Proxmox) | 172.16.1.158 | root | Virtualization host |
| selfhost | 172.16.1.159 | root | Docker services |
| cerebro | 172.16.1.160 | root | AI workloads |
| Home Assistant | 172.16.1.31 | sysadmin | Home automation |
| zgate | 172.16.1.135 | pi | Z-Wave/Zigbee |
| cgate | 172.16.1.128 | pi | C-Bus gateway |
| UCG Max | 172.16.1.1 | - | Network gateway |

### Services by Host
- **selfhost (159):** Traefik, Authelia, Sonarr, Radarr, Lidarr, Prowlarr, qBittorrent, Grafana, Dawarich, Open WebUI, Ollama, Immich, FreshRSS, and 60+ others
- **cerebro (160):** Qdrant, Redis, SearXNG
- **Home Assistant (31):** Home Assistant Core + addons
- **zgate (135):** Z-Wave2MQTT, Zigbee2MQTT
- **cgate (128):** C-Bus integration (3 containers)

### Port Forwards
- **443** → 172.16.1.159:443 (Traefik ingress)
- **21115-21119** → 172.16.1.159:21115-21119 (Rustdesk)

---

## Maintenance Tasks

### Immediate Cleanup
- [ ] Remove 19 offline devices from UniFi
- [ ] Standardize ESPHome device naming
- [ ] Convert dynamic IPs to fixed for infrastructure
- [ ] Verify/correct auto-discovered hardware vendors
- [ ] Consolidate duplicate device entries (e.g., iot-gate-cbus)

### Future Network Improvements
- [ ] Implement VLAN segmentation
- [ ] Create firewall rules between VLANs
- [ ] Set up IoT isolation with Home Assistant allowed access
- [ ] Migrate devices to appropriate VLANs
- [ ] Create guest WiFi on isolated VLAN
- [ ] Document camera VLAN and NVR access patterns
