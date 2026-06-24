# Device Inventory & Naming Plan

**Last Updated:** 2026-06-11  
**Purpose:** Complete device inventory for naming standardization and network planning

## Infrastructure & Compute

| Current Name | IP | MAC | Type | Vendor | Role | Proposed Name | Fixed IP | Notes |
|--------------|---------|-------------|------|--------|------|---------------|----------|-------|
| Cloud Gateway Max | 172.16.1.1 | - | Gateway | UniFi | Router/DHCP/Firewall | usg-main | 172.16.1.1 | ✅ Core |
| atlantis | 172.16.1.158 | - | Server | Proxmox | Virtualization Host | atlantis | 172.16.1.158 | ✅ NS5Pro |
| selfhost | 172.16.1.159 | - | LXC | Proxmox | Docker Host (78 containers) | selfhost | 172.16.1.159 | ✅ Main stack |
| cerebro | ~~172.16.1.160~~ | - | ~~LXC~~ | ~~Proxmox~~ | ~~AI workload~~ | - | - | ❌ REMOVED 2026-06-11 |
| a0d7b954-ssh | 172.16.1.31 | - | Server | Intel NUC | Home Assistant OS | homeassistant | 172.16.1.31 | ✅ Core HA |
| DATAs-Mac-mini | 172.16.1.138 | d0:11:e5:83:e8:c9 | Desktop | Apple | DATA's workstation | datas-mac-mini | 172.16.1.138 | 🔴 MISSING from docs! |
| BYO-MBP-LY62L726TL | 172.16.1.31 | f4:4d:30:63:b5:ee | Laptop | Apple/Intel | Damian's MacBook | - | Dynamic | User device |

## Raspberry Pi Gateways

| Current Name | IP | MAC | Hardware | Role | Containers | Proposed Name | Fixed IP | Notes |
|--------------|---------|-------------|----------|------|------------|---------------|----------|-------|
| zwave2mqtt | 172.16.1.135 | b8:27:eb:3d:79:0c | RPi | Z-Wave/Zigbee Gateway | 2 (zwave2mqtt, zigbee2mqtt) | zgate | 172.16.1.135 | ✅ Fixed |
| iot-gate-cbus | 172.16.1.128 | b8:27:eb:4a:36:b9 | RPi | C-Bus Gateway | 3 | cgate | 172.16.1.128 | ⚠️ Duplicate IP .250 |
| iot-gate-cbus (duplicate) | 172.16.1.250 | b8:27:eb:4a:36:b9 | RPi | C-Bus Gateway | - | - | - | 🔴 Remove duplicate |

## Network Equipment

| Current Name | IP | MAC | Model | Role | Proposed Name | Fixed IP | Notes |
|--------------|---------|-------------|-------|------|---------------|----------|-------|
| amp-kitchenbeam | 172.16.1.143 | 34:7e:5c:90:fa:6e | Sonos ZP | Audio (Kitchen) | sonos-kitchen | 172.16.1.143 | Fixed |
| amp-outside | 172.16.1.141 | 00:0e:58:3d:e0:f8 | Sonos ZP | Audio (Outside) | sonos-outside | 172.16.1.141 | Fixed |
| HDHR-12513C2F | 172.16.1.161 | 00:18:dd:25:13:c2 | HDHomeRun | TV Tuner | hdhr-main | 172.16.1.161 | Fixed |
| FPP-K64D | 172.16.1.29 | 90:86:f2:1c:2b:80 | Texas Inst | Falcon Player (Christmas lights?) | fpp-showrunner | 172.16.1.29 | Dynamic → Fixed |
| iot-gate-hue | 172.16.1.28 | 00:17:88:4a:36:b9 | Philips Hue | Smart lighting bridge | hue-bridge | 172.16.1.28 | Dynamic → Fixed |

## Cameras & Security

| Current Name | IP | MAC | Vendor | Location | Proposed Name | Fixed IP | Notes |
|--------------|---------|-------------|--------|----------|---------------|----------|-------|
| cam-backdoor | 172.16.1.230 | 24:3f:75:dd:5b:e9 | Reolink | Back door | cam-backdoor | 172.16.1.230 | Fixed |
| cam-backyard | 172.16.1.227 | 44:19:b7:2f:27:15 | - | Backyard | cam-backyard | 172.16.1.227 | Fixed |
| cam-driveway | 172.16.1.229 | ec:71:db:41:4c:bf | D-Link | Driveway | cam-driveway | 172.16.1.229 | Fixed |
| cam-eastdrive | 172.16.1.226 | 44:19:b6:1c:36:91 | Hikvision | East driveway | cam-eastdrive | 172.16.1.226 | Fixed |
| cam-frontcircle | 172.16.1.232 | 44:19:b6:12:77:d8 | Hikvision | Front circle | cam-frontcircle | 172.16.1.232 | Fixed |
| cam-fronteast | 172.16.1.233 | 44:19:b6:1c:36:4c | Hikvision | Front east | cam-fronteast | 172.16.1.233 | Fixed |
| cam-frontgate | 172.16.1.234 | 44:19:b6:18:d7:b0 | Hikvision | Front gate | cam-frontgate | 172.16.1.234 | Fixed |
| USW-Attic | 172.16.1.236 | 6c:63:f8:8c:bd:46 | Ubiquiti | Attic | cam-attic | 172.16.1.236 | Dynamic → Fixed |
| USW-Cameras | 172.16.1.174 | 6c:63:f8:a3:32:4b | Ubiquiti | - | cam-multi | 172.16.1.174 | Dynamic → Fixed |
| USW-Cinema | 172.16.1.237 | 58:d6:1f:10:eb:d8 | Ubiquiti | Cinema | cam-cinema | 172.16.1.237 | Dynamic → Fixed |
| USW-Closet | 172.16.1.56 | 58:d6:1f:10:ef:5d | Ubiquiti | Closet | cam-closet | 172.16.1.56 | Dynamic → Fixed |
| USW-Office | 172.16.1.189 | 84:78:48:6a:f8:f2 | Ubiquiti | Office | cam-office | 172.16.1.189 | Dynamic → Fixed |
| 44:19:b6:11:f5:56:ba | 172.16.1.222 | 44:19:b6:11:f5:56 | Hikvision | ? | cam-unknown-1 | 172.16.1.222 | 🔴 Identify location |
| bc:24:11:45:56:ba | 172.16.1.160 | bc:24:11:45:56:ba | Proxmox | ? | - | - | 🔴 Wrong - this is cerebro LXC |

## ESPHome & IoT Devices (Cannot Rename - Hardcoded)

| Current Name | IP | MAC | Hardware | Location/Function | Managed By | Fixed IP | Notes |
|--------------|---------|-------------|----------|-------------------|------------|----------|-------|
| esyminiV2-RHID1 | 172.16.1.158 | e8:31:cd:29:dc:8f | ESP32 | ? | Home Assistant | Dynamic | ⚠️ IP conflict with atlantis! |
| espressif | 172.16.1.44 | e0:5a:1b:6a:e4:a4 | ESP | ? | Home Assistant | Dynamic | Generic name |
| FPP-K64D | 172.16.1.29 | 90:86:f2:1c:2b:80 | ESP | Christmas lights controller | FPP | Dynamic → Fixed | |
| **esyminiV2 (water pump)** | ? | ? | ESP | Water pump | Home Assistant | ? | 🎯 CANNOT RENAME |

## Smart Home Devices

| Current Name | IP | MAC | Vendor | Location | Proposed Name | Fixed IP | Notes |
|--------------|---------|-------------|--------|----------|---------------|----------|-------|
| iot-lg-washer | 172.16.1.183 | 4c:bc:e9:14:83:21 | LG | Laundry | lg-washer | 172.16.1.183 | Fixed |
| assist-basement | 172.16.1.119 | 44:65:0d:6e:1e:b9 | Amazon | Basement | echo-basement | 172.16.1.119 | Fixed |
| assist-bed1 | 172.16.1.118 | 10:09:f9:82:cb:7b | Amazon | Bed1 | echo-bed1 | 172.16.1.118 | Fixed |
| assist-garage | 172.16.1.116 | 0c:0e:99:b0:65:6e | Amazon | Garage | echo-garage | 172.16.1.116 | Fixed |
| assist-living | 172.16.1.115 | 0c:ee:99:28:10:4e | Amazon | Living | echo-living | 172.16.1.115 | Fixed |
| assist-mbed | 172.16.1.117 | 10:96:93:64:7d:7e | Amazon | Master bed | echo-mbed | 172.16.1.117 | Fixed |

## Streaming Devices

| Current Name | IP | MAC | Vendor | Location | Proposed Name | Fixed IP | Notes |
|--------------|---------|-------------|--------|----------|---------------|----------|-------|
| stream-basement | 172.16.1.104 | 08:31:34:e5:b4:35 | Roku | Basement | roku-basement | 172.16.1.104 | Fixed |
| stream-cinema | 172.16.1.98 | 14:c1:4e:00:44:a1 | Google | Cinema | chromecast-cinema | 172.16.1.98 | Dynamic → Fixed |
| stream-laundry | 172.16.1.103 | e2:6f:c4:84:90:cc | Google | Laundry | chromecast-laundry | 172.16.1.103 | Fixed |
| stream-living | 172.16.1.115 | 20:1f:3c:2a:5f:2e | Google | Living | chromecast-living | 172.16.1.115 | Dynamic → Fixed |
| stream-living-apple | 172.16.1.83 | 08:66:98:cd:38:59 | Apple | Living | appletv-living | 172.16.1.83 | Dynamic → Fixed |
| stream-sitting | 172.16.1.105 | 08:31:34:e5:b4:5a | Roku | Sitting | roku-sitting | 172.16.1.105 | Fixed |

## SONOFF Devices (Smart Switches/Sensors)

| Current Name | IP | MAC | Location | Proposed Name | Fixed IP | Notes |
|--------------|---------|-------------|----------|---------------|----------|-------|
| ssbed2n | 172.16.1.215 | c4:dd:57:02:ae:a7 | Bed2 | sonoff-bed2 | Dynamic | Tasmota/ESPHome? |
| ssgirldn | 172.16.1.20 | c4:dd:57:02:4:ef | Girl's room | sonoff-girl | Dynamic | |
| sskitchenpelmet | 172.16.1.22 | c4:dd:57:04:74:6b | Kitchen pelmet | sonoff-kitchen-pelmet | Dynamic | |
| sslvroomn | 172.16.1.241 | 70:03:9f:4c:12:8a | Living room | sonoff-living | Dynamic | |
| sslvroomme | 172.16.1.97 | c4:dd:57:07:8f:74 | Living room | sonoff-living-me | Dynamic | Duplicate location? |
| sslvroommw | 172.16.1.162 | c4:dd:57:04:0c:4a | Living room | sonoff-living-mw | Dynamic | Duplicate location? |
| ssmbede | 172.16.1.235 | c4:dd:57:0e:eb:7b | Master bed | sonoff-mbed-e | Dynamic | |
| ssmbedn | 172.16.1.252 | c4:dd:57:0b:d4:1c | Master bed | sonoff-mbed-n | Dynamic | |
| ssofficenw | 172.16.1.225 | c4:dd:57:08:d3:f1 | Office | sonoff-office | Dynamic | |
| sssittingroomn | 172.16.1.144 | c4:dd:57:0c:8d:db | Sitting room | sonoff-sitting | Dynamic | |
| sssittingroomme | 172.16.1.181 | 24:a1:60:14:a9:f7 | Sitting room | sonoff-sitting-me | Dynamic | |
| sssittingroommw | 172.16.1.92 | c4:dd:57:04:6c:62 | Sitting room | sonoff-sitting-mw | Dynamic | |
| sssunroommw | 172.16.1.36 | c4:dd:57:02:8e:56 | Sunroom | sonoff-sunroom | Dynamic | |

## Expected/Planned Devices

| Device Type | Quantity | Vendor | Purpose | Proposed Naming | Notes |
|-------------|----------|--------|---------|-----------------|-------|
| Victron Energy Monitor | 1+ | Victron | Solar/battery monitoring | victron-* | 🔜 Expected soon |
| UniFi Access Points | ? | Ubiquiti | WiFi expansion | uap-{location} | 🔜 To deploy |
| Reolink Cameras | ? | Reolink | Security cameras | cam-{location} | 🔜 To deploy |

## Issues & Actions

### 🔴 Critical Issues
1. **IP Conflict:** esyminiV2-RHID1 using 172.16.1.158 (atlantis/Proxmox host IP!)
2. **Missing from docs:** DATA's Mac mini (172.16.1.138) - important workstation not documented
3. **Duplicate entry:** iot-gate-cbus appears twice (172.16.1.128 and 172.16.1.250)
4. **Wrong camera entry:** bc:24:11:45:56:ba listed as camera but is cerebro LXC
5. **Unidentified camera:** 172.16.1.222 (44:19:b6:11:f5:56:ba) - location unknown

### ⚠️ Naming Issues
1. **ESPHome devices:** Many auto-generated names, some unchangeable (water pump)
2. **SONOFF naming:** Inconsistent abbreviations (sslvroomn, sslvroomme, sslvroommw for same room)
3. **Duplicate locations:** Multiple SONOFFs in same rooms without clear differentiation
4. **Generic names:** "espressif" devices need identification

### 📋 Cleanup Actions
1. **Fix IP conflict** - Move esyminiV2-RHID1 off .158
2. **Document DATA's Mac** - Add to infrastructure section
3. **Remove duplicate** - Delete iot-gate-cbus .250 entry
4. **Identify unknowns** - Camera at .222, espressif devices
5. **Standardize SONOFF** - Create clear naming convention for multi-device rooms
6. **Convert to fixed IPs** - All infrastructure, cameras, gateways, smart devices
7. **Plan for new devices** - Victron, new APs, new cameras

## Naming Conventions Proposal

### Pattern: `{type}-{location}[-{function}][-{index}]`

**Types:**
- `cam-` = Camera
- `echo-` = Amazon Echo/Alexa
- `sonoff-` = SONOFF switch/sensor
- `roku-` = Roku streaming
- `chromecast-` = Google Chromecast
- `appletv-` = Apple TV
- `sonos-` = Sonos speaker
- `hue-` = Philips Hue
- `uap-` = UniFi Access Point
- `usw-` = UniFi Switch
- `victron-` = Victron energy device

**Locations:** kitchen, laundry, cinema, basement, living, sitting, bed1, bed2, mbed (master bed), office, garage, sunroom, attic, closet, frontgate, backyard, driveway, etc.

**Examples:**
- `sonoff-living-north` (directional)
- `sonoff-living-main` (primary)
- `sonoff-living-wall` (function)
- `cam-frontgate-1`, `cam-frontgate-2` (multiple same location)

### ESPHome Unchangeable Devices
Document in Home Assistant with descriptive names even if device hostname can't change:
- Device: `esyminiV2` → HA Entity: "Water Pump Controller"
- Track in NETWORK.md with original name + function notes
