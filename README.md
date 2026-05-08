# Airgeddon Plugins by Nuseo1

This repository contains custom plugins created by Nuseo1 for [airgeddon](https://github.com/v1s1t0r1sh3r3/airgeddon), the multi-use bash script for auditing wireless networks.

## Available Plugins

### 1. Manual Evil Twin Control (`custom_et_control`)
This plugin gives you full manual control over your Evil Twin attacks. By default, airgeddon enforces certain parameters when setting up an Evil Twin. This plugin intercepts the configuration phase and prompts you to manually define:
- **BSSID:** Choose the exact original MAC, a completely fake one, or a custom one you type in.
- **Channel:** Change the broadcasting channel of your Evil Twin independent of the target.
- **ESSID:** Choose the exact original name, a custom name, or the standard fake airgeddon name.

It supports 13 languages natively and is fully compatible with other Captive Portal plugins.

### 2. WPA3-SAE Double Decker DoS (`double_decker`)
This plugin introduces the advanced **Double Decker DoS attack** against WPA3 networks. It combines the *Omnivore* (random MACs) and *Muted* (static MAC) attack techniques while sending 20 pre-captured SAE authentication pairs in rapid bursts.
This heavily stresses the target AP's CPU and memory, effectively denying service to legitimate WPA3 clients. It is fully compatible with 2.4 GHz, 5 GHz, and 6 GHz bands.

---

## Installation
1. Clone this repository or download the `.sh` and `.py` (if applicable) files of the plugin you want.
2. Place the plugin files directly into the `/plugins/` folder inside your airgeddon directory.
3. Launch airgeddon. The plugins will be loaded automatically if enabled.

*For more detailed instructions, please check the `README.md` file inside each plugin's respective subfolder.*
