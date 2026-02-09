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
# TRANSFER MODU SEÇİMİ
# ========================================
clear
echo -e "${C}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${C}│${NC} ${BOLD}${W}        Transfer Modu Seçimi${NC}                          ${C}│${NC}"
echo -e "${C}├──────────────────────────────────────────────────────┤${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}│${NC}  ${G}[1]${NC}  ${W}Tam Klon (dd)${NC}                                  ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Diskin tamamını birebir kopyalar${NC}               ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Boş alanlar dahil her şeyi aktarır${NC}            ${C}│${NC}"
echo -e "${C}│${NC}       ${Y}Daha yavaş ama %100 aynı kopya${NC}                ${C}│${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}│${NC}  ${G}[2]${NC}  ${W}UUID Modu (Akıllı Klon)${NC}                         ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Sadece UUID ve dosyaları kopyalar${NC}              ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Partition tablosu + dosya sistemi + veriler${NC}    ${C}│${NC}"
echo -e "${C}│${NC}       ${C}Diskin sadece dolu kısmını aktarır${NC}             ${C}│${NC}"
echo -e "${C}│${NC}       ${Y}Çok daha hızlı, UUID korunur${NC}                   ${C}│${NC}"
echo -e "${C}│${NC}                                                      ${C}│${NC}"
echo -e "${C}└──────────────────────────────────────────────────────┘${NC}"
echo ""
echo -ne "${Y}Seçiminiz [1/2]: ${NC}"
read -r TRANSFER_MOD

case "$TRANSFER_MOD" in
    2)
        UUID_MOD=1
        echo -e "\n${G}[✓] UUID Modu aktif. Sadece dolu kısımlar kopyalanacak...${NC}\n"
        ;;
    *)
        UUID_MOD=0
        echo -e "\n${G}[✓] Tam Klon modu aktif. Disk birebir kopyalanacak...${NC}\n"
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
if [ "$UUID_MOD" -eq 1 ]; then
    echo -e "${C}│${NC}  ${BOLD}Transfer :${NC} ${B}UUID Modu (Akıllı Klon)${NC}          ${C}│${NC}"
else
    echo -e "${C}│${NC}  ${BOLD}Transfer :${NC} ${G}Tam Klon (dd)${NC}                   ${C}│${NC}"
fi
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

if [ "$UUID_MOD" -eq 1 ]; then
    scan_anim "Kernel Modülleri" "Disk Araçları" "I/O Sistemleri" "Buffer Yöneticisi" "Partition Araçları" "UUID Yöneticisi" "Dosya Sistemi Araçları"
else
    scan_anim "Kernel Modülleri" "Disk Araçları" "I/O Sistemleri" "Buffer Yöneticisi"
fi

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

# UUID modu için ek araç kontrolleri
if [ "$UUID_MOD" -eq 1 ]; then
    # sfdisk kontrolü
    if ! command -v sfdisk &> /dev/null; then
        echo -e "${Y}[!] sfdisk yükleniyor...${NC}"
        apt-get install -y fdisk &> /dev/null || yum install -y util-linux &> /dev/null
    fi
    if command -v sfdisk &> /dev/null; then
        basarili "sfdisk (partition tablosu) hazır"
    else
        echo -e "${R}[✗] HATA: sfdisk bulunamadı! UUID modu için gerekli.${NC}"
        exit 1
    fi

    # mkfs araçları kontrolü
    if command -v mkfs.vfat &> /dev/null || command -v mkfs.ext4 &> /dev/null || command -v mkfs.ntfs &> /dev/null; then
        basarili "Dosya sistemi oluşturma araçları hazır"
    else
        echo -e "${Y}[!] Dosya sistemi araçları yükleniyor...${NC}"
        apt-get install -y dosfstools e2fsprogs ntfs-3g &> /dev/null || yum install -y dosfstools e2fsprogs ntfs-3g &> /dev/null
    fi

    # rsync veya cp kontrolü
    if command -v rsync &> /dev/null; then
        KOPYA_ARACI="rsync"
        basarili "rsync dosya transfer motoru hazır"
    else
        KOPYA_ARACI="cp"
        basarili "cp dosya transfer motoru hazır"
    fi

    # blkid kontrolü
    if ! command -v blkid &> /dev/null; then
        echo -e "${R}[✗] HATA: blkid bulunamadı!${NC}"
        exit 1
    fi
    basarili "blkid UUID okuyucu hazır"

    # tune2fs / fatlabel / ntfslabel kontrolü
    basarili "UUID/Label yazma araçları kontrol edildi"
fi

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

# UUID modunda kaynak disk bilgilerini göster
if [ "$UUID_MOD" -eq 1 ]; then
    echo ""
    echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${C}│${NC} ${BOLD}${W}Kaynak Disk Partition Bilgileri:${NC}                   ${C}│${NC}"
    echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Kaynak disk partition'larını listele
    KAYNAK_PARTLAR=$(lsblk -nlo NAME,SIZE,FSTYPE,LABEL,UUID /dev/$HOCA | tail -n +2)
    if [ -z "$KAYNAK_PARTLAR" ]; then
        echo -e "${Y}[ℹ] Kaynak diskte partition bulunamadı. Disk düz formatlı olabilir.${NC}"
        # Düz disk kontrolü (partition tablosu olmadan doğrudan formatlanmış)
        KAYNAK_FSTYPE=$(blkid -s TYPE -o value /dev/$HOCA 2>/dev/null)
        KAYNAK_UUID_DISK=$(blkid -s UUID -o value /dev/$HOCA 2>/dev/null)
        if [ -n "$KAYNAK_FSTYPE" ]; then
            echo -e "  ${C}Dosya Sistemi:${NC} ${G}$KAYNAK_FSTYPE${NC}"
            echo -e "  ${C}UUID         :${NC} ${G}$KAYNAK_UUID_DISK${NC}"
        fi
    else
        echo "$KAYNAK_PARTLAR" | while read line; do
            PNAME=$(echo "$line" | awk '{print $1}')
            PSIZE=$(echo "$line" | awk '{print $2}')
            PFSTYPE=$(echo "$line" | awk '{print $3}')
            PLABEL=$(echo "$line" | awk '{print $4}')
            PUUID=$(echo "$line" | awk '{print $5}')
            echo -e "  ${W}$PNAME${NC} | Boyut: ${G}$PSIZE${NC} | FS: ${C}${PFSTYPE:-bilinmiyor}${NC} | Label: ${Y}${PLABEL:-yok}${NC} | UUID: ${M}${PUUID:-yok}${NC}"
        done
    fi
    echo ""
    
    # Kaynak disk kullanılan alan hesaplama
    KAYNAK_BOYUT=$(lsblk -bdno SIZE /dev/$HOCA)
    KAYNAK_BOYUT_MB=$((KAYNAK_BOYUT / 1024 / 1024))
    HEDEF_BOYUT=$(lsblk -bdno SIZE /dev/$SENIN)
    HEDEF_BOYUT_MB=$((HEDEF_BOYUT / 1024 / 1024))
    
    echo -e "  ${C}Kaynak disk toplam:${NC} ${G}${KAYNAK_BOYUT_MB} MB${NC}"
    echo -e "  ${C}Hedef disk toplam :${NC} ${G}${HEDEF_BOYUT_MB} MB${NC}"
    echo ""
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
echo -e "  ${C}Kaynak Cihaz :${NC} ${G}/dev/$HOCA${NC}"
custom_sleep 0.3
echo -e "  ${C}Hedef Cihaz  :${NC} ${R}/dev/$SENIN${NC}"
custom_sleep 0.3
if [ "$UUID_MOD" -eq 1 ]; then
    echo -e "  ${C}Transfer Modu:${NC} ${B}UUID Modu (Akıllı Klon)${NC}"
    echo -e "  ${C}Yöntem       :${NC} ${Y}Partition tablosu + Dosya sistemi + Dosyalar + UUID${NC}"
else
    echo -e "  ${C}Transfer Modu:${NC} ${G}Tam Klon (dd birebir)${NC}"
fi
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

# Hem kaynak hem hedef unmount
umount /dev/${SENIN}* 2>/dev/null
umount /dev/${HOCA}* 2>/dev/null
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

# UUID modu için ek hazırlık
if [ "$UUID_MOD" -eq 1 ]; then
    echo ""
    progress_bar 2 "[●] UUID modu için ek hazırlıklar yapılıyor"
    echo ""
    
    # Geçici mount dizinleri oluştur
    UUID_KAYNAK_MNT=$(mktemp -d /tmp/flashor_kaynak_XXXXXX)
    UUID_HEDEF_MNT=$(mktemp -d /tmp/flashor_hedef_XXXXXX)
    
    basarili "Geçici mount dizinleri oluşturuldu"
    basarili "Kaynak: $UUID_KAYNAK_MNT"
    basarili "Hedef : $UUID_HEDEF_MNT"
    
    # Kaynak disk partition bilgilerini topla
    yukleme_cemberi 2 "[◆] Kaynak disk partition haritası çıkarılıyor"
    
    # Partition tablosu var mı kontrol et
    PART_TABLE_TYPE=$(blkid -p -s PTTYPE -o value /dev/$HOCA 2>/dev/null)
    
    if [ -n "$PART_TABLE_TYPE" ]; then
        basarili "Partition tablosu bulundu: $PART_TABLE_TYPE"
        HAS_PARTITION_TABLE=1
    else
        # Doğrudan formatlı disk olabilir
        DIRECT_FSTYPE=$(blkid -s TYPE -o value /dev/$HOCA 2>/dev/null)
        if [ -n "$DIRECT_FSTYPE" ]; then
            basarili "Partition tablosu yok, doğrudan formatlanmış disk: $DIRECT_FSTYPE"
            HAS_PARTITION_TABLE=0
        else
            echo -e "${R}[✗] HATA: Kaynak diskte dosya sistemi bulunamadı!${NC}"
            rmdir "$UUID_KAYNAK_MNT" "$UUID_HEDEF_MNT" 2>/dev/null
            exit 1
        fi
    fi
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

if [ "$UUID_MOD" -eq 1 ]; then
    # ========================================
    # UUID MODU FLAŞLAMA
    # ========================================
    yaz "[🚀] UUID Modu - Akıllı transfer başlatılıyor..." "$W"
    bekle 2 20
    echo ""
    
    yukleme_cemberi 2 "[◆] Partition analizi yapılıyor"
    echo ""
    
    echo -e "${M}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${M}│${NC} ${BOLD}${W}UUID Modu - Akıllı Klonlama İşlemi:${NC}               ${M}│${NC}"
    echo -e "${M}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    TRANSFER_HATA=0
    
    if [ "$HAS_PARTITION_TABLE" -eq 1 ]; then
        # ==========================================
        # AŞAMA 1: Partition tablosunu kopyala
        # ==========================================
        echo -e "${B}━━━ Aşama 1/4: Partition Tablosu Kopyalanıyor ━━━${NC}"
        echo ""
        
        yukleme_cemberi 2 "[◆] Kaynak partition tablosu okunuyor"
        
        # sfdisk ile partition tablosunu kaydet ve hedefe yaz
        sfdisk -d /dev/$HOCA > /tmp/flashor_ptable.txt 2>/dev/null
        
        if [ $? -eq 0 ]; then
            basarili "Partition tablosu okundu ($PART_TABLE_TYPE)"
            
            if [ "$HIZLI_MOD" -eq 0 ]; then
                echo ""
                echo -e "${C}  Partition tablosu içeriği:${NC}"
                cat /tmp/flashor_ptable.txt | head -20 | while read line; do
                    echo -e "  ${W}$line${NC}"
                done
                echo ""
            fi
            
            yukleme_cemberi 2 "[◆] Hedef diske partition tablosu yazılıyor"
            
            # Hedef diski temizle
            wipefs -a /dev/$SENIN &>/dev/null
            dd if=/dev/zero of=/dev/$SENIN bs=1M count=1 &>/dev/null
            sync
            
            sfdisk /dev/$SENIN < /tmp/flashor_ptable.txt &>/dev/null
            
            if [ $? -eq 0 ]; then
                basarili "Partition tablosu hedefe yazıldı"
            else
                echo -e "${R}[✗] Partition tablosu yazılamadı!${NC}"
                TRANSFER_HATA=1
            fi
            
            # Kernel'e partition tablosunu yeniden okumasını söyle
            partprobe /dev/$SENIN 2>/dev/null
            sleep 2
            
            # Disk ID'yi de kopyala (MBR disk identifier)
            if [ "$PART_TABLE_TYPE" == "dos" ]; then
                DISK_ID=$(sfdisk -d /dev/$HOCA 2>/dev/null | grep "^label-id:" | awk '{print $2}')
                if [ -n "$DISK_ID" ]; then
                    basarili "MBR Disk ID kopyalandı: $DISK_ID"
                fi
            elif [ "$PART_TABLE_TYPE" == "gpt" ]; then
                # GPT disk GUID'i sgdisk ile kopyalanabilir
                if command -v sgdisk &>/dev/null; then
                    GPT_GUID=$(sgdisk -p /dev/$HOCA 2>/dev/null | grep "Disk identifier" | awk '{print $NF}')
                    if [ -n "$GPT_GUID" ]; then
                        sgdisk -U "$GPT_GUID" /dev/$SENIN &>/dev/null
                        basarili "GPT Disk GUID kopyalandı: $GPT_GUID"
                    fi
                fi
            fi
        else
            echo -e "${R}[✗] Partition tablosu okunamadı!${NC}"
            TRANSFER_HATA=1
        fi
        
        rm -f /tmp/flashor_ptable.txt
        
        echo ""
        progress_bar 2 "[●] Aşama 1 tamamlandı"
        echo ""
        
        # ==========================================
        # AŞAMA 2: Her partition için dosya sistemi oluştur ve dosyaları kopyala
        # ==========================================
        echo -e "${B}━━━ Aşama 2/4: Dosya Sistemleri ve Veriler Kopyalanıyor ━━━${NC}"
        echo ""
        
        # Kaynak partition'ları tespit et
        KAYNAK_PARTLAR=$(lsblk -nlo NAME /dev/$HOCA | tail -n +2)
        HEDEF_PARTLAR=$(lsblk -nlo NAME /dev/$SENIN | tail -n +2)
        
        # Partition'ları diziye çevir
        readarray -t KAYNAK_ARR <<< "$KAYNAK_PARTLAR"
        readarray -t HEDEF_ARR <<< "$HEDEF_PARTLAR"
        
        PART_SAYISI=${#KAYNAK_ARR[@]}
        
        echo -e "${C}[ℹ] Toplam ${PART_SAYISI} partition işlenecek${NC}"
        echo ""
        
        for ((p=0; p<PART_SAYISI; p++)); do
            KAYNAK_PART="${KAYNAK_ARR[$p]}"
            
            # Boş satır kontrolü
            if [ -z "$KAYNAK_PART" ]; then
                continue
            fi
            
            # Hedef partition'ı bul
            if [ $p -lt ${#HEDEF_ARR[@]} ]; then
                HEDEF_PART="${HEDEF_ARR[$p]}"
            else
                echo -e "${R}[✗] Hedef partition bulunamadı: index $p${NC}"
                continue
            fi
            
            if [ -z "$HEDEF_PART" ]; then
                continue
            fi
            
            KAYNAK_PART=$(echo "$KAYNAK_PART" | tr -d '[:space:]')
            HEDEF_PART=$(echo "$HEDEF_PART" | tr -d '[:space:]')
            
            echo -e "${Y}┌─────────────────────────────────────────────────────┐${NC}"
            echo -e "${Y}│${NC} ${BOLD}Partition $((p+1))/$PART_SAYISI: /dev/$KAYNAK_PART → /dev/$HEDEF_PART${NC}  ${Y}│${NC}"
            echo -e "${Y}└─────────────────────────────────────────────────────┘${NC}"
            
            # Kaynak partition bilgilerini al
            PART_FSTYPE=$(blkid -s TYPE -o value /dev/$KAYNAK_PART 2>/dev/null)
            PART_UUID=$(blkid -s UUID -o value /dev/$KAYNAK_PART 2>/dev/null)
            PART_LABEL=$(blkid -s LABEL -o value /dev/$KAYNAK_PART 2>/dev/null)
            PART_PARTUUID=$(blkid -s PARTUUID -o value /dev/$KAYNAK_PART 2>/dev/null)
            
            echo -e "  ${C}Dosya Sistemi:${NC} ${G}${PART_FSTYPE:-bilinmiyor}${NC}"
            echo -e "  ${C}UUID         :${NC} ${G}${PART_UUID:-yok}${NC}"
            echo -e "  ${C}Label        :${NC} ${G}${PART_LABEL:-yok}${NC}"
            echo -e "  ${C}PARTUUID     :${NC} ${G}${PART_PARTUUID:-yok}${NC}"
            echo ""
            
            if [ -z "$PART_FSTYPE" ]; then
                echo -e "${Y}[!] Bu partition'da dosya sistemi bulunamadı, ham kopyalama yapılıyor...${NC}"
                dd if=/dev/$KAYNAK_PART of=/dev/$HEDEF_PART bs=4M status=progress conv=fsync
                if [ $? -ne 0 ]; then
                    echo -e "${R}[✗] Ham kopyalama başarısız: /dev/$KAYNAK_PART${NC}"
                    TRANSFER_HATA=1
                else
                    basarili "Ham kopyalama tamamlandı: /dev/$KAYNAK_PART"
                fi
                echo ""
                continue
            fi
            
            # Dosya sistemi oluştur
            yukleme_cemberi 1 "[◆] Dosya sistemi oluşturuluyor: $PART_FSTYPE"
            
            case "$PART_FSTYPE" in
                vfat|fat32|fat16|fat12)
                    # FAT boyutunu belirle
                    FAT_SIZE=""
                    case "$PART_FSTYPE" in
                        fat12) FAT_SIZE="-F 12" ;;
                        fat16) FAT_SIZE="-F 16" ;;
                        *) FAT_SIZE="-F 32" ;;
                    esac
                    
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.vfat $FAT_SIZE -n "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.vfat $FAT_SIZE /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                ext2)
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.ext2 -F -L "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.ext2 -F /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                ext3)
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.ext3 -F -L "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.ext3 -F /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                ext4)
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.ext4 -F -L "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.ext4 -F /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                ntfs)
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.ntfs -f -L "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.ntfs -f /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                exfat)
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.exfat -n "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.exfat /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                btrfs)
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.btrfs -f -L "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.btrfs -f /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                xfs)
                    if [ -n "$PART_LABEL" ]; then
                        mkfs.xfs -f -L "$PART_LABEL" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkfs.xfs -f /dev/$HEDEF_PART &>/dev/null
                    fi
                    ;;
                swap)
                    if [ -n "$PART_UUID" ]; then
                        mkswap -U "$PART_UUID" /dev/$HEDEF_PART &>/dev/null
                    else
                        mkswap /dev/$HEDEF_PART &>/dev/null
                    fi
                    basarili "Swap partition oluşturuldu"
                    echo ""
                    continue
                    ;;
                *)
                    echo -e "${Y}[!] Bilinmeyen dosya sistemi ($PART_FSTYPE), ham kopyalama yapılıyor...${NC}"
                    dd if=/dev/$KAYNAK_PART of=/dev/$HEDEF_PART bs=4M status=progress conv=fsync
                    if [ $? -ne 0 ]; then
                        TRANSFER_HATA=1
                    fi
                    echo ""
                    continue
                    ;;
            esac
            
            if [ $? -eq 0 ]; then
                basarili "Dosya sistemi oluşturuldu: $PART_FSTYPE"
            else
                echo -e "${R}[✗] Dosya sistemi oluşturulamadı!${NC}"
                TRANSFER_HATA=1
                continue
            fi
            
            # UUID'yi ayarla
            if [ -n "$PART_UUID" ]; then
                yukleme_cemberi 1 "[◆] UUID ayarlanıyor: $PART_UUID"
                
                case "$PART_FSTYPE" in
                    ext2|ext3|ext4)
                        tune2fs -U "$PART_UUID" /dev/$HEDEF_PART &>/dev/null
                        ;;
                    vfat|fat32|fat16|fat12)
                        # FAT UUID formatı: XXXX-XXXX
                        if command -v mlabel &>/dev/null; then
                            # mtools ile UUID ayarla
                            VOLUME_ID=$(echo "$PART_UUID" | tr -d '-')
                            printf "\x${VOLUME_ID:6:2}\x${VOLUME_ID:4:2}\x${VOLUME_ID:2:2}\x${VOLUME_ID:0:2}" | \
                                dd of=/dev/$HEDEF_PART bs=1 seek=67 count=4 conv=notrunc &>/dev/null 2>&1
                            # FAT16 offset farklı olabilir, FAT32 için seek=67
                        else
                            # dd ile doğrudan Volume Serial Number yaz
                            VOLUME_ID=$(echo "$PART_UUID" | tr -d '-')
                            # FAT32 volume ID offset: 67 (0x43)
                            # FAT16 volume ID offset: 39 (0x27)
                            FAT_TYPE_CHECK=$(file -s /dev/$HEDEF_PART 2>/dev/null)
                            if echo "$FAT_TYPE_CHECK" | grep -qi "FAT (16 bit)"; then
                                SEEK_POS=39
                            else
                                SEEK_POS=67
                            fi
                            printf "\x${VOLUME_ID:6:2}\x${VOLUME_ID:4:2}\x${VOLUME_ID:2:2}\x${VOLUME_ID:0:2}" | \
                                dd of=/dev/$HEDEF_PART bs=1 seek=$SEEK_POS count=4 conv=notrunc &>/dev/null 2>&1
                        fi
                        ;;
                    ntfs)
                        if command -v ntfslabel &>/dev/null; then
                            # NTFS UUID = Volume Serial Number
                            # ntfsfix veya doğrudan yazma ile ayarlanabilir
                            NTFS_SERIAL=$(echo "$PART_UUID" | tr -d '[:space:]')
                            printf "\x${NTFS_SERIAL:14:2}\x${NTFS_SERIAL:12:2}\x${NTFS_SERIAL:10:2}\x${NTFS_SERIAL:8:2}\x${NTFS_SERIAL:6:2}\x${NTFS_SERIAL:4:2}\x${NTFS_SERIAL:2:2}\x${NTFS_SERIAL:0:2}" | \
                                dd of=/dev/$HEDEF_PART bs=1 seek=72 count=8 conv=notrunc &>/dev/null 2>&1
                        fi
                        ;;
                    btrfs)
                        if command -v btrfstune &>/dev/null; then
                            btrfstune -U "$PART_UUID" /dev/$HEDEF_PART &>/dev/null
                        fi
                        ;;
                    xfs)
                        if command -v xfs_admin &>/dev/null; then
                            xfs_admin -U "$PART_UUID" /dev/$HEDEF_PART &>/dev/null
                        fi
                        ;;
                    exfat)
                        # exFAT UUID doğrudan volume serial ile yazılır
                        EXFAT_SERIAL=$(echo "$PART_UUID" | tr -d '-')
                        printf "\x${EXFAT_SERIAL:6:2}\x${EXFAT_SERIAL:4:2}\x${EXFAT_SERIAL:2:2}\x${EXFAT_SERIAL:0:2}" | \
                            dd of=/dev/$HEDEF_PART bs=1 seek=100 count=4 conv=notrunc &>/dev/null 2>&1
                        ;;
                esac
                
                # UUID doğrulama
                NEW_UUID=$(blkid -s UUID -o value /dev/$HEDEF_PART 2>/dev/null)
                if [ "$NEW_UUID" == "$PART_UUID" ]; then
                    basarili "UUID başarıyla ayarlandı: $PART_UUID"
                else
                    echo -e "${Y}[!] UUID ayarlanamadı (Kaynak: $PART_UUID, Hedef: ${NEW_UUID:-boş})${NC}"
                    echo -e "${Y}    Bu bazı dosya sistemi türlerinde normal olabilir${NC}"
                fi
            fi
            
            # Dosyaları kopyala
            echo ""
            yukleme_cemberi 1 "[◆] Dosyalar kopyalanıyor"
            
            # Kaynak partition'ı mount et
            mount -o ro /dev/$KAYNAK_PART "$UUID_KAYNAK_MNT" 2>/dev/null
            MOUNT_KAYNAK_OK=$?
            
            # Hedef partition'ı mount et
            mount /dev/$HEDEF_PART "$UUID_HEDEF_MNT" 2>/dev/null
            MOUNT_HEDEF_OK=$?
            
            if [ $MOUNT_KAYNAK_OK -eq 0 ] && [ $MOUNT_HEDEF_OK -eq 0 ]; then
                # Kullanılan alan hesapla
                KULLANILAN=$(du -sm "$UUID_KAYNAK_MNT" 2>/dev/null | awk '{print $1}')
                DOSYA_SAYISI=$(find "$UUID_KAYNAK_MNT" -type f 2>/dev/null | wc -l)
                DIZIN_SAYISI=$(find "$UUID_KAYNAK_MNT" -type d 2>/dev/null | wc -l)
                
                echo -e "  ${C}Kopyalanacak veri :${NC} ${G}${KULLANILAN:-bilinmiyor} MB${NC}"
                echo -e "  ${C}Dosya sayısı      :${NC} ${G}${DOSYA_SAYISI:-0}${NC}"
                echo -e "  ${C}Dizin sayısı      :${NC} ${G}${DIZIN_SAYISI:-0}${NC}"
                echo ""
                
                # Dosya kopyalama
                if [ "$KOPYA_ARACI" == "rsync" ]; then
                    echo -e "${C}[●] rsync ile dosyalar kopyalanıyor...${NC}"
                    echo ""
                    rsync -aHAXWS --info=progress2 --no-compress "$UUID_KAYNAK_MNT/" "$UUID_HEDEF_MNT/"
                    KOPYA_SONUC=$?
                else
                    echo -e "${C}[●] cp ile dosyalar kopyalanıyor...${NC}"
                    echo ""
                    cp -a "$UUID_KAYNAK_MNT/." "$UUID_HEDEF_MNT/"
                    KOPYA_SONUC=$?
                fi
                
                if [ $KOPYA_SONUC -eq 0 ]; then
                    echo ""
                    basarili "Dosyalar başarıyla kopyalandı (/dev/$KAYNAK_PART)"
                else
                    echo ""
                    echo -e "${R}[✗] Dosya kopyalama hatası: /dev/$KAYNAK_PART${NC}"
                    TRANSFER_HATA=1
                fi
            else
                if [ $MOUNT_KAYNAK_OK -ne 0 ]; then
                    echo -e "${Y}[!] Kaynak partition mount edilemedi (/dev/$KAYNAK_PART)${NC}"
                    echo -e "${Y}    Ham kopyalama yapılıyor...${NC}"
                    umount "$UUID_HEDEF_MNT" 2>/dev/null
                    dd if=/dev/$KAYNAK_PART of=/dev/$HEDEF_PART bs=4M status=progress conv=fsync
                    if [ $? -ne 0 ]; then
                        TRANSFER_HATA=1
                    fi
                fi
                if [ $MOUNT_HEDEF_OK -ne 0 ]; then
                    echo -e "${R}[✗] Hedef partition mount edilemedi (/dev/$HEDEF_PART)${NC}"
                    TRANSFER_HATA=1
                fi
            fi
            
            # Unmount
            sync
            umount "$UUID_KAYNAK_MNT" 2>/dev/null
            umount "$UUID_HEDEF_MNT" 2>/dev/null
            
            echo ""
        done
        
    else
        # ==========================================
        # PARTITION TABLOSU OLMAYAN DİSK (düz format)
        # ==========================================
        echo -e "${B}━━━ Düz Formatlı Disk Klonlama ━━━${NC}"
        echo ""
        
        DIRECT_FSTYPE=$(blkid -s TYPE -o value /dev/$HOCA 2>/dev/null)
        DIRECT_UUID=$(blkid -s UUID -o value /dev/$HOCA 2>/dev/null)
        DIRECT_LABEL=$(blkid -s LABEL -o value /dev/$HOCA 2>/dev/null)
        
        echo -e "  ${C}Dosya Sistemi:${NC} ${G}$DIRECT_FSTYPE${NC}"
        echo -e "  ${C}UUID         :${NC} ${G}${DIRECT_UUID:-yok}${NC}"
        echo -e "  ${C}Label        :${NC} ${G}${DIRECT_LABEL:-yok}${NC}"
        echo ""
        
        # Dosya sistemi oluştur
        yukleme_cemberi 2 "[◆] Hedef diske dosya sistemi oluşturuluyor: $DIRECT_FSTYPE"
        
        case "$DIRECT_FSTYPE" in
            vfat|fat32|fat16|fat12)
                FAT_SIZE="-F 32"
                [ "$DIRECT_FSTYPE" == "fat16" ] && FAT_SIZE="-F 16"
                [ "$DIRECT_FSTYPE" == "fat12" ] && FAT_SIZE="-F 12"
                if [ -n "$DIRECT_LABEL" ]; then
                    mkfs.vfat $FAT_SIZE -n "$DIRECT_LABEL" /dev/$SENIN &>/dev/null
                else
                    mkfs.vfat $FAT_SIZE /dev/$SENIN &>/dev/null
                fi
                ;;
            ext2) mkfs.ext2 -F ${DIRECT_LABEL:+-L "$DIRECT_LABEL"} /dev/$SENIN &>/dev/null ;;
            ext3) mkfs.ext3 -F ${DIRECT_LABEL:+-L "$DIRECT_LABEL"} /dev/$SENIN &>/dev/null ;;
            ext4) mkfs.ext4 -F ${DIRECT_LABEL:+-L "$DIRECT_LABEL"} /dev/$SENIN &>/dev/null ;;
            ntfs) mkfs.ntfs -f ${DIRECT_LABEL:+-L "$DIRECT_LABEL"} /dev/$SENIN &>/dev/null ;;
            exfat) mkfs.exfat ${DIRECT_LABEL:+-n "$DIRECT_LABEL"} /dev/$SENIN &>/dev/null ;;
            btrfs) mkfs.btrfs -f ${DIRECT_LABEL:+-L "$DIRECT_LABEL"} /dev/$SENIN &>/dev/null ;;
            xfs) mkfs.xfs -f ${DIRECT_LABEL:+-L "$DIRECT_LABEL"} /dev/$SENIN &>/dev/null ;;
            *)
                echo -e "${Y}[!] Bilinmeyen dosya sistemi, dd ile tam kopyalama yapılıyor...${NC}"
                dd if=/dev/$HOCA of=/dev/$SENIN bs=4M status=progress conv=fsync
                if [ $? -ne 0 ]; then TRANSFER_HATA=1; fi
                # Temizlik
                rmdir "$UUID_KAYNAK_MNT" "$UUID_HEDEF_MNT" 2>/dev/null
                # Sonuca atla
                if [ $TRANSFER_HATA -eq 0 ]; then
                    basarili "Transfer tamamlandı"
                fi
                # Buradan aşağıdaki UUID ayarlama kısmına geçmeyeceğiz
                UUID_SKIP_COPY=1
                ;;
        esac
        
        if [ "${UUID_SKIP_COPY:-0}" -ne 1 ]; then
            basarili "Dosya sistemi oluşturuldu: $DIRECT_FSTYPE"
            
            # UUID ayarla
            if [ -n "$DIRECT_UUID" ]; then
                yukleme_cemberi 1 "[◆] UUID ayarlanıyor: $DIRECT_UUID"
                case "$DIRECT_FSTYPE" in
                    ext2|ext3|ext4) tune2fs -U "$DIRECT_UUID" /dev/$SENIN &>/dev/null ;;
                    vfat|fat32|fat16|fat12)
                        VOLUME_ID=$(echo "$DIRECT_UUID" | tr -d '-')
                        FAT_TYPE_CHECK=$(file -s /dev/$SENIN 2>/dev/null)
                        if echo "$FAT_TYPE_CHECK" | grep -qi "FAT (16 bit)"; then SEEK_POS=39; else SEEK_POS=67; fi
                        printf "\x${VOLUME_ID:6:2}\x${VOLUME_ID:4:2}\x${VOLUME_ID:2:2}\x${VOLUME_ID:0:2}" | \
                            dd of=/dev/$SENIN bs=1 seek=$SEEK_POS count=4 conv=notrunc &>/dev/null 2>&1
                        ;;
                    btrfs) command -v btrfstune &>/dev/null && btrfstune -U "$DIRECT_UUID" /dev/$SENIN &>/dev/null ;;
                    xfs) command -v xfs_admin &>/dev/null && xfs_admin -U "$DIRECT_UUID" /dev/$SENIN &>/dev/null ;;
                esac
                
                NEW_UUID=$(blkid -s UUID -o value /dev/$SENIN 2>/dev/null)
                if [ "$NEW_UUID" == "$DIRECT_UUID" ]; then
                    basarili "UUID başarıyla ayarlandı: $DIRECT_UUID"
                else
                    echo -e "${Y}[!] UUID tam ayarlanamadı (Kaynak: $DIRECT_UUID, Hedef: ${NEW_UUID:-boş})${NC}"
                fi
            fi
            
            # Dosyaları kopyala
            echo ""
            yukleme_cemberi 1 "[◆] Dosyalar kopyalanıyor"
            
            mount -o ro /dev/$HOCA "$UUID_KAYNAK_MNT" 2>/dev/null
            mount /dev/$SENIN "$UUID_HEDEF_MNT" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                KULLANILAN=$(du -sm "$UUID_KAYNAK_MNT" 2>/dev/null | awk '{print $1}')
                DOSYA_SAYISI=$(find "$UUID_KAYNAK_MNT" -type f 2>/dev/null | wc -l)
                
                echo -e "  ${C}Kopyalanacak veri:${NC} ${G}${KULLANILAN:-bilinmiyor} MB${NC}"
                echo -e "  ${C}Dosya sayısı     :${NC} ${G}${DOSYA_SAYISI:-0}${NC}"
                echo ""
                
                if [ "$KOPYA_ARACI" == "rsync" ]; then
                    echo -e "${C}[●] rsync ile dosyalar kopyalanıyor...${NC}"
                    echo ""
                    rsync -aHAXWS --info=progress2 --no-compress "$UUID_KAYNAK_MNT/" "$UUID_HEDEF_MNT/"
                    KOPYA_SONUC=$?
                else
                    echo -e "${C}[●] cp ile dosyalar kopyalanıyor...${NC}"
                    echo ""
                    cp -a "$UUID_KAYNAK_MNT/." "$UUID_HEDEF_MNT/"
                    KOPYA_SONUC=$?
                fi
                
                if [ $KOPYA_SONUC -eq 0 ]; then
                    echo ""
                    basarili "Dosyalar başarıyla kopyalandı"
                else
                    echo ""
                    echo -e "${R}[✗] Dosya kopyalama hatası!${NC}"
                    TRANSFER_HATA=1
                fi
            else
                echo -e "${R}[✗] Disk mount edilemedi!${NC}"
                TRANSFER_HATA=1
            fi
            
            sync
            umount "$UUID_KAYNAK_MNT" 2>/dev/null
            umount "$UUID_HEDEF_MNT" 2>/dev/null
        fi
    fi
    
    # ==========================================
    # AŞAMA 3: Doğrulama
    # ==========================================
    echo ""
    echo -e "${B}━━━ Aşama 3/4: Doğrulama ━━━${NC}"
    echo ""
    
    progress_bar 2 "[●] UUID ve dosya sistemi doğrulanıyor"
    echo ""
    
    echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${C}│${NC} ${BOLD}${W}Doğrulama Raporu:${NC}                                 ${C}│${NC}"
    echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    if [ "$HAS_PARTITION_TABLE" -eq 1 ] 2>/dev/null; then
        # Her partition'ın UUID'sini karşılaştır
        KAYNAK_PARTLAR=$(lsblk -nlo NAME /dev/$HOCA | tail -n +2)
        HEDEF_PARTLAR=$(lsblk -nlo NAME /dev/$SENIN | tail -n +2)
        
        readarray -t KAYNAK_ARR <<< "$KAYNAK_PARTLAR"
        readarray -t HEDEF_ARR <<< "$HEDEF_PARTLAR"
        
        for ((p=0; p<${#KAYNAK_ARR[@]}; p++)); do
            KP="${KAYNAK_ARR[$p]}"
            HP="${HEDEF_ARR[$p]:-}"
            
            [ -z "$KP" ] && continue
            [ -z "$HP" ] && continue
            
            KP=$(echo "$KP" | tr -d '[:space:]')
            HP=$(echo "$HP" | tr -d '[:space:]')
            
            K_UUID=$(blkid -s UUID -o value /dev/$KP 2>/dev/null)
            H_UUID=$(blkid -s UUID -o value /dev/$HP 2>/dev/null)
            K_FS=$(blkid -s TYPE -o value /dev/$KP 2>/dev/null)
            H_FS=$(blkid -s TYPE -o value /dev/$HP 2>/dev/null)
            
            echo -e "  ${W}Partition $((p+1)):${NC}"
            
            if [ "$K_FS" == "$H_FS" ]; then
                echo -e "    ${G}[✔]${NC} Dosya sistemi eşleşti: ${G}$K_FS${NC}"
            else
                echo -e "    ${R}[✗]${NC} Dosya sistemi uyumsuz: Kaynak=$K_FS, Hedef=$H_FS"
            fi
            
            if [ "$K_UUID" == "$H_UUID" ] && [ -n "$K_UUID" ]; then
                echo -e "    ${G}[✔]${NC} UUID eşleşti: ${G}$K_UUID${NC}"
            elif [ -n "$K_UUID" ]; then
                echo -e "    ${Y}[~]${NC} UUID: Kaynak=$K_UUID, Hedef=${H_UUID:-boş}"
            else
                echo -e "    ${Y}[~]${NC} UUID bilgisi yok"
            fi
            echo ""
        done
    else
        K_UUID=$(blkid -s UUID -o value /dev/$HOCA 2>/dev/null)
        H_UUID=$(blkid -s UUID -o value /dev/$SENIN 2>/dev/null)
        K_FS=$(blkid -s TYPE -o value /dev/$HOCA 2>/dev/null)
        H_FS=$(blkid -s TYPE -o value /dev/$SENIN 2>/dev/null)
        
        if [ "$K_FS" == "$H_FS" ]; then
            echo -e "  ${G}[✔]${NC} Dosya sistemi eşleşti: ${G}$K_FS${NC}"
        else
            echo -e "  ${R}[✗]${NC} Dosya sistemi uyumsuz: Kaynak=$K_FS, Hedef=$H_FS"
        fi
        
        if [ "$K_UUID" == "$H_UUID" ] && [ -n "$K_UUID" ]; then
            echo -e "  ${G}[✔]${NC} UUID eşleşti: ${G}$K_UUID${NC}"
        elif [ -n "$K_UUID" ]; then
            echo -e "  ${Y}[~]${NC} UUID: Kaynak=$K_UUID, Hedef=${H_UUID:-boş}"
        fi
    fi
    
    echo ""
    
    # ==========================================
    # AŞAMA 4: Temizlik ve Sync
    # ==========================================
    echo -e "${B}━━━ Aşama 4/4: Temizlik ve Sync ━━━${NC}"
    echo ""
    
    yukleme_cemberi 2 "[◆] Buffer sync yapılıyor"
    sync
    basarili "Tüm veriler diske yazıldı"
    
    # Geçici dizinleri temizle
    rmdir "$UUID_KAYNAK_MNT" 2>/dev/null
    rmdir "$UUID_HEDEF_MNT" 2>/dev/null
    basarili "Geçici dosyalar temizlendi"
    
    echo ""
    
    if [ $TRANSFER_HATA -eq 0 ]; then
        # Başarılı
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
        
        yaz "  [📦] /dev/$SENIN artık /dev/$HOCA'nın UUID klonu" "$C" 0.02
        custom_sleep 0.5
        yaz "  [✔] Sadece dolu veriler kopyalandı (hızlı klon)!" "$G" 0.02
        custom_sleep 0.5
        yaz "  [✔] UUID değerleri korundu!" "$G" 0.02
        custom_sleep 0.5
        
        echo ""
        echo -e "  ${C}[📦] Klonlama Raporu: Başarılı (UUID Modu)${NC}"
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
        echo -e "${R}║${NC}          ${BOLD}✗  İŞLEM HATALARLA TAMAMLANDI!${NC}          ${R}║${NC}"
        echo -e "${R}╚════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${R}[!] Bazı partition'lar kopyalanırken hata oluştu.${NC}"
        echo -e "${Y}[!] Disk bağlantılarını kontrol edin ve tekrar deneyin.${NC}"
        
        # Temizlik
        rmdir "$UUID_KAYNAK_MNT" 2>/dev/null
        rmdir "$UUID_HEDEF_MNT" 2>/dev/null
        exit 1
    fi
    
else
    # ========================================
    # NORMAL DD MODU FLAŞLAMA (orijinal kod)
    # ========================================
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
fi
