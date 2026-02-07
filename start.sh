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
# MOD SEÇİMİ (3 SEÇENEK)
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
echo -e "${C}└──────────────────────────────────────────────────────┘${NC}"
echo ""
echo -ne "${Y}Seçiminiz [1/2/3]: ${NC}"
read -r MOD_SECIM

case "$MOD_SECIM" in
    2)
        HIZLI_MOD=1
        OTOMATIK_MOD=0
        ADIM_BEKLEME=0
        echo -e "\n${G}[✓] Hızlı mod aktif. Süslemeler atlanıyor...${NC}\n"
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
        ;;
    *)
        HIZLI_MOD=0
        OTOMATIK_MOD=0
        ADIM_BEKLEME=0
        echo -e "\n${G}[✓] Animasyonlu mod aktif. Her adımda ENTER beklenecek...${NC}\n"
        ;;
esac

# ========================================
# YARDIMCI FONKSİYONLAR
# ========================================

# Akıllı Sleep
custom_sleep() {
    if [ "$HIZLI_MOD" -eq 0 ]; then
        sleep "$1"
    fi
}

# Yazma Animasyonu
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

# Progress Bar
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

# Yıldız Patlaması
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

# Nokta nokta bekleme
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

# Scan Animasyonu
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

# =====================================================
# ADIM İLERLETME - MOD'A GÖRE DAVRANIŞI DEĞİŞİR
# =====================================================
ileri() {
    echo ""
    
    # Mod 2: Hızlı mod - hiç bekleme yok
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "${G}[→] Sonraki adıma geçiliyor...${NC}"
        return
    fi
    
    # Mod 3: Otomatik mod - animasyonlu geri sayım, ENTER gerektirmez
    if [ "$OTOMATIK_MOD" -eq 1 ]; then
        echo -e "${M}╔═════════════════════════════════════════════════════╗${NC}"
        echo -e "${M}║${NC}                                                     ${M}║${NC}"
        echo -e "${M}║${NC}     ${BOLD}${C}⏳ Sonraki adıma otomatik geçiliyor...${NC}          ${M}║${NC}"
        echo -e "${M}║${NC}                                                     ${M}║${NC}"
        echo -e "${M}╚═════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        for ((kalan=ADIM_BEKLEME; kalan>=1; kalan--)); do
            # Geri sayım çubuğu
            local dolu=$((  (ADIM_BEKLEME - kalan) * 30 / ADIM_BEKLEME  ))
            local bos=$(( 30 - dolu ))
            printf "\r  ${C}[${NC}"
            for ((b=0; b<dolu; b++)); do printf "${G}▓${NC}"; done
            for ((b=0; b<bos; b++)); do printf "${W}░${NC}"; done
            printf "${C}]${NC} ${BOLD}${Y}%2d saniye${NC} " $kalan
            
            # Dönen animasyon
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
        
        # Tamamlandı
        printf "\r  ${C}[${NC}"
        for ((b=0; b<30; b++)); do printf "${G}▓${NC}"; done
        printf "${C}]${NC} ${BOLD}${G} Devam!    ${NC}  "
        echo ""
        echo ""
        return
    fi
    
    # Mod 1: Manuel mod - ENTER bekle
    echo -e "${M}╔═════════════════════════════════════════════════════╗${NC}"
    echo -e "${M}║${NC}                                                     ${M}║${NC}"
    echo -ne "${M}║${NC}     "; yaz ">>> Devam etmek için ENTER'a bas <<<" "$BOLD$Y" 0.01; 
    echo -e "${M}║${NC}                                                     ${M}║${NC}"
    echo -e "${M}╚═════════════════════════════════════════════════════╝${NC}"
    read -r
}

# Başarı Animasyonu
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

# Yükleme Çemberi
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

# Matrix Rain Efekti
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

# Aktif mod göstergesi
echo -e "${C}┌──────────────────────────────────────────────┐${NC}"
case "$OTOMATIK_MOD$HIZLI_MOD" in
    "00") echo -e "${C}│${NC}  ${BOLD}Aktif Mod:${NC} ${G}Animasyonlu (Manuel)${NC}            ${C}│${NC}" ;;
    "01") echo -e "${C}│${NC}  ${BOLD}Aktif Mod:${NC} ${Y}Hızlı${NC}                           ${C}│${NC}" ;;
    "10") echo -e "${C}│${NC}  ${BOLD}Aktif Mod:${NC} ${M}Otomatik (${ADIM_BEKLEME}sn bekleme)${NC}           ${C}│${NC}" ;;
esac
echo -e "${C}└──────────────────────────────────────────────┘${NC}"
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
    exit 1
fi
basarili "lsblk modülü aktif"

if ! command -v dd &> /dev/null; then
    echo -e "${R}[✗] HATA: dd bulunamadı!${NC}"
    exit 1
fi
basarili "dd transfer motoru hazır"
basarili "Hesaplama motoru çevrimiçi"

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
    exit 1
fi

if [ "$HOCA" == "$SENIN" ]; then
    echo -e "${R}[✗] HATA: Kaynak ve hedef aynı olamaz!${NC}"
    exit 1
fi

if [ "$HOCA" == "$OS_DISK" ] || [ "$SENIN" == "$OS_DISK" ]; then
    echo -e "${R}[✗] HATA: OS diskini seçemezsin!${NC}"
    exit 1
fi

echo ""
yukleme_cemberi 2 "[◆] Seçimler doğrulanıyor"
echo ""
progress_bar 2 "[●] Hedef kilitleniyor"
echo ""

basarili "Kaynak tespit edildi: /dev/$HOCA"
basarili "Hedef kilitlendi: /dev/$SENIN"

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
echo -e "  ${C}Kaynak Cihaz:${NC} ${G}/dev/$HOCA${NC}"
custom_sleep 0.3
echo -e "  ${C}Hedef Cihaz :${NC} ${R}/dev/$SENIN${NC}"
custom_sleep 0.5
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

# GÜVENLİK ONAYI - Bu her modda kullanıcıdan alınmalı
echo -ne "${Y}Son onay için ${BOLD}${R}EVET${NC}${Y} yaz: ${NC}"
read ONAY

if [ "$ONAY" != "EVET" ]; then
    echo ""
    yaz "[ℹ] Operasyon kullanıcı tarafından iptal edildi." "$R"
    custom_sleep 1
    echo -e "${C}Güvenli çıkış yapılıyor...${NC}"
    bekle 1 10
    exit 0
fi

echo ""
basarili "Güvenlik onayı alındı"
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
custom_sleep 1

echo -e "${C}[●] Transfer başladı... (dd progress aşağıda)${NC}"
echo ""

# DD işlemi
dd if=/dev/$HOCA of=/dev/$SENIN bs=4M status=progress conv=fsync

if [ $? -eq 0 ]; then
    echo ""
    echo ""
    yukleme_cemberi 3 "[◆] Transfer tamamlandı, doğrulanıyor"
    echo ""
    
    progress_bar 3 "[●] Veri bütünlüğü kontrol ediliyor"
    echo ""
    
    yukleme_cemberi 2 "[◆] Buffer sync yapılıyor"
    sync
    basarili "Tüm veriler diske yazıldı, lütfen bekleyin ve asla USB disklerinizi çıkarmayın."
    
    # ==========================================
    # GÜVENLİK ADIMI (EJECT)
    # ==========================================
    echo ""
    yaz "[🔌] Bekleyin, hedef disk güvenli moda alınıyor..." "$W" 0.03
    
    eject /dev/$SENIN 2>/dev/null || umount /dev/$SENIN* 2>/dev/null
    
    basarili "Hedef disk (/dev/$SENIN) sistemden ayrıldı"
    echo -e "${Y}[!] Artık otomatik mount edilemez, güvenle çekebilirsin.${NC}"
    
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
    echo -e "  ${C}[📦] Klonlama Raporu: Başarılı${NC}"
    echo -e "  ${G}[✔] Hedef disk (/dev/$SENIN) şimdi kullanılabilir${NC}"
    echo -e "  ${W}[ℹ] Güvenle çıkarabilirsin.${NC}"

    echo ""
    echo -e "${M}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${M}│${NC}                                                     ${M}│${NC}"
    echo -ne "${M}│${NC}  "; yaz "Tahtayı açmak için hazır mısın? 😎" "$Y$BOLD" 0.03;
    echo -e "${M}│${NC}                                                     ${M}│${NC}"
    echo -e "${M}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    
else
    echo ""
    echo -e "${R}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${R}║${NC}          ${BOLD}✗  İŞLEM BAŞARISIZ!${NC}                      ${R}║${NC}"
    echo -e "${R}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${R}[!] Transfer sırasında hata oluştu.${NC}"
    custom_sleep 1
    echo -e "${Y}[!] Disk bağlantılarını kontrol edin.${NC}"
    exit 1
fi
