#!/usr/bin/env bash

#shellcheck disable=SC2034,SC2154

plugin_name="Manual Evil Twin Control"
plugin_description="Plugin for manually selecting the BSSID, channel, and ESSID for Evil Twin attacks."
plugin_author="Nuseo1"
plugin_enabled=1
plugin_minimum_ag_affected_version="12.0"
plugin_maximum_ag_affected_version=""
plugin_distros_supported=("*")

type -t debug_print >/dev/null || function debug_print() { :; }

declare -g custom_et_chosen_bssid=""
declare -g custom_et_chosen_essid=""

function custom_et_control_prehook_hookable_for_languages() {
    arr["ENGLISH","custom_et_text_1"]="Manual Evil Twin control:"
    arr["SPANISH","custom_et_text_1"]="Control manual de Evil Twin:"
    arr["FRENCH","custom_et_text_1"]="Contrôle manuel Evil Twin :"
    arr["CATALAN","custom_et_text_1"]="Control manual d'Evil Twin:"
    arr["PORTUGUESE","custom_et_text_1"]="Controle manual de Evil Twin:"
    arr["RUSSIAN","custom_et_text_1"]="Ручное управление Evil Twin:"
    arr["GREEK","custom_et_text_1"]="Χειροκίνητος έλεγχος Evil Twin:"
    arr["ITALIAN","custom_et_text_1"]="Controllo manuale di Evil Twin:"
    arr["POLISH","custom_et_text_1"]="Ręczna kontrola Evil Twin:"
    arr["GERMAN","custom_et_text_1"]="Manuelle Evil Twin Kontrolle:"
    arr["TURKISH","custom_et_text_1"]="Manuel Evil Twin kontrolü:"
    arr["ARABIC","custom_et_text_1"]="التحكم اليدوي في Evil Twin:"
    arr["CHINESE","custom_et_text_1"]="Evil Twin 手动控制："

    arr["ENGLISH","custom_et_text_2"]="How should the BSSID for the Evil Twin be set?"
    arr["SPANISH","custom_et_text_2"]="¿Cómo se debe configurar el BSSID para el Evil Twin?"
    arr["FRENCH","custom_et_text_2"]="Comment définir le BSSID pour l'Evil Twin ?"
    arr["CATALAN","custom_et_text_2"]="Com s'ha d'establir el BSSID per a l'Evil Twin?"
    arr["PORTUGUESE","custom_et_text_2"]="Como o BSSID para o Evil Twin deve ser definido?"
    arr["RUSSIAN","custom_et_text_2"]="Как следует установить BSSID для Evil Twin?"
    arr["GREEK","custom_et_text_2"]="Πώς πρέπει να ρυθμιστεί το BSSID για το Evil Twin;"
    arr["ITALIAN","custom_et_text_2"]="Come dovrebbe essere impostato il BSSID per l'Evil Twin?"
    arr["POLISH","custom_et_text_2"]="Jak ustawić BSSID dla Evil Twin?"
    arr["GERMAN","custom_et_text_2"]="Wie soll die BSSID für den Evil Twin festgelegt werden?"
    arr["TURKISH","custom_et_text_2"]="Evil Twin için BSSID nasıl ayarlanmalı?"
    arr["ARABIC","custom_et_text_2"]="كيف يجب تعيين BSSID لـ Evil Twin؟"
    arr["CHINESE","custom_et_text_2"]="应该如何设置 Evil Twin 的 BSSID？"

    arr["ENGLISH","custom_et_text_3"]="Use exact original BSSID"
    arr["SPANISH","custom_et_text_3"]="Usar el BSSID original exacto"
    arr["FRENCH","custom_et_text_3"]="Utiliser le BSSID original exact"
    arr["CATALAN","custom_et_text_3"]="Utilitzar el BSSID original exacte"
    arr["PORTUGUESE","custom_et_text_3"]="Usar o BSSID original exato"
    arr["RUSSIAN","custom_et_text_3"]="Использовать точный исходный BSSID"
    arr["GREEK","custom_et_text_3"]="Χρησιμοποιήστε το ακριβές αρχικό BSSID"
    arr["ITALIAN","custom_et_text_3"]="Usa l'esatto BSSID originale"
    arr["POLISH","custom_et_text_3"]="Użyj dokładnego oryginalnego BSSID"
    arr["GERMAN","custom_et_text_3"]="Exakte originale BSSID verwenden"
    arr["TURKISH","custom_et_text_3"]="Tam orijinal BSSID'yi kullan"
    arr["ARABIC","custom_et_text_3"]="استخدام BSSID الأصلي بالضبط"
    arr["CHINESE","custom_et_text_3"]="使用确切的原始 BSSID"

    arr["ENGLISH","custom_et_text_4"]="Enter a completely new BSSID manually"
    arr["SPANISH","custom_et_text_4"]="Introducir un BSSID completamente nuevo manualmente"
    arr["FRENCH","custom_et_text_4"]="Entrer manuellement un nouveau BSSID"
    arr["CATALAN","custom_et_text_4"]="Introduir manualment un BSSID completament nou"
    arr["PORTUGUESE","custom_et_text_4"]="Inserir manualmente um BSSID completamente novo"
    arr["RUSSIAN","custom_et_text_4"]="Ввести совершенно новый BSSID вручную"
    arr["GREEK","custom_et_text_4"]="Εισαγάγετε ένα εντελώς νέο BSSID χειροκίνητα"
    arr["ITALIAN","custom_et_text_4"]="Inserisci manualmente un BSSID completamente nuovo"
    arr["POLISH","custom_et_text_4"]="Wprowadź całkowicie nowy BSSID ręcznie"
    arr["GERMAN","custom_et_text_4"]="Eine komplett neue BSSID manuell eingeben"
    arr["TURKISH","custom_et_text_4"]="Tamamen yeni bir BSSID'yi manuel gir"
    arr["ARABIC","custom_et_text_4"]="إدخال BSSID جديد تمامًا يدويًا"
    arr["CHINESE","custom_et_text_4"]="手动输入一个全新的 BSSID"

    arr["ENGLISH","custom_et_text_5"]="Use standard (slightly modified) airgeddon BSSID (default)"
    arr["SPANISH","custom_et_text_5"]="Usar BSSID estándar (ligeramente modificado) de airgeddon (predeterminado)"
    arr["FRENCH","custom_et_text_5"]="Utiliser le BSSID standard (légèrement modifié) d'airgeddon (par défaut)"
    arr["CATALAN","custom_et_text_5"]="Utilitzar el BSSID estàndard (lleugerament modificat) d'airgeddon (predeterminat)"
    arr["PORTUGUESE","custom_et_text_5"]="Usar o BSSID padrão (ligeiramente modificado) do airgeddon (padrão)"
    arr["RUSSIAN","custom_et_text_5"]="Использовать стандартный (слегка изменённый) BSSID airgeddon (по умолчанию)"
    arr["GREEK","custom_et_text_5"]="Χρησιμοποιήστε το τυπικό (ελαφρώς τροποποιημένο) BSSID του airgeddon (προεπιλογή)"
    arr["ITALIAN","custom_et_text_5"]="Usa il BSSID standard (leggermente modificato) di airgeddon (predefinito)"
    arr["POLISH","custom_et_text_5"]="Użyj standardowego (lekko zmodyfikowanego) BSSID airgeddon (domyślnie)"
    arr["GERMAN","custom_et_text_5"]="Standard (leicht veränderte) airgeddon BSSID verwenden (Standard)"
    arr["TURKISH","custom_et_text_5"]="Standart (hafif değiştirilmiş) airgeddon BSSID kullan (varsayılan)"
    arr["ARABIC","custom_et_text_5"]="استخدام BSSID الافتراضي (المعدل قليلاً) لـ airgeddon (الافتراضي)"
    arr["CHINESE","custom_et_text_5"]="使用标准（稍作修改的）airgeddon BSSID（默认）"

    arr["ENGLISH","custom_et_text_6"]="OK. Original BSSID will be used:"
    arr["SPANISH","custom_et_text_6"]="OK. Se utilizará el BSSID original:"
    arr["FRENCH","custom_et_text_6"]="OK. Le BSSID original sera utilisé :"
    arr["CATALAN","custom_et_text_6"]="OK. S'utilitzarà el BSSID original:"
    arr["PORTUGUESE","custom_et_text_6"]="OK. O BSSID original será usado:"
    arr["RUSSIAN","custom_et_text_6"]="ОК. Будет использован исходный BSSID:"
    arr["GREEK","custom_et_text_6"]="OK. Το αρχικό BSSID θα χρησιμοποιηθεί:"
    arr["ITALIAN","custom_et_text_6"]="OK. Verrà utilizzato il BSSID originale:"
    arr["POLISH","custom_et_text_6"]="OK. Zostanie użyty oryginalny BSSID:"
    arr["GERMAN","custom_et_text_6"]="OK. Die originale BSSID wird verwendet:"
    arr["TURKISH","custom_et_text_6"]="Tamam. Orijinal BSSID kullanılacak:"
    arr["ARABIC","custom_et_text_6"]="حسنا. سيتم استخدام BSSID الأصلي:"
    arr["CHINESE","custom_et_text_6"]="好的。将使用原始 BSSID："

    arr["ENGLISH","custom_et_text_7"]="Warning: This may cause instability in the network!"
    arr["SPANISH","custom_et_text_7"]="Advertencia: ¡Esto puede causar inestabilidad en la red!"
    arr["FRENCH","custom_et_text_7"]="Attention : cela peut provoquer une instabilité du réseau !"
    arr["CATALAN","custom_et_text_7"]="Atenció: Això pot causar inestabilitat a la xarxa!"
    arr["PORTUGUESE","custom_et_text_7"]="Aviso: Isso pode causar instabilidade na rede!"
    arr["RUSSIAN","custom_et_text_7"]="Предупреждение: Это может вызвать нестабильность сети!"
    arr["GREEK","custom_et_text_7"]="Προειδοποίηση: Αυτό μπορεί να προκαλέσει αστάθεια στο δίκτυο!"
    arr["ITALIAN","custom_et_text_7"]="Avviso: Questo potrebbe causare instabilità nella rete!"
    arr["POLISH","custom_et_text_7"]="Ostrzeżenie: Może to spowodować niestabilność w sieci!"
    arr["GERMAN","custom_et_text_7"]="Achtung: Dies kann zu Instabilität im Netzwerk führen!"
    arr["TURKISH","custom_et_text_7"]="Uyarı: Bu ağda kararsızlığa neden olabilir!"
    arr["ARABIC","custom_et_text_7"]="تحذير: قد يسبب هذا عدم استقرار في الشبكة!"
    arr["CHINESE","custom_et_text_7"]="警告：这可能会导致网络不稳定！"

    arr["ENGLISH","custom_et_text_8"]="Please enter the desired BSSID (format XX:XX:XX:XX:XX:XX):"
    arr["SPANISH","custom_et_text_8"]="Introduzca el BSSID deseado (formato XX:XX:XX:XX:XX:XX):"
    arr["FRENCH","custom_et_text_8"]="Veuillez entrer le BSSID souhaité (format XX:XX:XX:XX:XX:XX) :"
    arr["CATALAN","custom_et_text_8"]="Introduïu el BSSID desitjat (format XX:XX:XX:XX:XX:XX):"
    arr["PORTUGUESE","custom_et_text_8"]="Insira o BSSID desejado (formato XX:XX:XX:XX:XX:XX):"
    arr["RUSSIAN","custom_et_text_8"]="Пожалуйста, введите желаемый BSSID (формат XX:XX:XX:XX:XX:XX):"
    arr["GREEK","custom_et_text_8"]="Παρακαλώ εισαγάγετε το επιθυμητό BSSID (μορφή XX:XX:XX:XX:XX:XX):"
    arr["ITALIAN","custom_et_text_8"]="Inserisci il BSSID desiderato (formato XX:XX:XX:XX:XX:XX):"
    arr["POLISH","custom_et_text_8"]="Wprowadź żądany BSSID (format XX:XX:XX:XX:XX:XX):"
    arr["GERMAN","custom_et_text_8"]="Geben Sie die gewünschte BSSID ein (Format XX:XX:XX:XX:XX:XX):"
    arr["TURKISH","custom_et_text_8"]="Lütfen istenen BSSID'yi girin (biçim XX:XX:XX:XX:XX:XX):"
    arr["ARABIC","custom_et_text_8"]="الرجاء إدخال BSSID المطلوب (بالتنسيق XX:XX:XX:XX:XX:XX):"
    arr["CHINESE","custom_et_text_8"]="请输入所需的 BSSID（格式 XX:XX:XX:XX:XX:XX）："

    arr["ENGLISH","custom_et_text_9"]="BSSID has been set to:"
    arr["SPANISH","custom_et_text_9"]="BSSID se ha configurado en:"
    arr["FRENCH","custom_et_text_9"]="Le BSSID a été défini sur :"
    arr["CATALAN","custom_et_text_9"]="El BSSID s'ha establert a:"
    arr["PORTUGUESE","custom_et_text_9"]="O BSSID foi definido para:"
    arr["RUSSIAN","custom_et_text_9"]="BSSID был установлен на:"
    arr["GREEK","custom_et_text_9"]="Το BSSID έχει οριστεί σε:"
    arr["ITALIAN","custom_et_text_9"]="Il BSSID è stato impostato su:"
    arr["POLISH","custom_et_text_9"]="BSSID został ustawiony na:"
    arr["GERMAN","custom_et_text_9"]="BSSID wurde gesetzt auf:"
    arr["TURKISH","custom_et_text_9"]="BSSID şu olarak ayarlandı:"
    arr["ARABIC","custom_et_text_9"]="تم تعيين BSSID إلى:"
    arr["CHINESE","custom_et_text_9"]="BSSID 已设置为："

    arr["ENGLISH","custom_et_text_10"]="Invalid format. Generating standard BSSID..."
    arr["SPANISH","custom_et_text_10"]="Formato no válido. Generando BSSID estándar..."
    arr["FRENCH","custom_et_text_10"]="Format invalide. Génération du BSSID standard..."
    arr["CATALAN","custom_et_text_10"]="Format no vàlid. Generant BSSID estàndard..."
    arr["PORTUGUESE","custom_et_text_10"]="Formato inválido. Gerando BSSID padrão..."
    arr["RUSSIAN","custom_et_text_10"]="Неверный формат. Генерация стандартного BSSID..."
    arr["GREEK","custom_et_text_10"]="Μη έγκυρη μορφή. Δημιουργία τυπικού BSSID..."
    arr["ITALIAN","custom_et_text_10"]="Formato non valido. Generazione del BSSID standard..."
    arr["POLISH","custom_et_text_10"]="Nieprawidłowy format. Generowanie standardowego BSSID..."
    arr["GERMAN","custom_et_text_10"]="Ungültiges Format. Standard-BSSID wird generiert..."
    arr["TURKISH","custom_et_text_10"]="Geçersiz biçim. Standart BSSID oluşturuluyor..."
    arr["ARABIC","custom_et_text_10"]="تنسيق غير صالح. جارٍ إنشاء BSSID الافتراضي..."
    arr["CHINESE","custom_et_text_10"]="格式无效。正在生成标准 BSSID..."

    arr["ENGLISH","custom_et_text_11"]="OK. Standard airgeddon BSSID will be used."
    arr["SPANISH","custom_et_text_11"]="OK. Se utilizará el BSSID estándar de airgeddon."
    arr["FRENCH","custom_et_text_11"]="OK. Le BSSID standard d'airgeddon sera utilisé."
    arr["CATALAN","custom_et_text_11"]="OK. S'utilitzarà el BSSID estàndard d'airgeddon."
    arr["PORTUGUESE","custom_et_text_11"]="OK. O BSSID padrão do airgeddon será usado."
    arr["RUSSIAN","custom_et_text_11"]="ОК. Будет использован стандартный BSSID airgeddon."
    arr["GREEK","custom_et_text_11"]="OK. Θα χρησιμοποιηθεί το τυπικό BSSID του airgeddon."
    arr["ITALIAN","custom_et_text_11"]="OK. Verrà utilizzato il BSSID standard di airgeddon."
    arr["POLISH","custom_et_text_11"]="OK. Zostanie użyty standardowy BSSID airgeddon."
    arr["GERMAN","custom_et_text_11"]="OK. Die Standard airgeddon BSSID wird verwendet."
    arr["TURKISH","custom_et_text_11"]="Tamam. Standart airgeddon BSSID kullanılacak."
    arr["ARABIC","custom_et_text_11"]="حسنا. سيتم استخدام BSSID الافتراضي لـ airgeddon."
    arr["CHINESE","custom_et_text_11"]="好的。将使用标准 airgeddon BSSID。"

    arr["ENGLISH","custom_et_text_12"]="Current channel:"
    arr["SPANISH","custom_et_text_12"]="Canal actual:"
    arr["FRENCH","custom_et_text_12"]="Canal actuel :"
    arr["CATALAN","custom_et_text_12"]="Canal actual:"
    arr["PORTUGUESE","custom_et_text_12"]="Canal atual:"
    arr["RUSSIAN","custom_et_text_12"]="Текущий канал:"
    arr["GREEK","custom_et_text_12"]="Τρέχον κανάλι:"
    arr["ITALIAN","custom_et_text_12"]="Canale attuale:"
    arr["POLISH","custom_et_text_12"]="Aktualny kanał:"
    arr["GERMAN","custom_et_text_12"]="Aktueller Kanal:"
    arr["TURKISH","custom_et_text_12"]="Geçerli kanal:"
    arr["ARABIC","custom_et_text_12"]="القناة الحالية:"
    arr["CHINESE","custom_et_text_12"]="当前信道："

    arr["ENGLISH","custom_et_text_12b"]="Enter a new channel (e.g. 1-233) or press Enter to keep it:"
    arr["SPANISH","custom_et_text_12b"]="Introduzca un nuevo canal (ej. 1-233) o presione Intro para mantenerlo:"
    arr["FRENCH","custom_et_text_12b"]="Entrez un nouveau canal (par ex. 1-233) ou appuyez sur Entrée pour le conserver :"
    arr["CATALAN","custom_et_text_12b"]="Introduïu un canal nou (p. ex. 1-233) o premeu Enter per mantenir-lo:"
    arr["PORTUGUESE","custom_et_text_12b"]="Digite um novo canal (ex. 1-233) ou pressione Enter para mantê-lo:"
    arr["RUSSIAN","custom_et_text_12b"]="Введите новый канал (например, 1-233) или нажмите Enter, чтобы оставить его:"
    arr["GREEK","custom_et_text_12b"]="Εισαγάγετε νέο κανάλι (π.χ. 1-233) ή πατήστε Enter για να το κρατήσετε:"
    arr["ITALIAN","custom_et_text_12b"]="Inserisci un nuovo canale (es. 1-233) o premi Invio per mantenerlo:"
    arr["POLISH","custom_et_text_12b"]="Wprowadź nowy kanał (np. 1-233) lub naciśnij Enter, aby go zachować:"
    arr["GERMAN","custom_et_text_12b"]="Geben Sie einen neuen Kanal (z.B. 1-233) ein oder drücken Sie Enter, um ihn beizubehalten:"
    arr["TURKISH","custom_et_text_12b"]="Yeni bir kanal girin (örn. 1-233) veya korumak için Enter'a basın:"
    arr["ARABIC","custom_et_text_12b"]="أدخل قناة جديدة (مثلاً 1-233) أو اضغط Enter للاحتفاظ بها:"
    arr["CHINESE","custom_et_text_12b"]="输入新信道（例如 1-233）或按回车键保持不变："

    arr["ENGLISH","custom_et_text_13"]="Channel has been set to:"
    arr["SPANISH","custom_et_text_13"]="El canal se configuró en:"
    arr["FRENCH","custom_et_text_13"]="Le canal a été défini sur :"
    arr["CATALAN","custom_et_text_13"]="El canal s'ha establert a:"
    arr["PORTUGUESE","custom_et_text_13"]="O canal foi definido para:"
    arr["RUSSIAN","custom_et_text_13"]="Канал установлен на:"
    arr["GREEK","custom_et_text_13"]="Το κανάλι έχει οριστεί σε:"
    arr["ITALIAN","custom_et_text_13"]="Il canale è stato impostato su:"
    arr["POLISH","custom_et_text_13"]="Kanał został ustawiony na:"
    arr["GERMAN","custom_et_text_13"]="Kanal wurde gesetzt auf:"
    arr["TURKISH","custom_et_text_13"]="Kanal şu olarak ayarlandı:"
    arr["ARABIC","custom_et_text_13"]="تم تعيين القناة إلى:"
    arr["CHINESE","custom_et_text_13"]="信道已设置为："

    arr["ENGLISH","custom_et_text_14"]="Keeping standard channel:"
    arr["SPANISH","custom_et_text_14"]="Manteniendo el canal estándar:"
    arr["FRENCH","custom_et_text_14"]="Conservation du canal standard :"
    arr["CATALAN","custom_et_text_14"]="Es manté el canal estàndard:"
    arr["PORTUGUESE","custom_et_text_14"]="Mantendo o canal padrão:"
    arr["RUSSIAN","custom_et_text_14"]="Сохранение стандартного канала:"
    arr["GREEK","custom_et_text_14"]="Διατήρηση τυπικού καναλιού:"
    arr["ITALIAN","custom_et_text_14"]="Mantenimento del canale standard:"
    arr["POLISH","custom_et_text_14"]="Zachowanie standardowego kanału:"
    arr["GERMAN","custom_et_text_14"]="Standard-Kanal wird verwendet:"
    arr["TURKISH","custom_et_text_14"]="Standart kanal korunuyor:"
    arr["ARABIC","custom_et_text_14"]="الاحتفاظ بالقناة القياسية:"
    arr["CHINESE","custom_et_text_14"]="保持标准信道："

    arr["ENGLISH","custom_et_text_15"]="How should the ESSID (AP name) for the Evil Twin be set?"
    arr["SPANISH","custom_et_text_15"]="¿Cómo se debe configurar el ESSID (nombre del AP) para el Evil Twin?"
    arr["FRENCH","custom_et_text_15"]="Comment définir l'ESSID (nom AP) pour l'Evil Twin ?"
    arr["CATALAN","custom_et_text_15"]="Com s'ha d'establir l'ESSID (nom AP) per a l'Evil Twin?"
    arr["PORTUGUESE","custom_et_text_15"]="Como o ESSID (nome AP) para o Evil Twin deve ser definido?"
    arr["RUSSIAN","custom_et_text_15"]="Как должен быть установлен ESSID (имя AP) для Evil Twin?"
    arr["GREEK","custom_et_text_15"]="Πώς πρέπει να ρυθμιστεί το ESSID (όνομα AP) για το Evil Twin;"
    arr["ITALIAN","custom_et_text_15"]="Come dovrebbe essere impostato l'ESSID (nome AP) per l'Evil Twin?"
    arr["POLISH","custom_et_text_15"]="Jak ustawić ESSID (nazwę AP) dla Evil Twin?"
    arr["GERMAN","custom_et_text_15"]="Wie soll die ESSID (AP-Name) für den Evil Twin festgelegt werden?"
    arr["TURKISH","custom_et_text_15"]="Evil Twin için ESSID (AP adı) nasıl ayarlanmalı?"
    arr["ARABIC","custom_et_text_15"]="كيف يجب تعيين ESSID (اسم نقطة الوصول) لـ Evil Twin؟"
    arr["CHINESE","custom_et_text_15"]="应该如何设置 Evil Twin 的 ESSID（AP名称）？"

    arr["ENGLISH","custom_et_text_16"]="Use exact original ESSID"
    arr["SPANISH","custom_et_text_16"]="Usar el ESSID original exacto"
    arr["FRENCH","custom_et_text_16"]="Utiliser l'ESSID original exact"
    arr["CATALAN","custom_et_text_16"]="Utilitzar l'ESSID original exacte"
    arr["PORTUGUESE","custom_et_text_16"]="Usar o ESSID original exato"
    arr["RUSSIAN","custom_et_text_16"]="Использовать точный исходный ESSID"
    arr["GREEK","custom_et_text_16"]="Χρησιμοποιήστε το ακριβές αρχικό ESSID"
    arr["ITALIAN","custom_et_text_16"]="Usa l'esatto ESSID originale"
    arr["POLISH","custom_et_text_16"]="Użyj dokładnego oryginalnego ESSID"
    arr["GERMAN","custom_et_text_16"]="Exakte originale ESSID verwenden"
    arr["TURKISH","custom_et_text_16"]="Tam orijinal ESSID'yi kullan"
    arr["ARABIC","custom_et_text_16"]="استخدام ESSID الأصلي بالضبط"
    arr["CHINESE","custom_et_text_16"]="使用确切的原始 ESSID"

    arr["ENGLISH","custom_et_text_17"]="Enter a new ESSID manually"
    arr["SPANISH","custom_et_text_17"]="Introducir un nuevo ESSID manualmente"
    arr["FRENCH","custom_et_text_17"]="Entrer manuellement un nouvel ESSID"
    arr["CATALAN","custom_et_text_17"]="Introduir manualment un nou ESSID"
    arr["PORTUGUESE","custom_et_text_17"]="Inserir manualmente um novo ESSID"
    arr["RUSSIAN","custom_et_text_17"]="Ввести новый ESSID вручную"
    arr["GREEK","custom_et_text_17"]="Εισαγάγετε ένα νέο ESSID χειροκίνητα"
    arr["ITALIAN","custom_et_text_17"]="Inserisci manualmente un nuovo ESSID"
    arr["POLISH","custom_et_text_17"]="Wprowadź nowy ESSID ręcznie"
    arr["GERMAN","custom_et_text_17"]="Eine neue ESSID manuell eingeben"
    arr["TURKISH","custom_et_text_17"]="Yeni bir ESSID'yi manuel gir"
    arr["ARABIC","custom_et_text_17"]="إدخال ESSID جديد يدويًا"
    arr["CHINESE","custom_et_text_17"]="手动输入新的 ESSID"

    arr["ENGLISH","custom_et_text_18"]="Use standard (fake) airgeddon ESSID (default)"
    arr["SPANISH","custom_et_text_18"]="Usar ESSID estándar (falso) de airgeddon (predeterminado)"
    arr["FRENCH","custom_et_text_18"]="Utiliser l'ESSID standard (faux) d'airgeddon (par défaut)"
    arr["CATALAN","custom_et_text_18"]="Utilitzar l'ESSID estàndard (fals) d'airgeddon (predeterminat)"
    arr["PORTUGUESE","custom_et_text_18"]="Usar o ESSID padrão (falso) do airgeddon (padrão)"
    arr["RUSSIAN","custom_et_text_18"]="Использовать стандартный (поддельный) ESSID airgeddon (по умолчанию)"
    arr["GREEK","custom_et_text_18"]="Χρησιμοποιήστε το τυπικό (ψεύτικο) ESSID του airgeddon (προεπιλογή)"
    arr["ITALIAN","custom_et_text_18"]="Usa l'ESSID standard (falso) di airgeddon (predefinito)"
    arr["POLISH","custom_et_text_18"]="Użyj standardowego (fałszywego) ESSID airgeddon (domyślnie)"
    arr["GERMAN","custom_et_text_18"]="Standard (gefälschte) airgeddon ESSID verwenden (Standard)"
    arr["TURKISH","custom_et_text_18"]="Standart (sahte) airgeddon ESSID kullan (varsayılan)"
    arr["ARABIC","custom_et_text_18"]="استخدام ESSID الافتراضي (المزيف) لـ airgeddon (الافتراضي)"
    arr["CHINESE","custom_et_text_18"]="使用标准（伪造的）airgeddon ESSID（默认）"

    arr["ENGLISH","custom_et_text_19"]="OK. Exact original ESSID will be used:"
    arr["SPANISH","custom_et_text_19"]="OK. Se utilizará el ESSID original:"
    arr["FRENCH","custom_et_text_19"]="OK. L'ESSID original sera utilisé :"
    arr["CATALAN","custom_et_text_19"]="OK. S'utilitzarà l'ESSID original:"
    arr["PORTUGUESE","custom_et_text_19"]="OK. O ESSID original será usado:"
    arr["RUSSIAN","custom_et_text_19"]="ОК. Будет использован исходный ESSID:"
    arr["GREEK","custom_et_text_19"]="OK. Το αρχικό ESSID θα χρησιμοποιηθεί:"
    arr["ITALIAN","custom_et_text_19"]="OK. Verrà utilizzato l'ESSID originale:"
    arr["POLISH","custom_et_text_19"]="OK. Zostanie użyty oryginalny ESSID:"
    arr["GERMAN","custom_et_text_19"]="OK. Die originale ESSID wird verwendet:"
    arr["TURKISH","custom_et_text_19"]="Tamam. Orijinal ESSID kullanılacak:"
    arr["ARABIC","custom_et_text_19"]="حسنا. سيتم استخدام ESSID الأصلي:"
    arr["CHINESE","custom_et_text_19"]="好的。将使用原始 ESSID："

    arr["ENGLISH","custom_et_text_20"]="Please enter the desired ESSID (cannot be empty):"
    arr["SPANISH","custom_et_text_20"]="Introduzca el ESSID deseado (no puede estar vacío):"
    arr["FRENCH","custom_et_text_20"]="Veuillez entrer l'ESSID souhaité (ne peut pas être vide) :"
    arr["CATALAN","custom_et_text_20"]="Introduïu l'ESSID desitjat (no pot estar buit):"
    arr["PORTUGUESE","custom_et_text_20"]="Insira o ESSID desejado (não pode estar vazio):"
    arr["RUSSIAN","custom_et_text_20"]="Пожалуйста, введите желаемый ESSID (не может быть пустым):"
    arr["GREEK","custom_et_text_20"]="Παρακαλώ εισαγάγετε το επιθυμητό ESSID (δεν μπορεί να είναι κενό):"
    arr["ITALIAN","custom_et_text_20"]="Inserisci l'ESSID desiderato (non può essere vuoto):"
    arr["POLISH","custom_et_text_20"]="Wprowadź żądany ESSID (nie może być pusty):"
    arr["GERMAN","custom_et_text_20"]="Geben Sie die gewünschte ESSID ein (darf nicht leer sein):"
    arr["TURKISH","custom_et_text_20"]="Lütfen istenen ESSID'yi girin (boş olamaz):"
    arr["ARABIC","custom_et_text_20"]="الرجاء إدخال ESSID المطلوب (لا يمكن أن يكون فارغًا):"
    arr["CHINESE","custom_et_text_20"]="请输入所需的 ESSID（不能为空）："

    arr["ENGLISH","custom_et_text_21"]="ESSID has been set to:"
    arr["SPANISH","custom_et_text_21"]="ESSID se ha configurado en:"
    arr["FRENCH","custom_et_text_21"]="L'ESSID a été défini sur :"
    arr["CATALAN","custom_et_text_21"]="L'ESSID s'ha establert a:"
    arr["PORTUGUESE","custom_et_text_21"]="O ESSID foi definido para:"
    arr["RUSSIAN","custom_et_text_21"]="ESSID был установлен на:"
    arr["GREEK","custom_et_text_21"]="Το ESSID έχει οριστεί σε:"
    arr["ITALIAN","custom_et_text_21"]="L'ESSID è stato impostato su:"
    arr["POLISH","custom_et_text_21"]="ESSID został ustawiony na:"
    arr["GERMAN","custom_et_text_21"]="ESSID wurde gesetzt auf:"
    arr["TURKISH","custom_et_text_21"]="ESSID şu olarak ayarlandı:"
    arr["ARABIC","custom_et_text_21"]="تم تعيين ESSID إلى:"
    arr["CHINESE","custom_et_text_21"]="ESSID 已设置为："

    arr["ENGLISH","custom_et_text_22"]="No input. Generating standard ESSID..."
    arr["SPANISH","custom_et_text_22"]="Sin entrada. Generando ESSID estándar..."
    arr["FRENCH","custom_et_text_22"]="Aucune saisie. Génération de l'ESSID standard..."
    arr["CATALAN","custom_et_text_22"]="Sense entrada. Generant ESSID estàndard..."
    arr["PORTUGUESE","custom_et_text_22"]="Sem entrada. Gerando ESSID padrão..."
    arr["RUSSIAN","custom_et_text_22"]="Нет ввода. Генерация стандартного ESSID..."
    arr["GREEK","custom_et_text_22"]="Καμία εισαγωγή. Δημιουργία τυπικού ESSID..."
    arr["ITALIAN","custom_et_text_22"]="Nessun input. Generazione dell'ESSID standard..."
    arr["POLISH","custom_et_text_22"]="Brak danych. Generowanie standardowego ESSID..."
    arr["GERMAN","custom_et_text_22"]="Keine Eingabe. Standard-ESSID wird generiert..."
    arr["TURKISH","custom_et_text_22"]="Giriş yok. Standart ESSID oluşturuluyor..."
    arr["ARABIC","custom_et_text_22"]="لا يوجد إدخال. جارٍ إنشاء ESSID الافتراضي..."
    arr["CHINESE","custom_et_text_22"]="无输入。正在生成标准 ESSID..."

    arr["ENGLISH","custom_et_text_23"]="OK. Standard airgeddon ESSID will be used."
    arr["SPANISH","custom_et_text_23"]="OK. Se utilizará el ESSID estándar de airgeddon."
    arr["FRENCH","custom_et_text_23"]="OK. L'ESSID standard d'airgeddon sera utilisé."
    arr["CATALAN","custom_et_text_23"]="OK. S'utilitzarà l'ESSID estàndard d'airgeddon."
    arr["PORTUGUESE","custom_et_text_23"]="OK. O ESSID padrão do airgeddon será usado."
    arr["RUSSIAN","custom_et_text_23"]="ОК. Будет использован стандартный ESSID airgeddon."
    arr["GREEK","custom_et_text_23"]="OK. Θα χρησιμοποιηθεί το τυπικό ESSID του airgeddon."
    arr["ITALIAN","custom_et_text_23"]="OK. Verrà utilizzato l'ESSID standard di airgeddon."
    arr["POLISH","custom_et_text_23"]="OK. Zostanie użyty standardowy ESSID airgeddon."
    arr["GERMAN","custom_et_text_23"]="OK. Die Standard airgeddon ESSID wird verwendet."
    arr["TURKISH","custom_et_text_23"]="Tamam. Standart airgeddon ESSID kullanılacak."
    arr["ARABIC","custom_et_text_23"]="حسنا. سيتم استخدام ESSID الافتراضي لـ airgeddon."
    arr["CHINESE","custom_et_text_23"]="好的。将使用标准 airgeddon ESSID。"

    arr["ENGLISH","custom_et_text_24"]="Note: Changing channel means DoS won't work simultaneously on original channel."
    arr["SPANISH","custom_et_text_24"]="Nota: Cambiar de canal significa que DoS no funcionará simultáneamente en el canal original."
    arr["FRENCH","custom_et_text_24"]="Note : Changer de canal signifie que le DoS ne fonctionnera pas simultanément sur le canal d'origine."
    arr["CATALAN","custom_et_text_24"]="Nota: Canviar de canal significa que DoS no funcionarà simultàniament al canal original."
    arr["PORTUGUESE","custom_et_text_24"]="Nota: Mudar de canal significa que o DoS não funcionará simultaneamente no canal original."
    arr["RUSSIAN","custom_et_text_24"]="Примечание: Смена канала означает, что DoS не будет работать одновременно на исходном канале."
    arr["GREEK","custom_et_text_24"]="Σημείωση: Η αλλαγή καναλιού σημαίνει ότι το DoS δεν θα λειτουργεί ταυτόχρονα στο αρχικό κανάλι."
    arr["ITALIAN","custom_et_text_24"]="Nota: Cambiare canale significa che il DoS non funzionerà simultaneamente sul canale originale."
    arr["POLISH","custom_et_text_24"]="Uwaga: Zmiana kanału oznacza, że DoS nie będzie działał jednocześnie na oryginalnym kanale."
    arr["GERMAN","custom_et_text_24"]="Hinweis: Kanalwechsel bedeutet, dass DoS nicht gleichzeitig auf Originalkanal funktioniert."
    arr["TURKISH","custom_et_text_24"]="Not: Kanalı değiştirmek, DoS'un orijinal kanalda eşzamanlı çalışmayacağı anlamına gelir."
    arr["ARABIC","custom_et_text_24"]="ملاحظة: تغيير القناة يعني أن هجوم DoS لن يعمل في نفس الوقت على القناة الأصلية."
    arr["CHINESE","custom_et_text_24"]="注意：更改信道意味着 DoS 将不会在原始信道上同时工作。"

    arr["ENGLISH","custom_et_text_25"]="Which band does this channel belong to?"
    arr["SPANISH","custom_et_text_25"]="¿A qué banda pertenece este canal?"
    arr["FRENCH","custom_et_text_25"]="À quelle bande appartient ce canal ?"
    arr["CATALAN","custom_et_text_25"]="A quina banda pertany aquest canal?"
    arr["PORTUGUESE","custom_et_text_25"]="A qual banda este canal pertence?"
    arr["RUSSIAN","custom_et_text_25"]="К какому диапазону относится этот канал?"
    arr["GREEK","custom_et_text_25"]="Σε ποια ζώνη ανήκει αυτό το κανάλι;"
    arr["ITALIAN","custom_et_text_25"]="A quale banda appartiene questo canale?"
    arr["POLISH","custom_et_text_25"]="Do którego pasma należy ten kanał?"
    arr["GERMAN","custom_et_text_25"]="Zu welchem Band gehört dieser Kanal?"
    arr["TURKISH","custom_et_text_25"]="Bu kanal hangi banda ait?"
    arr["ARABIC","custom_et_text_25"]="إلى أي نطاق تنتمي هذه القناة؟"
    arr["CHINESE","custom_et_text_25"]="此信道属于哪个频段？"

    return 0
}

function _custom_et_interactive_prompt() {
	debug_print

	local lang_key="${language}"
	if [[ -z "${arr["${lang_key}","custom_et_text_1"]}" ]]; then
		lang_key="ENGLISH"
	fi

	custom_et_chosen_bssid=""
	custom_et_chosen_essid=""

	echo
	echo -e "${yellow_color}${arr["${lang_key}","custom_et_text_1"]}${normal_color}"
	echo

	echo -e "${cyan_color}${arr["${lang_key}","custom_et_text_2"]}${normal_color}"
	echo -e "1. ${arr["${lang_key}","custom_et_text_3"]} (${bssid})"
	echo -e "2. ${arr["${lang_key}","custom_et_text_4"]}"
	echo -e "3. ${arr["${lang_key}","custom_et_text_5"]}"
	read -rp "> " bssid_choice

	case "${bssid_choice}" in
		1)
			custom_et_chosen_bssid="${bssid}"
			echo -e "${green_color}${arr["${lang_key}","custom_et_text_6"]} ${custom_et_chosen_bssid}${normal_color}"
			echo -e "${red_color}${arr["${lang_key}","custom_et_text_7"]}${normal_color}"
			;;
		2)
			echo -e "${green_color}${arr["${lang_key}","custom_et_text_8"]}${normal_color}"
			read -rp "> " custom_bssid
			if [[ -n "${custom_bssid}" && "${custom_bssid}" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
				custom_et_chosen_bssid="${custom_bssid}"
				echo -e "${green_color}${arr["${lang_key}","custom_et_text_9"]} ${custom_et_chosen_bssid}${normal_color}"
			else
				echo -e "${red_color}${arr["${lang_key}","custom_et_text_10"]}${normal_color}"
			fi
			;;
		*)
			echo -e "${green_color}${arr["${lang_key}","custom_et_text_11"]}${normal_color}"
			;;
	esac

	echo
	echo -e "${cyan_color}${arr["${lang_key}","custom_et_text_12"]} ${channel}${normal_color}"
	echo -e "${red_color}${arr["${lang_key}","custom_et_text_24"]}${normal_color}"
	echo -e "${cyan_color}${arr["${lang_key}","custom_et_text_12b"]}${normal_color}"
	read -rp "> " custom_channel

	if [[ -n "${custom_channel}" && "${custom_channel}" =~ ^[0-9]+$ && "${custom_channel}" -gt 0 && "${custom_channel}" -le 233 ]]; then
		channel="${custom_channel}"
		echo "${channel}" > "${tmpdir}${channelfile}"
		echo -e "${green_color}${arr["${lang_key}","custom_et_text_13"]} ${channel}${normal_color}"
		
		echo
		echo -e "${cyan_color}${arr["${lang_key}","custom_et_text_25"]}${normal_color}"
		echo "1. 2.4Ghz"
		echo "2. 5Ghz"
		echo "3. 6Ghz"
		local valid_band=0
		while [[ ${valid_band} -eq 0 ]]; do
			read -rp "> " custom_band_choice
			case "${custom_band_choice}" in
				1) band="2.4Ghz"; valid_band=1 ;;
				2) band="5Ghz"; valid_band=1 ;;
				3) band="6Ghz"; valid_band=1 ;;
				*) echo -e "${red_color}Invalid / Ungültig${normal_color}" ;;
			esac
		done
		echo -e "${green_color}Band -> ${band}${normal_color}"
	else
		echo -e "${green_color}${arr["${lang_key}","custom_et_text_14"]} ${channel}${normal_color}"
	fi

	echo
	echo -e "${cyan_color}${arr["${lang_key}","custom_et_text_15"]}${normal_color}"
	echo -e "1. ${arr["${lang_key}","custom_et_text_16"]} (${essid})"
	echo -e "2. ${arr["${lang_key}","custom_et_text_17"]}"
	echo -e "3. ${arr["${lang_key}","custom_et_text_18"]}"
	read -rp "> " essid_choice

	case "${essid_choice}" in
		1)
			custom_et_chosen_essid="${essid}"
			echo -e "${green_color}${arr["${lang_key}","custom_et_text_19"]} \"${essid}\"${normal_color}"
			;;
		2)
			local custom_essid=""
			echo -e "${green_color}${arr["${lang_key}","custom_et_text_20"]}${normal_color}"
			while [[ -z "${custom_essid}" ]]; do
				read -r -p "> " custom_essid
			done
			custom_et_chosen_essid="${custom_essid}"
			echo -e "${green_color}${arr["${lang_key}","custom_et_text_21"]} \"${custom_essid}\"${normal_color}"
			;;
		*)
			custom_et_chosen_essid="${essid}"
			echo -e "${green_color}${arr["${lang_key}","custom_et_text_23"]} \"${essid}\"${normal_color}"
			;;
	esac

	echo
	sleep 2

	if [[ -n "${custom_et_chosen_essid}" ]]; then
		et_essid="${custom_et_chosen_essid}"
	fi
	if [[ -n "${custom_et_chosen_bssid}" ]]; then
		et_bssid="${custom_et_chosen_bssid}"
	fi
}

function custom_et_control_prehook_set_hostapd_config() { _custom_et_interactive_prompt; }
function custom_et_control_prehook_set_hostapd_wpe_config() { _custom_et_interactive_prompt; }
function custom_et_control_prehook_set_hostapd_mana_config() { _custom_et_interactive_prompt; }

# Changed hook location to prehook_launch_webserver to avoid conflict
function _apply_custom_et_config() {
	local target_config_file="${1}"

	if [[ -n "${custom_et_chosen_bssid}" ]]; then
		et_bssid="${custom_et_chosen_bssid}"
		sed -ri "s/^bssid=.*/bssid=${et_bssid}/" "${target_config_file}" 2> /dev/null
	fi

	if [[ -n "${custom_et_chosen_essid}" ]]; then
		et_essid="${custom_et_chosen_essid}"
		local safe_essid
		safe_essid=$(printf '%s' "${et_essid}" | sed -e 's/\\/\\\\/g' -e 's/|/\\|/g' -e 's/&/\\&/g')
		sed -ri "s|^ssid=.*|ssid=${safe_essid}|" "${target_config_file}" 2> /dev/null
	fi
}

function custom_et_control_posthook_set_hostapd_config() { _apply_custom_et_config "${tmpdir}${hostapd_file}"; return 0; }
function custom_et_control_posthook_set_hostapd_wpe_config() { _apply_custom_et_config "${tmpdir}${hostapd_wpe_file}"; return 0; }
function custom_et_control_posthook_set_hostapd_mana_config() { _apply_custom_et_config "${tmpdir}${hostapd_mana_file}"; return 0; }

# Posthooking launch_webserver instead of launch_captive_portal
# because airgeddon requires hookable functions to exist directly as 'function name()'.
function custom_et_control_prehook_launch_webserver() {
	if [[ -n "${custom_et_chosen_essid}" ]] && [[ "${custom_et_chosen_essid}" != "${essid}" ]]; then
		local portal_index="${tmpdir}${webdir}${indexfile}"
		if [[ -f "${portal_index}" ]]; then
			local safe_old_essid
			safe_old_essid=$(printf '%s
' "${essid}" | sed 's/[][\/.*^$]/\&/g')
			local safe_new_essid
			safe_new_essid=$(printf '%s
' "${custom_et_chosen_essid}" | sed -e 's/[\/&]/\&/g')
			sed -i "s/${safe_old_essid}/${safe_new_essid}/g" "${portal_index}" 2> /dev/null
		fi
	fi
    return 0
}
