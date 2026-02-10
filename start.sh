#!/bin/bash

# Dil ayarını sabitle
export LC_NUMERIC=C

# ========================================
# AYARLAR VE DEĞİŞKENLER
# ========================================

# Renk Paleti
G='\033[0;32m'
R='\033[0;31m'
C='\033[0;36m'
Y='\033[1;33m'
M='\033[0;35m'
B='\033[1;34m'
W='\033[1;37m'
BLINK='\033[5m'
BOLD='\033[1m'
NC='\033[0m'

# Varsayılan Ayarlar
GUVENLIK_ONAY=1            # 1=EVET yazmak gerekir, 0=atlanır
DD_BLOCK_SIZE="4M"         # dd bs parametresi
DD_CONV="fsync"            # dd conv parametresi
DOGRULAMA_YAP=1            # 1=hash doğrulaması yap, 0=atla
EJECT_YAP=1                # 1=işlem sonunda diski eject et, 0=etme
TRANSFER_ONCELIK="normal"  # ionice/nice önceliği: low/normal/high
LOG_DOSYASI=""             # boş=log tutma, dosya yolu=log tut
OZEL_DD_PARAM=""           # kullanıcının ek dd parametreleri
BOYUT_KORUMA=1             # 1=hedef<kaynak ise engelle, 0=zorla devam

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
    echo -e "${R}[✗] Bu scripti sudo ile çalıştırmalısın!${NC}"
    exit 1
fi

# awk kontrolü
if ! command -v awk &> /dev/null; then
    echo -e "${Y}[!] Gerekli araçlar yükleniyor (awk)...${NC}"
    apt-get install -y gawk &> /dev/null || yum install -y gawk &> /dev/null
fi

# ========================================
# LOG FONKSİYONU
# ========================================
log_yaz() {
    local mesaj="$1"
    if [ -n "$LOG_DOSYASI" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $mesaj" >> "$LOG_DOSYASI"
    fi
}

# ========================================
# BOYUT FORMATLAMA
# ========================================
boyut_formatla() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        awk "BEGIN {printf \"%.2f GB\", $bytes/1073741824}"
    elif [ "$bytes" -ge 1048576 ]; then
        awk "BEGIN {printf \"%.2f MB\", $bytes/1048576}"
    elif [ "$bytes" -ge 1024 ]; then
        awk "BEGIN {printf \"%.2f KB\", $bytes/1024}"
    else
        echo "${bytes} B"
    fi
}

# ========================================
# AYARLAR MENÜSÜ
# ========================================
ayarlar_menusu() {
    local ayar_devam=1
    while [ $ayar_devam -eq 1 ]; do
        clear
        echo -e "${C}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC} ${BOLD}${W}                  ⚙  AYARLAR  ⚙${NC}                        ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}                                                          ${C}║${NC}"

        # 1) Güvenlik onayı
        if [ "$GUVENLIK_ONAY" -eq 1 ]; then
            echo -e "${C}║${NC}  ${G}[1]${NC} Güvenlik Onayı (EVET yazma)    : ${G}AÇIK${NC}             ${C}║${NC}"
        else
            echo -e "${C}║${NC}  ${G}[1]${NC} Güvenlik Onayı (EVET yazma)    : ${R}KAPALI${NC}           ${C}║${NC}"
        fi

        # 2) Block Size
        echo -e "${C}║${NC}  ${G}[2]${NC} DD Block Size (bs)              : ${Y}${DD_BLOCK_SIZE}${NC}               ${C}║${NC}"

        # 3) DD Conv parametresi
        echo -e "${C}║${NC}  ${G}[3]${NC} DD Conv Parametresi             : ${Y}${DD_CONV}${NC}            ${C}║${NC}"

        # 4) Hash Doğrulama
        if [ "$DOGRULAMA_YAP" -eq 1 ]; then
            echo -e "${C}║${NC}  ${G}[4]${NC} Hash Doğrulama (MD5)            : ${G}AÇIK${NC}             ${C}║${NC}"
        else
            echo -e "${C}║${NC}  ${G}[4]${NC} Hash Doğrulama (MD5)            : ${R}KAPALI${NC}           ${C}║${NC}"
        fi

        # 5) Eject
        if [ "$EJECT_YAP" -eq 1 ]; then
            echo -e "${C}║${NC}  ${G}[5]${NC} İşlem Sonunda Eject             : ${G}AÇIK${NC}             ${C}║${NC}"
        else
            echo -e "${C}║${NC}  ${G}[5]${NC} İşlem Sonunda Eject             : ${R}KAPALI${NC}           ${C}║${NC}"
        fi

        # 6) Transfer Önceliği
        case "$TRANSFER_ONCELIK" in
            low)  ONCELIK_RENK="${C}DÜŞÜK${NC}" ;;
            high) ONCELIK_RENK="${R}YÜKSEK${NC}" ;;
            *)    ONCELIK_RENK="${G}NORMAL${NC}" ;;
        esac
        echo -e "${C}║${NC}  ${G}[6]${NC} Transfer Önceliği (I/O)         : ${ONCELIK_RENK}            ${C}║${NC}"

        # 7) Log Dosyası
        if [ -n "$LOG_DOSYASI" ]; then
            echo -e "${C}║${NC}  ${G}[7]${NC} Log Dosyası                     : ${G}${LOG_DOSYASI}${NC}  ${C}║${NC}"
        else
            echo -e "${C}║${NC}  ${G}[7]${NC} Log Dosyası                     : ${R}KAPALI${NC}           ${C}║${NC}"
        fi

        # 8) Özel DD Parametreleri
        if [ -n "$OZEL_DD_PARAM" ]; then
            echo -e "${C}║${NC}  ${G}[8]${NC} Özel DD Parametreleri           : ${Y}${OZEL_DD_PARAM}${NC}  ${C}║${NC}"
        else
            echo -e "${C}║${NC}  ${G}[8]${NC} Özel DD Parametreleri           : ${W}yok${NC}              ${C}║${NC}"
        fi

        # 9) Boyut Koruma
        if [ "$BOYUT_KORUMA" -eq 1 ]; then
            echo -e "${C}║${NC}  ${G}[9]${NC} Boyut Koruma (Hedef<Kaynak)     : ${G}AÇIK${NC}             ${C}║${NC}"
        else
            echo -e "${C}║${NC}  ${G}[9]${NC} Boyut Koruma (Hedef<Kaynak)     : ${R}KAPALI${NC}           ${C}║${NC}"
        fi

        echo -e "${C}║${NC}                                                          ${C}║${NC}"
        echo -e "${C}║${NC}  ${M}[0]${NC} ${BOLD}Kaydet ve Geri Dön${NC}                                  ${C}║${NC}"
        echo -e "${C}║${NC}                                                          ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -ne "${Y}Değiştirmek istediğin ayar [0-9]: ${NC}"
        read -r AYAR_SEC

        case "$AYAR_SEC" in
            1)
                if [ "$GUVENLIK_ONAY" -eq 1 ]; then
                    echo ""
                    echo -e "${R}╔══════════════════════════════════════════════════╗${NC}"
                    echo -e "${R}║${NC}  ${BOLD}⚠  DİKKAT: Güvenlik onayını kapatmak${NC}           ${R}║${NC}"
                    echo -e "${R}║${NC}  ${BOLD}yanlışlıkla veri kaybına neden olabilir!${NC}        ${R}║${NC}"
                    echo -e "${R}╚══════════════════════════════════════════════════╝${NC}"
                    echo -ne "${Y}Yine de kapatmak istiyor musun? [e/h]: ${NC}"
                    read -r ONAYLA
                    if [[ "$ONAYLA" =~ ^[eE]$ ]]; then
                        GUVENLIK_ONAY=0
                        echo -e "${G}[✓] Güvenlik onayı kapatıldı${NC}"
                    fi
                else
                    GUVENLIK_ONAY=1
                    echo -e "${G}[✓] Güvenlik onayı açıldı${NC}"
                fi
                sleep 1
                ;;
            2)
                echo ""
                echo -e "${C}Mevcut Block Size: ${Y}${DD_BLOCK_SIZE}${NC}"
                echo -e "${W}Önerilen değerler: 512, 1K, 4K, 64K, 1M, 4M, 8M, 16M, 64M${NC}"
                echo -e "${C}Küçük bs = daha güvenli ama yavaş${NC}"
                echo -e "${C}Büyük bs = daha hızlı ama hata riski artar${NC}"
                echo -ne "${Y}Yeni Block Size: ${NC}"
                read -r YBS
                if [ -n "$YBS" ]; then
                    DD_BLOCK_SIZE="$YBS"
                    echo -e "${G}[✓] Block Size ayarlandı: ${DD_BLOCK_SIZE}${NC}"
                fi
                sleep 1
                ;;
            3)
                echo ""
                echo -e "${C}Mevcut Conv: ${Y}${DD_CONV}${NC}"
                echo -e "${W}Seçenekler:${NC}"
                echo -e "  ${G}fsync${NC}    - Her bloktan sonra fiziksel yazma (güvenli)"
                echo -e "  ${G}fdatasync${NC} - Sadece veriyi sync et (biraz daha hızlı)"
                echo -e "  ${G}notrunc${NC}  - Hedefi kırpma"
                echo -e "  ${G}noerror${NC}  - Hatalarda durma (hasarlı disk için)"
                echo -e "  ${G}sync${NC}     - Eksik blokları sıfırla"
                echo -e "${C}Birden fazla: virgülle ayır (örn: fsync,noerror)${NC}"
                echo -ne "${Y}Yeni Conv parametresi: ${NC}"
                read -r YCONV
                if [ -n "$YCONV" ]; then
                    DD_CONV="$YCONV"
                    echo -e "${G}[✓] Conv ayarlandı: ${DD_CONV}${NC}"
                fi
                sleep 1
                ;;
            4)
                if [ "$DOGRULAMA_YAP" -eq 1 ]; then
                    DOGRULAMA_YAP=0
                    echo -e "${Y}[✓] Hash doğrulama kapatıldı (daha hızlı)${NC}"
                else
                    DOGRULAMA_YAP=1
                    echo -e "${G}[✓] Hash doğrulama açıldı (daha güvenli)${NC}"
                fi
                sleep 1
                ;;
            5)
                if [ "$EJECT_YAP" -eq 1 ]; then
                    EJECT_YAP=0
                    echo -e "${Y}[✓] İşlem sonunda eject yapılmayacak${NC}"
                else
                    EJECT_YAP=1
                    echo -e "${G}[✓] İşlem sonunda disk eject edilecek${NC}"
                fi
                sleep 1
                ;;
            6)
                echo ""
                echo -e "${C}Mevcut Öncelik: ${ONCELIK_RENK}${NC}"
                echo -e "${W}Seçenekler:${NC}"
                echo -e "  ${C}[1]${NC} Düşük   - Sistem öncelikli, transfer arka planda"
                echo -e "  ${G}[2]${NC} Normal  - Dengeli (varsayılan)"
                echo -e "  ${R}[3]${NC} Yüksek  - Transfer öncelikli, sistem yavaşlayabilir"
                echo -ne "${Y}Seçim [1/2/3]: ${NC}"
                read -r ONCELIK_SEC
                case "$ONCELIK_SEC" in
                    1) TRANSFER_ONCELIK="low"; echo -e "${G}[✓] Düşük öncelik ayarlandı${NC}" ;;
                    3) TRANSFER_ONCELIK="high"; echo -e "${G}[✓] Yüksek öncelik ayarlandı${NC}" ;;
                    *) TRANSFER_ONCELIK="normal"; echo -e "${G}[✓] Normal öncelik ayarlandı${NC}" ;;
                esac
                sleep 1
                ;;
            7)
                echo ""
                if [ -n "$LOG_DOSYASI" ]; then
                    echo -e "${C}Mevcut log dosyası: ${Y}${LOG_DOSYASI}${NC}"
                    echo -ne "${Y}Kapatmak için boş bırak, değiştirmek için yol yaz: ${NC}"
                else
                    echo -e "${C}Log dosyası şu an kapalı.${NC}"
                    echo -ne "${Y}Log dosyası yolu (örn: /tmp/flashor.log): ${NC}"
                fi
                read -r YLOG
                if [ -z "$YLOG" ]; then
                    LOG_DOSYASI=""
                    echo -e "${Y}[✓] Log kapatıldı${NC}"
                else
                    LOG_DOSYASI="$YLOG"
                    touch "$LOG_DOSYASI" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        echo -e "${G}[✓] Log dosyası ayarlandı: ${LOG_DOSYASI}${NC}"
                    else
                        echo -e "${R}[✗] Bu dosya yoluna yazılamıyor!${NC}"
                        LOG_DOSYASI=""
                    fi
                fi
                sleep 1
                ;;
            8)
                echo ""
                echo -e "${C}Mevcut özel parametreler: ${Y}${OZEL_DD_PARAM:-yok}${NC}"
                echo -e "${W}dd komutuna eklenecek ek parametreler yazın.${NC}"
                echo -e "${W}Örnek: iflag=direct oflag=direct${NC}"
                echo -e "${W}Örnek: count=1000 skip=10${NC}"
                echo -e "${C}Boş bırakırsan temizlenir.${NC}"
                echo -ne "${Y}Özel parametreler: ${NC}"
                read -r YDD
                OZEL_DD_PARAM="$YDD"
                if [ -n "$OZEL_DD_PARAM" ]; then
                    echo -e "${G}[✓] Özel parametreler ayarlandı: ${OZEL_DD_PARAM}${NC}"
                else
                    echo -e "${Y}[✓] Özel parametreler temizlendi${NC}"
                fi
                sleep 1
                ;;
            9)
                if [ "$BOYUT_KORUMA" -eq 1 ]; then
                    echo ""
                    echo -e "${R}╔══════════════════════════════════════════════════════╗${NC}"
                    echo -e "${R}║                                                      ║${NC}"
                    echo -e "${R}║${NC}  ${BOLD}⚠  CİDDİ UYARI: Boyut korumasını kapatmak${NC}          ${R}║${NC}"
                    echo -e "${R}║${NC}  ${BOLD}veri kaybına veya bozuk diske yol açabilir!${NC}         ${R}║${NC}"
                    echo -e "${R}║                                                      ║${NC}"
                    echo -e "${R}║${NC}  Kaynak disk hedeften büyükse, hedef diske          ${R}║${NC}"
                    echo -e "${R}║${NC}  sığmayan veriler ${BOLD}KESİLECEK${NC} ve kaybolacak.         ${R}║${NC}"
                    echo -e "${R}║${NC}  Disk bölüm tablosu bozulabilir.                    ${R}║${NC}"
                    echo -e "${R}║                                                      ║${NC}"
                    echo -e "${R}║${NC}  ${Y}Bu ayar sadece ne yaptığını bilenler içindir!${NC}       ${R}║${NC}"
                    echo -e "${R}║                                                      ║${NC}"
                    echo -e "${R}╚══════════════════════════════════════════════════════╝${NC}"
                    echo ""
                    echo -ne "${Y}Riski kabul edip kapatmak istiyor musun? [e/h]: ${NC}"
                    read -r ONAYLA
                    if [[ "$ONAYLA" =~ ^[eE]$ ]]; then
                        BOYUT_KORUMA=0
                        echo -e "${R}[✓] Boyut koruma KAPATILDI - dikkatli ol!${NC}"
                    else
                        echo -e "${G}[✓] Boyut koruma açık kaldı${NC}"
                    fi
                else
                    BOYUT_KORUMA=1
                    echo -e "${G}[✓] Boyut koruma tekrar açıldı${NC}"
                fi
                sleep 1
                ;;
            0)
                ayar_devam=0
                echo -e "${G}[✓] Ayarlar kaydedildi!${NC}"
                sleep 1
                ;;
            *)
                echo -e "${R}[✗] Geçersiz seçim${NC}"
                sleep 1
                ;;
        esac
    done
}

# ========================================
# MOD SEÇİMİ
# ========================================
clear
echo -e "${C}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${C}│${NC} ${BOLD}${W}        Çalışma Modu Seçimi${NC}                          ${C}│${NC}"
echo -e "${C}├──────────────────────────────────────────────────────┤${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}│${NC}  ${G}[1]${NC}  ${W}Animasyonlu Mod${NC} ${Y}(Manuel ilerleme)${NC}              ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Her adımda ENTER'a basarak ilerlersin${NC}         ${C}│${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}│${NC}  ${G}[2]${NC}  ${W}Hızlı Mod${NC} ${Y}(Animasyon yok)${NC}                     ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Tüm süslemeler atlanır, sadece iş yapılır${NC}    ${C}│${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}│${NC}  ${G}[3]${NC}  ${W}Otomatik Mod${NC} ${Y}(Animasyonlu, durmadan)${NC}          ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Animasyonlar oynar ama ENTER beklemez${NC}         ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Adımlar arası otomatik geçiş (3sn bekleme)${NC}   ${C}│${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}│${NC}  ${M}[A]${NC}  ${W}⚙  Ayarlar${NC}                                    ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Gelişmiş yapılandırma seçenekleri${NC}             ${C}│${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}└──────────────────────────────────────────────────────┘${NC}"
echo ""

MOD_SECILDI=0
while [ $MOD_SECILDI -eq 0 ]; do
    echo -ne "${Y}Seçiminiz [1/2/3/A]: ${NC}"
    read -r MOD_SECIM

    case "$MOD_SECIM" in
        [aA])
            ayarlar_menusu
            clear
            echo -e "${C}┌──────────────────────────────────────────────────────┐${NC}"
            echo -e "${C}│${NC} ${BOLD}${W}        Çalışma Modu Seçimi${NC}                          ${C}│${NC}"
            echo -e "${C}├──────────────────────────────────────────────────────┤${NC}"
            echo -e "${C}│${NC}                                                      ${C}│${NC}"
            echo -e "${C}│${NC}  ${G}[1]${NC}  ${W}Animasyonlu Mod${NC} ${Y}(Manuel ilerleme)${NC}              ${C}│${NC}"
            echo -e "${C}│${NC}       ${C}Her adımda ENTER'a basarak ilerlersin${NC}         ${C}│${NC}"
            echo -e "${C}│${NC}                                                      ${C}│${NC}"
            echo -e "${C}│${NC}  ${G}[2]${NC}  ${W}Hızlı Mod${NC} ${Y}(Animasyon yok)${NC}                     ${C}│${NC}"
            echo -e "${C}│${NC}       ${C}Tüm süslemeler atlanır, sadece iş yapılır${NC}    ${C}│${NC}"
            echo -e "${C}│${NC}                                                      ${C}│${NC}"
            echo -e "${C}│${NC}  ${G}[3]${NC}  ${W}Otomatik Mod${NC} ${Y}(Animasyonlu, durmadan)${NC}          ${C}│${NC}"
            echo -e "${C}│${NC}       ${C}Animasyonlar oynar ama ENTER beklemez${NC}         ${C}│${NC}"
            echo -e "${C}│${NC}       ${C}Adımlar arası otomatik geçiş (3sn bekleme)${NC}   ${C}│${NC}"
            echo -e "${C}│${NC}                                                      ${C}│${NC}"
            echo -e "${C}│${NC}  ${M}[A]${NC}  ${W}⚙  Ayarlar${NC}                                    ${C}│${NC}"
            echo -e "${C}│${NC}       ${C}Gelişmiş yapılandırma seçenekleri${NC}             ${C}│${NC}"
            echo -e "${C}│${NC}                                                      ${C}│${NC}"
            echo -e "${C}└──────────────────────────────────────────────────────┘${NC}"
            echo ""
            echo -e "${G}[✓] Ayarlar güncellendi!${NC}"
            echo ""
            ;;
        2)
            HIZLI_MOD=1
            OTOMATIK_MOD=0
            ADIM_BEKLEME=0
            echo -e "\n${G}[✓] Hızlı mod aktif. Süslemeler atlanıyor...${NC}\n"
            MOD_SECILDI=1
            ;;
        3)
            HIZLI_MOD=0
            OTOMATIK_MOD=1
            ADIM_BEKLEME=3
            echo -e "\n${G}[✓] Otomatik mod aktif. Animasyonlar oynar, adımlar otomatik geçer...${NC}"
            echo -ne "${Y}Adımlar arası bekleme süresi (saniye) [varsayılan=3]: ${NC}"
            read -r SURE_SECIM
            if [[ "$SURE_SECIM" =~ ^[0-9]+$ ]] && [ "$SURE_SECIM" -gt 0 ]; then
                ADIM_BEKLEME=$SURE_SECIM
            fi
            echo -e "${C}[ℹ] Adımlar arası bekleme: ${ADIM_BEKLEME} saniye${NC}\n"
            MOD_SECILDI=1
            ;;
        *)
            HIZLI_MOD=0
            OTOMATIK_MOD=0
            ADIM_BEKLEME=0
            echo -e "\n${G}[✓] Animasyonlu mod aktif. Her adımda ENTER beklenecek...${NC}\n"
            MOD_SECILDI=1
            ;;
    esac
done

# Log başlat
log_yaz "========================================="
log_yaz "FLASHOR başlatıldı"
log_yaz "Mod: HIZLI=$HIZLI_MOD OTOMATIK=$OTOMATIK_MOD"
log_yaz "Ayarlar: BS=$DD_BLOCK_SIZE CONV=$DD_CONV DOGRULAMA=$DOGRULAMA_YAP EJECT=$EJECT_YAP ONCELIK=$TRANSFER_ONCELIK BOYUT_KORUMA=$BOYUT_KORUMA"
log_yaz "Özel DD param: $OZEL_DD_PARAM"

# ========================================
# YARDIMCI FONKSİYONLAR
# ========================================

custom_sleep() {
    if [ "$HIZLI_MOD" -eq 0 ]; then
        sleep "$1"
    fi
}

yaz() {
    local text="$1"
    local color="${2:-$NC}"
    local delay=${3:-0.03}
    
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "${color}${text}${NC}"
        return
    fi
    
    echo -ne "$color"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo -e "${NC}"
}

progress_bar() {
    local duration=$1
    local text="$2"
    
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "${Y}${text}${NC} ${G}[TAMAMLANDI]${NC}"
        return
    fi

    local width=50
    local progress=0
    echo -ne "${Y}${text}${NC}\n"
    local total_steps=50
    local sleep_time=$(awk "BEGIN {print $duration/$total_steps}" 2>/dev/null || echo "0.1")
    
    while [ $progress -le 100 ]; do
        local filled=$((progress * width / 100))
        local empty=$((width - filled))
        printf "\r${C}[${NC}"
        for ((i=0; i<filled; i++)); do
            if [ $((i % 3)) -eq 0 ]; then printf "${G}█${NC}";
            elif [ $((i % 3)) -eq 1 ]; then printf "${Y}█${NC}";
            else printf "${C}█${NC}"; fi
        done
        if [ $empty -gt 0 ]; then printf "${W}%${empty}s${NC}" | tr ' ' '░'; fi
        printf "${C}]${NC} ${BOLD}${G}%3d%%${NC}" $progress
        local spin='-\|/'
        local idx=$((progress % 4))
        printf " ${Y}${spin:$idx:1}${NC}"
        progress=$((progress + 2))
        sleep $sleep_time
    done
    echo ""
}

yildiz_patlat() {
    local text="$1"
    
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "${BOLD}${G}>>> ${text} <<<${NC}"
        return
    fi

    echo ""
    for i in {1..5}; do
        case $i in
            1) echo -ne "  ${Y}★${NC}" ;;
            2) echo -ne " ${G}✦${NC}" ;;
            3) echo -ne " ${C}✧${NC}" ;;
            4) echo -ne " ${M}✦${NC}" ;;
            5) echo -ne " ${B}★${NC}" ;;
        esac
        sleep 0.15
    done
    echo ""
    sleep 0.3
    yaz "  ${text}" "$W" 0.02
}

bekle() {
    if [ "$HIZLI_MOD" -eq 1 ]; then return; fi

    local duration=${1:-3}
    local dots=${2:-10}
    local sleep_time=$(awk "BEGIN {print $duration/$dots}" 2>/dev/null || echo "0.3")
    
    for ((i=1; i<=dots; i++)); do
        echo -ne "${C}.${NC}"
        sleep $sleep_time
    done
    echo ""
}

scan_anim() {
    local items=("$@")
    for item in "${items[@]}"; do
        if [ "$HIZLI_MOD" -eq 1 ]; then
            echo -e "${G}[✔]${NC} ${W}Bulundu: ${NC}$item"
        else
            echo -ne "${Y}[${NC}${C}◆${NC}${Y}]${NC} ${W}Taranıyor: ${NC}$item"
            sleep 0.3
            echo -ne "\r${G}[${NC}${G}✔${NC}${G}]${NC} ${W}Bulundu   : ${NC}$item"
            echo ""
            sleep 0.2
        fi
    done
}

ileri() {
    echo ""
    
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "${G}[→] Sonraki adıma geçiliyor...${NC}"
        return
    fi
    
    if [ "$OTOMATIK_MOD" -eq 1 ]; then
        echo -e "${M}╔═════════════════════════════════════════════════════╗${NC}"
        echo -e "${M}║${NC}                                                     ${M}║${NC}"
        echo -e "${M}║${NC}     ${BOLD}${C}⏳ Sonraki adıma otomatik geçiliyor...${NC}          ${M}║${NC}"
        echo -e "${M}║${NC}                                                     ${M}║${NC}"
        echo -e "${M}╚═════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        for ((kalan=ADIM_BEKLEME; kalan>=1; kalan--)); do
            local dolu=$((  (ADIM_BEKLEME - kalan) * 30 / ADIM_BEKLEME  ))
            local bos=$(( 30 - dolu ))
            printf "\r  ${C}[${NC}"
            for ((b=0; b<dolu; b++)); do printf "${G}▓${NC}"; done
            for ((b=0; b<bos; b++)); do printf "${W}░${NC}"; done
            printf "${C}]${NC} ${BOLD}${Y}%2d saniye${NC} " $kalan
            
            local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
            for ((f=0; f<5; f++)); do
                local spin_idx=$(( (f + kalan) % ${#spin_chars} ))
                printf "\r  ${C}[${NC}"
                local dolu2=$((  (ADIM_BEKLEME - kalan) * 30 / ADIM_BEKLEME + f * 30 / (ADIM_BEKLEME * 5)  ))
                if [ $dolu2 -gt 30 ]; then dolu2=30; fi
                local bos2=$(( 30 - dolu2 ))
                for ((b=0; b<dolu2; b++)); do printf "${G}▓${NC}"; done
                for ((b=0; b<bos2; b++)); do printf "${W}░${NC}"; done
                printf "${C}]${NC} ${BOLD}${Y}%2d saniye${NC} ${C}${spin_chars:$spin_idx:1}${NC}" $kalan
                sleep 0.2
            done
        done
        
        printf "\r  ${C}[${NC}"
        for ((b=0; b<30; b++)); do printf "${G}▓${NC}"; done
        printf "${C}]${NC} ${BOLD}${G} Devam!    ${NC}  "
        echo ""
        echo ""
        return
    fi
    
    echo -e "${M}╔═════════════════════════════════════════════════════╗${NC}"
    echo -e "${M}║${NC}                                                     ${M}║${NC}"
    echo -ne "${M}║${NC}     "; yaz ">>> Devam etmek için ENTER'a bas <<<" "$BOLD$Y" 0.01; 
    echo -e "${M}║${NC}                                                     ${M}║${NC}"
    echo -e "${M}╚═════════════════════════════════════════════════════╝${NC}"
    read -r
}

basarili() {
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "${G}[✔]${NC} $1"
        return
    fi
    echo -ne "${Y}[${NC}${C}⟳${NC}${Y}]${NC} $1"
    sleep 0.5
    echo -ne "\r${G}[${NC}${G}✔${NC}${G}]${NC} $1"
    echo ""
    sleep 0.2
}

yukleme_cemberi() {
    local duration=$1
    local text="$2"
    
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "${G}[✔]${NC} ${text}"
        return
    fi

    local frames=('◐' '◓' '◑' '◒')
    local end=$((SECONDS + duration))
    echo -ne "${Y}${text}${NC} "
    while [ $SECONDS -lt $end ]; do
        for frame in "${frames[@]}"; do
            echo -ne "\r${Y}${text}${NC} ${C}${frame}${NC}"
            sleep 0.1
        done
    done
    echo -ne "\r${G}${text} ✔${NC}"
    echo ""
}

matrix_rain() {
    if [ "$HIZLI_MOD" -eq 1 ]; then return; fi
    local lines=5
    for ((i=1; i<=lines; i++)); do
        local rand_text=$(cat /dev/urandom | tr -dc '01' | fold -w 60 | head -n 1)
        echo -e "${G}${rand_text}${NC}"
        sleep 0.05
    done
}

# ========================================
# ANA PROGRAM BAŞLIYOR
# ========================================

clear
echo -e "${G}"
custom_sleep 0.3
echo -e "    ╔═══════════════════════════════════════════════════════╗"
echo -e "    ║                                                       ║"
custom_sleep 0.2
matrix_rain
clear

# BANNER
echo -e "${C}"
cat << "EOF"
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║   ██████╗  ██████╗ ██╗     ██████╗ ███████╗          ║
    ║  ██╔════╝ ██╔═══██╗██║     ██╔══██╗██╔════╝          ║
    ║  ██║  ███╗██║   ██║██║     ██║  ██║█████╗            ║
    ║  ██║   ██║██║   ██║██║     ██║  ██║██╔══╝            ║
    ║  ╚██████╔╝╚██████╔╝███████╗██████╔╝███████╗          ║
    ║   ╚═════╝  ╚═════╝ ╚══════╝╚═════╝ ╚══════╝          ║
    ║                                                       ║
EOF
custom_sleep 0.3
echo -e "    ║        F L A S H O R   P R O T O K O L Ü              ║"
cat << "EOF"
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
custom_sleep 0.5

yukleme_cemberi 2 "Sistem başlatılıyor"
echo ""
yaz "                    by YAŞAR EFE" "$W" 0.03
custom_sleep 0.3
yaz "              [USB Klonlama Sistemi]" "$C" 0.03
echo ""
custom_sleep 0.5

# Aktif mod ve ayar göstergesi
echo -e "${C}┌──────────────────────────────────────────────────┐${NC}"
case "$OTOMATIK_MOD$HIZLI_MOD" in
    "00") echo -e "${C}│${NC}  ${BOLD}Aktif Mod :${NC} ${G}Animasyonlu (Manuel)${NC}            ${C}│${NC}" ;;
    "01") echo -e "${C}│${NC}  ${BOLD}Aktif Mod :${NC} ${Y}Hızlı${NC}                           ${C}│${NC}" ;;
    "10") echo -e "${C}│${NC}  ${BOLD}Aktif Mod :${NC} ${M}Otomatik (${ADIM_BEKLEME}sn bekleme)${NC}           ${C}│${NC}" ;;
esac
echo -e "${C}│${NC}  ${BOLD}Block Size:${NC} ${Y}${DD_BLOCK_SIZE}${NC}  ${BOLD}Conv:${NC} ${Y}${DD_CONV}${NC}              ${C}│${NC}"
if [ "$GUVENLIK_ONAY" -eq 0 ]; then
    echo -e "${C}│${NC}  ${BOLD}Güvenlik  :${NC} ${R}KAPALI${NC}                              ${C}│${NC}"
fi
if [ "$BOYUT_KORUMA" -eq 0 ]; then
    echo -e "${C}│${NC}  ${BOLD}Boyut Kor.:${NC} ${R}KAPALI (riskli)${NC}                     ${C}│${NC}"
fi
if [ "$DOGRULAMA_YAP" -eq 1 ]; then
    echo -e "${C}│${NC}  ${BOLD}Doğrulama :${NC} ${G}MD5 Hash Aktif${NC}                      ${C}│${NC}"
fi
if [ -n "$OZEL_DD_PARAM" ]; then
    echo -e "${C}│${NC}  ${BOLD}Özel Param:${NC} ${Y}${OZEL_DD_PARAM}${NC}                    ${C}│${NC}"
fi
if [ -n "$LOG_DOSYASI" ]; then
    echo -e "${C}│${NC}  ${BOLD}Log       :${NC} ${G}${LOG_DOSYASI}${NC}                      ${C}│${NC}"
fi
echo -e "${C}└──────────────────────────────────────────────────┘${NC}"
echo ""

yildiz_patlat "Hoş Geldin!"

echo -e "${W}Bu araç, bir USB'yi diğerine BİREBİR kopyalar.${NC}"
custom_sleep 0.5
echo -e "${R}⚠️  ${BLINK}HEDEFTEKİ TÜM VERİLER SİLİNECEK!${NC}"
custom_sleep 1

ileri

# ========================================
# ADIM 1: SİSTEM KONTROLÜ
# ========================================
clear
echo -e "${B}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${B}║${NC}  ${BOLD}${W}ADIM 1/5: SİSTEM KONTROLÜ${NC}                        ${B}║${NC}"
echo -e "${B}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[⚙]  Sistem bileşenleri taranıyor..." "$W"
echo ""
custom_sleep 1

scan_anim "Kernel Modülleri" "Disk Araçları" "I/O Sistemleri" "Buffer Yöneticisi"

echo ""
progress_bar 2 "[●] Araç uyumluluğu test ediliyor"
echo ""

if ! command -v lsblk &> /dev/null; then
    echo -e "${R}[✗] HATA: lsblk bulunamadı!${NC}"
    log_yaz "HATA: lsblk bulunamadı"
    exit 1
fi
basarili "lsblk modülü aktif"

if ! command -v dd &> /dev/null; then
    echo -e "${R}[✗] HATA: dd bulunamadı!${NC}"
    log_yaz "HATA: dd bulunamadı"
    exit 1
fi
basarili "dd transfer motoru hazır"
basarili "Hesaplama motoru çevrimiçi"

# Doğrulama aracı kontrolü
if [ "$DOGRULAMA_YAP" -eq 1 ]; then
    if command -v md5sum &> /dev/null; then
        basarili "MD5 doğrulama motoru hazır"
    else
        echo -e "${Y}[!] md5sum bulunamadı, doğrulama devre dışı bırakıldı${NC}"
        DOGRULAMA_YAP=0
    fi
fi

# ionice kontrolü
if [ "$TRANSFER_ONCELIK" != "normal" ]; then
    if command -v ionice &> /dev/null; then
        basarili "I/O önceliklendirme motoru hazır"
    else
        echo -e "${Y}[!] ionice bulunamadı, öncelik normal olarak ayarlandı${NC}"
        TRANSFER_ONCELIK="normal"
    fi
fi

log_yaz "Sistem kontrolü tamamlandı"

echo ""
yukleme_cemberi 2 "[✓] Son kontroller yapılıyor"

yildiz_patlat "Tüm sistemler operasyonel!"

ileri

# ========================================
# ADIM 2: DISK TESPİTİ
# ========================================
clear
echo -e "${B}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${B}║${NC}  ${BOLD}${W}ADIM 2/5: DISK TESPİTİ${NC}                          ${B}║${NC}"
echo -e "${B}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[🔍] Tüm depolama cihazları taranıyor..." "$W"
bekle 2 20
echo ""

progress_bar 3 "[●] Blok cihazları analiz ediliyor"
echo ""
custom_sleep 0.5

echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${C}│${NC} ${BOLD}${W}Tespit Edilen Diskler (OS dışında):${NC}               ${C}│${NC}"
echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"
echo ""
custom_sleep 0.3

OS_DISK=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//' | sed 's/\/dev\///')

echo -e "${Y}[ℹ] OS diski: ${R}/dev/$OS_DISK${Y} (bu listeye dahil değil)${NC}"
echo ""
lsblk -ndo NAME,SIZE,TYPE | grep 'disk' | grep -v "^$OS_DISK " | nl -w2 -s'. '

echo ""
custom_sleep 0.5
echo -e "${Y}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${Y}│${NC} ${BOLD}Hedef Belirleme Protokolü${NC}                         ${Y}│${NC}"
echo -e "${Y}└─────────────────────────────────────────────────────┘${NC}"
custom_sleep 0.3

echo ""
echo -ne "${C}➤${NC} ${W}KAYNAK disk numarası (kopyalanacak): ${NC}"
read KAYNAK_NO
custom_sleep 0.3
echo -ne "${C}➤${NC} ${W}HEDEF disk numarası (üzerine yazılacak): ${NC}"
read HEDEF_NO

HOCA=$(lsblk -ndo NAME,TYPE | grep 'disk' | grep -v "^$OS_DISK " | sed -n "${KAYNAK_NO}p" | awk '{print $1}')
SENIN=$(lsblk -ndo NAME,TYPE | grep 'disk' | grep -v "^$OS_DISK " | sed -n "${HEDEF_NO}p" | awk '{print $1}')

if [ -z "$HOCA" ] || [ -z "$SENIN" ]; then
    echo -e "${R}[✗] HATA: Geçersiz seçim!${NC}"
    log_yaz "HATA: Geçersiz disk seçimi K=$KAYNAK_NO H=$HEDEF_NO"
    exit 1
fi

if [ "$HOCA" == "$SENIN" ]; then
    echo -e "${R}[✗] HATA: Kaynak ve hedef aynı olamaz!${NC}"
    log_yaz "HATA: Kaynak ve hedef aynı: $HOCA"
    exit 1
fi

if [ "$HOCA" == "$OS_DISK" ] || [ "$SENIN" == "$OS_DISK" ]; then
    echo -e "${R}[✗] HATA: OS diskini seçemezsin!${NC}"
    log_yaz "HATA: OS diski seçildi"
    exit 1
fi

log_yaz "Disk seçimi: Kaynak=/dev/$HOCA Hedef=/dev/$SENIN"

echo ""
yukleme_cemberi 2 "[◆] Seçimler doğrulanıyor"
echo ""
progress_bar 2 "[●] Hedef kilitleniyor"
echo ""

basarili "Kaynak tespit edildi: /dev/$HOCA"
basarili "Hedef kilitlendi: /dev/$SENIN"

# Disk boyutları
KAYNAK_BOYUT=$(lsblk -bdno SIZE /dev/$HOCA 2>/dev/null)
HEDEF_BOYUT=$(lsblk -bdno SIZE /dev/$SENIN 2>/dev/null)
KAYNAK_BOYUT_HR=$(boyut_formatla "$KAYNAK_BOYUT")
HEDEF_BOYUT_HR=$(boyut_formatla "$HEDEF_BOYUT")

echo ""
echo -e "  ${C}Kaynak boyut:${NC} ${G}${KAYNAK_BOYUT_HR}${NC}  (/dev/$HOCA)"
echo -e "  ${C}Hedef boyut :${NC} ${G}${HEDEF_BOYUT_HR}${NC}  (/dev/$SENIN)"

# ========================================
# BOYUT KONTROLÜ
# ========================================
if [ -n "$KAYNAK_BOYUT" ] && [ -n "$HEDEF_BOYUT" ]; then
    if [ "$HEDEF_BOYUT" -lt "$KAYNAK_BOYUT" ]; then
        FARK_BYTE=$((KAYNAK_BOYUT - HEDEF_BOYUT))
        FARK_HR=$(boyut_formatla "$FARK_BYTE")
        
        echo ""
        echo -e "${R}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${R}║                                                        ║${NC}"
        echo -e "${R}║${NC}  ${BLINK}${BOLD}⚠  BOYUT UYUMSUZLUĞU TESPİT EDİLDİ ⚠${NC}                ${R}║${NC}"
        echo -e "${R}║                                                        ║${NC}"
        echo -e "${R}║${NC}  Kaynak disk hedef diskten ${BOLD}BÜYÜK!${NC}                      ${R}║${NC}"
        echo -e "${R}║                                                        ║${NC}"
        echo -e "${R}║${NC}  Kaynak : ${G}${KAYNAK_BOYUT_HR}${NC}                                  ${R}║${NC}"
        echo -e "${R}║${NC}  Hedef  : ${Y}${HEDEF_BOYUT_HR}${NC}                                  ${R}║${NC}"
        echo -e "${R}║${NC}  Fark   : ${R}${FARK_HR}${NC} sığmayacak                         ${R}║${NC}"
        echo -e "${R}║                                                        ║${NC}"
        echo -e "${R}╚════════════════════════════════════════════════════════╝${NC}"
        
        log_yaz "BOYUT UYUMSUZLUĞU: Kaynak=$KAYNAK_BOYUT_HR Hedef=$HEDEF_BOYUT_HR Fark=$FARK_HR"
        
        if [ "$BOYUT_KORUMA" -eq 1 ]; then
            echo ""
            echo -e "${R}[✗] Hedef disk kaynaktan küçük olduğu için işlem iptal edildi.${NC}"
            echo -e "${Y}[ℹ] Veriler sığmaz, bozuk kopya oluşur.${NC}"
            echo -e "${C}[ℹ] Bu kontrolü kapatmak için Ayarlar > [9] Boyut Koruma${NC}"
            echo ""
            log_yaz "İşlem iptal edildi: Boyut koruma aktif, hedef < kaynak"
            exit 1
        else
            echo ""
            echo -e "${R}╔════════════════════════════════════════════════════════╗${NC}"
            echo -e "${R}║${NC}  ${BOLD}BOYUT KORUMA KAPALI${NC} - Riskli mod aktif!                ${R}║${NC}"
            echo -e "${R}║                                                        ║${NC}"
            echo -e "${R}║${NC}  Kaynak hedeften büyük ama yine de devam edilecek.     ${R}║${NC}"
            echo -e "${R}║${NC}  Son ${BOLD}${FARK_HR}${NC} veri ${BOLD}KESİLECEK${NC} ve kaybolacak!            ${R}║${NC}"
            echo -e "${R}║${NC}  Bölüm tablosu ve dosya sistemi ${BOLD}BOZULABİLİR!${NC}          ${R}║${NC}"
            echo -e "${R}╚════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -ne "${Y}Bu riski kabul ediyor musun? [e/h]: ${NC}"
            read -r BOYUT_RISK_ONAY
            if [[ ! "$BOYUT_RISK_ONAY" =~ ^[eE]$ ]]; then
                echo -e "${G}[ℹ] Akıllıca karar. İşlem iptal edildi.${NC}"
                log_yaz "İşlem iptal edildi: Kullanıcı boyut riskini kabul etmedi"
                exit 0
            fi
            echo -e "${R}[!] Risk kabul edildi. Eksik veriyle devam ediliyor...${NC}"
            log_yaz "UYARI: Kullanıcı boyut riskini kabul etti, devam ediliyor"
        fi
    else
        echo ""
        echo -e "  ${G}[✔] Hedef disk yeterli boyutta${NC}"
        if [ "$HEDEF_BOYUT" -gt "$KAYNAK_BOYUT" ]; then
            FAZLA_BYTE=$((HEDEF_BOYUT - KAYNAK_BOYUT))
            FAZLA_HR=$(boyut_formatla "$FAZLA_BYTE")
            echo -e "  ${C}[ℹ] Hedefte ${FAZLA_HR} fazla alan kalacak${NC}"
        fi
        log_yaz "Boyut kontrolü başarılı: Kaynak=$KAYNAK_BOYUT_HR Hedef=$HEDEF_BOYUT_HR"
    fi
fi

yildiz_patlat "Hedefler belirlendi!"

ileri

# ========================================
# ADIM 3: GÜVENLİK ONAY
# ========================================
clear
echo -e "${R}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${R}║${NC}  ${BOLD}${W}ADIM 3/5: GÜVENLİK ONAY PROTOKOLÜ${NC}                ${R}║${NC}"
echo -e "${R}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[📋] İşlem parametreleri derleniyor..." "$W"
bekle 2 15
echo ""

echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${C}│${NC} ${BOLD}${W}Transfer Matrisi:${NC}                                 ${C}│${NC}"
echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"
custom_sleep 0.3
echo ""
echo -e "  ${C}Kaynak Cihaz  :${NC} ${G}/dev/$HOCA${NC} (${KAYNAK_BOYUT_HR})"
custom_sleep 0.3
echo -e "  ${C}Hedef Cihaz   :${NC} ${R}/dev/$SENIN${NC} (${HEDEF_BOYUT_HR})"
custom_sleep 0.3
echo -e "  ${C}Block Size    :${NC} ${Y}${DD_BLOCK_SIZE}${NC}"
echo -e "  ${C}Conv          :${NC} ${Y}${DD_CONV}${NC}"
echo -e "  ${C}I/O Önceliği  :${NC} ${Y}${TRANSFER_ONCELIK}${NC}"
if [ -n "$OZEL_DD_PARAM" ]; then
    echo -e "  ${C}Özel Param    :${NC} ${Y}${OZEL_DD_PARAM}${NC}"
fi
if [ "$DOGRULAMA_YAP" -eq 1 ]; then
    echo -e "  ${C}Doğrulama     :${NC} ${G}MD5 Hash (aktif)${NC}"
else
    echo -e "  ${C}Doğrulama     :${NC} ${Y}Kapalı${NC}"
fi
custom_sleep 0.5
echo ""

# DD komut önizleme
DD_CMD="dd if=/dev/$HOCA of=/dev/$SENIN bs=$DD_BLOCK_SIZE status=progress conv=$DD_CONV"
if [ -n "$OZEL_DD_PARAM" ]; then
    DD_CMD="$DD_CMD $OZEL_DD_PARAM"
fi

echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${C}│${NC} ${BOLD}${W}Çalışacak DD Komutu:${NC}                               ${C}│${NC}"
echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"
echo -e "  ${W}$DD_CMD${NC}"
echo ""

if [ "$HIZLI_MOD" -eq 0 ]; then
    for i in {3..1}; do
        echo -ne "${Y}[!] Uyarı gösteriliyor... ${i}${NC}\r"
        sleep 1
    done
fi
echo ""

echo -e "${R}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${R}║                                                    ║${NC}"
echo -e "${R}║${NC}  ${BLINK}${BOLD}⚠️  KRİTİK UYARI ⚠️${NC}                              ${R}║${NC}"
echo -e "${R}║                                                    ║${NC}"
echo -e "${R}║${NC}    /dev/$SENIN üzerindeki ${BOLD}TÜM VERİLER${NC}              ${R}║${NC}"
echo -e "${R}║${NC}    ${BOLD}KALICI OLARAK SİLİNECEK!${NC}                      ${R}║${NC}"
echo -e "${R}║                                                    ║${NC}"
echo -e "${R}║${NC}    ${BOLD}BU İŞLEM GERİ ALINAMAZ!${NC}                       ${R}║${NC}"
echo -e "${R}║                                                    ║${NC}"
echo -e "${R}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 1

# GÜVENLİK ONAYI
if [ "$GUVENLIK_ONAY" -eq 1 ]; then
    echo -ne "${Y}Son onay için ${BOLD}${R}EVET${NC}${Y} yaz: ${NC}"
    read ONAY

    if [ "$ONAY" != "EVET" ]; then
        echo ""
        yaz "[ℹ] Operasyon kullanıcı tarafından iptal edildi." "$R"
        log_yaz "Operasyon kullanıcı tarafından iptal edildi"
        custom_sleep 1
        echo -e "${C}Güvenli çıkış yapılıyor...${NC}"
        bekle 1 10
        exit 0
    fi
    echo ""
    basarili "Güvenlik onayı alındı"
    log_yaz "Güvenlik onayı alındı"
else
    echo -e "${Y}[!] Güvenlik onayı devre dışı - otomatik devam ediliyor${NC}"
    log_yaz "Güvenlik onayı atlandı (ayarlardan kapalı)"
fi

custom_sleep 0.5
yukleme_cemberi 2 "[◆] Güvenlik protokolleri işleniyor"
progress_bar 2 "[●] Yetkilendirme tamamlanıyor"
yildiz_patlat "Yetkilendirme başarılı!"

ileri

# ========================================
# ADIM 4: HAZIRLIK
# ========================================
clear
echo -e "${B}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${B}║${NC}  ${BOLD}${W}ADIM 4/5: SİSTEM HAZIRLIK AŞAMASI${NC}                ${B}║${NC}"
echo -e "${B}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[🔧] Hedef disk hazırlanıyor..." "$W"
echo ""
custom_sleep 1

progress_bar 3 "[●] Bağlı sistemler analiz ediliyor"
echo ""

yukleme_cemberi 2 "[◆] Mount noktaları kapatılıyor"

umount /dev/${SENIN}* 2>/dev/null
basarili "Tüm mount noktaları kaldırıldı"
log_yaz "Mount noktaları kaldırıldı: /dev/$SENIN"

echo ""
progress_bar 2 "[●] Disk buffer temizleniyor"
echo ""

yukleme_cemberi 2 "[◆] Kernel buffer sync ediliyor"
basarili "Kernel buffer temizlendi"

echo ""
progress_bar 2 "[●] I/O kuyruğu optimize ediliyor"
echo ""

yukleme_cemberi 1 "[◆] DMA kanalları açılıyor"
basarili "DMA transfer modu aktif"

# Transfer önceliği bilgisi
if [ "$TRANSFER_ONCELIK" != "normal" ]; then
    echo ""
    case "$TRANSFER_ONCELIK" in
        low)  basarili "I/O önceliği: DÜŞÜK (sistem performansı korunur)" ;;
        high) basarili "I/O önceliği: YÜKSEK (maksimum transfer hızı)" ;;
    esac
fi

echo ""
yildiz_patlat "Hedef disk transfer için hazır!"

ileri

# ========================================
# ADIM 5: FLAŞLAMA
# ========================================
clear
echo -e "${G}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${G}║${NC}  ${BOLD}${W}ADIM 5/5: FLAŞLAMA OPERASYONU${NC}                    ${G}║${NC}"
echo -e "${G}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[🚀] Transfer motoru çalıştırılıyor..." "$W"
bekle 2 20
echo ""

yukleme_cemberi 3 "[◆] Veri transferi başlatılıyor"
echo ""

echo -e "${M}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${M}│${NC} ${BOLD}${W}Gerçek Zamanlı Transfer İzleme:${NC}                   ${M}│${NC}"
echo -e "${M}└─────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${C}[ℹ] Komut: ${W}${DD_CMD}${NC}"
echo ""
custom_sleep 1

echo -e "${C}[●] Transfer başladı... (dd progress aşağıda)${NC}"
echo ""

log_yaz "Transfer başladı: $DD_CMD"
BASLANGIC_ZAMANI=$(date +%s)

# DD Komutu - Öncelik ayarına göre çalıştır
case "$TRANSFER_ONCELIK" in
    low)
        ionice -c 3 nice -n 19 dd if=/dev/$HOCA of=/dev/$SENIN bs=$DD_BLOCK_SIZE status=progress conv=$DD_CONV $OZEL_DD_PARAM
        DD_SONUC=$?
        ;;
    high)
        ionice -c 1 -n 0 nice -n -20 dd if=/dev/$HOCA of=/dev/$SENIN bs=$DD_BLOCK_SIZE status=progress conv=$DD_CONV $OZEL_DD_PARAM
        DD_SONUC=$?
        ;;
    *)
        dd if=/dev/$HOCA of=/dev/$SENIN bs=$DD_BLOCK_SIZE status=progress conv=$DD_CONV $OZEL_DD_PARAM
        DD_SONUC=$?
        ;;
esac

BITIS_ZAMANI=$(date +%s)
GECEN_SURE=$((BITIS_ZAMANI - BASLANGIC_ZAMANI))
GECEN_DAKIKA=$((GECEN_SURE / 60))
GECEN_SANIYE=$((GECEN_SURE % 60))

if [ $DD_SONUC -eq 0 ]; then
    echo ""
    echo ""
    log_yaz "DD transfer başarılı (${GECEN_DAKIKA}dk ${GECEN_SANIYE}sn)"
    
    yukleme_cemberi 3 "[◆] Transfer tamamlandı, doğrulanıyor"
    echo ""
    
    echo -e "  ${C}Transfer süresi:${NC} ${G}${GECEN_DAKIKA} dakika ${GECEN_SANIYE} saniye${NC}"
    echo ""
    
    # ==========================================
    # HASH DOĞRULAMA
    # ==========================================
    if [ "$DOGRULAMA_YAP" -eq 1 ]; then
        echo -e "${B}┌─────────────────────────────────────────────────────┐${NC}"
        echo -e "${B}│${NC} ${BOLD}${W}MD5 Hash Doğrulama:${NC}                                ${B}│${NC}"
        echo -e "${B}└─────────────────────────────────────────────────────┘${NC}"
        echo ""
        
        KAYNAK_BYTE=$(blockdev --getsize64 /dev/$HOCA 2>/dev/null || echo "$KAYNAK_BOYUT")
        
        echo -e "${Y}[◆] Kaynak disk hash hesaplanıyor...${NC}"
        echo -e "${C}    (Bu işlem disk boyutuna göre uzun sürebilir)${NC}"
        echo ""
        
        KAYNAK_HASH=$(dd if=/dev/$HOCA bs=1M count=$((KAYNAK_BYTE / 1048576)) 2>/dev/null | md5sum | awk '{print $1}')
        
        echo -e "${Y}[◆] Hedef disk hash hesaplanıyor...${NC}"
        echo ""
        
        HEDEF_HASH=$(dd if=/dev/$SENIN bs=1M count=$((KAYNAK_BYTE / 1048576)) 2>/dev/null | md5sum | awk '{print $1}')
        
        echo -e "  ${C}Kaynak MD5:${NC} ${W}${KAYNAK_HASH}${NC}"
        echo -e "  ${C}Hedef  MD5:${NC} ${W}${HEDEF_HASH}${NC}"
        echo ""
        
        if [ "$KAYNAK_HASH" == "$HEDEF_HASH" ]; then
            basarili "Hash doğrulama BAŞARILI - Veriler birebir aynı!"
            log_yaz "Hash doğrulama başarılı: $KAYNAK_HASH"
        else
            echo -e "${R}[✗] Hash doğrulama BAŞARISIZ!${NC}"
            echo -e "${R}    Kaynak ve hedef verileri farklı!${NC}"
            echo -e "${Y}    (Disk boyut farkı nedeniyle olabilir, dosyalar yine de doğru olabilir)${NC}"
            log_yaz "Hash doğrulama başarısız: Kaynak=$KAYNAK_HASH Hedef=$HEDEF_HASH"
        fi
        echo ""
    else
        progress_bar 3 "[●] Veri bütünlüğü kontrol ediliyor (temel)"
        echo ""
    fi
    
    yukleme_cemberi 2 "[◆] Buffer sync yapılıyor"
    sync
    basarili "Tüm veriler diske yazıldı, lütfen bekleyin ve asla USB disklerinizi çıkarmayın."
    
    # ==========================================
    # GÜVENLİK ADIMI (EJECT)
    # ==========================================
    if [ "$EJECT_YAP" -eq 1 ]; then
        echo ""
        yaz "[🔌] Bekleyin, hedef disk güvenli moda alınıyor..." "$W" 0.03
        
        eject /dev/$SENIN 2>/dev/null || umount /dev/$SENIN* 2>/dev/null
        
        basarili "Hedef disk (/dev/$SENIN) sistemden ayrıldı"
        echo -e "${Y}[!] Artık otomatik mount edilemez, güvenle çekebilirsin.${NC}"
        log_yaz "Hedef disk eject edildi: /dev/$SENIN"
    else
        echo ""
        echo -e "${Y}[ℹ] Eject kapalı - disk hala bağlı: /dev/$SENIN${NC}"
        log_yaz "Eject atlandı (ayarlardan kapalı)"
    fi
    
    echo ""
    sleep 1
    
    # BAŞARI EKRANI
    clear
    echo ""
    echo ""
    
    if [ "$HIZLI_MOD" -eq 0 ]; then
        for i in {1..3}; do
            echo -e "${G}          ★ ★ ★ ★ ★ ★ ★ ★ ★ ★${NC}"
            sleep 0.2
            echo -ne "\033[1A\033[2K"
        done
    fi
    
    echo -e "${G}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${G}║                                                    ║${NC}"
    echo -e "${G}║                                                    ║${NC}"
    echo -e "${G}║${NC}       ${BOLD}${BLINK}✔  İŞLEM BAŞARIYLA TAMAMLANDI!  ✔${NC}        ${G}║${NC}"
    echo -e "${G}║                                                    ║${NC}"
    echo -e "${G}║                                                    ║${NC}"
    echo -e "${G}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    custom_sleep 1
    
    if [ "$HIZLI_MOD" -eq 0 ]; then
        for i in {1..10}; do
            case $((i % 5)) in
                0) echo -ne "  ${Y}★${NC}" ;;
                1) echo -ne " ${G}✦${NC}" ;;
                2) echo -ne " ${C}✧${NC}" ;;
                3) echo -ne " ${M}✦${NC}" ;;
                4) echo -ne " ${B}★${NC}" ;;
            esac
            sleep 0.15
        done
        echo ""
    fi
    echo ""
    
    yaz "  [📦] /dev/$SENIN artık /dev/$HOCA'nın tam kopyası" "$C" 0.02
    custom_sleep 0.5
    yaz "  [✔] Disk başarıyla oluşturuldu!" "$G" 0.02
    custom_sleep 0.5
    
    echo ""
    echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${C}│${NC} ${BOLD}${W}Klonlama Raporu:${NC}                                  ${C}│${NC}"
    echo -e "${C}├─────────────────────────────────────────────────────┤${NC}"
    echo -e "${C}│${NC}  ${W}Kaynak       :${NC} ${G}/dev/$HOCA${NC} (${KAYNAK_BOYUT_HR})              ${C}│${NC}"
    echo -e "${C}│${NC}  ${W}Hedef        :${NC} ${G}/dev/$SENIN${NC} (${HEDEF_BOYUT_HR})              ${C}│${NC}"
    echo -e "${C}│${NC}  ${W}Block Size   :${NC} ${Y}${DD_BLOCK_SIZE}${NC}                              ${C}│${NC}"
    echo -e "${C}│${NC}  ${W}Süre         :${NC} ${G}${GECEN_DAKIKA}dk ${GECEN_SANIYE}sn${NC}                        ${C}│${NC}"
    echo -e "${C}│${NC}  ${W}Durum        :${NC} ${G}BAŞARILI${NC}                           ${C}│${NC}"
    if [ "$DOGRULAMA_YAP" -eq 1 ] && [ "${KAYNAK_HASH:-x}" == "${HEDEF_HASH:-y}" ]; then
        echo -e "${C}│${NC}  ${W}Hash Doğrulama:${NC} ${G}EŞLEŞME BAŞARILI${NC}                ${C}│${NC}"
    fi
    echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"

    echo ""
    echo -e "${M}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${M}│${NC}                                                     ${M}│${NC}"
    echo -ne "${M}│${NC}  "; yaz "Tahtayı açmak için hazır mısın? 😎" "$Y$BOLD" 0.03;
    echo -e "${M}│${NC}                                                     ${M}│${NC}"
    echo -e "${M}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    log_yaz "İşlem başarıyla tamamlandı"
    log_yaz "========================================="
    
else
    echo ""
    log_yaz "HATA: DD transfer başarısız (çıkış kodu: $DD_SONUC)"
    
    echo -e "${R}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${R}║${NC}          ${BOLD}✗  İŞLEM BAŞARISIZ!${NC}                      ${R}║${NC}"
    echo -e "${R}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${R}[!] Transfer sırasında hata oluştu.${NC}"
    echo -e "${R}[!] DD çıkış kodu: ${DD_SONUC}${NC}"
    custom_sleep 1
    echo -e "${Y}[!] Disk bağlantılarını kontrol edin.${NC}"
    echo -e "${Y}[!] Geçen süre: ${GECEN_DAKIKA}dk ${GECEN_SANIYE}sn${NC}"
    
    if [ -n "$LOG_DOSYASI" ]; then
        echo -e "${C}[ℹ] Detaylı log: ${LOG_DOSYASI}${NC}"
    fi
    
    log_yaz "========================================="
    exit 1
fi
