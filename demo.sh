#!/bin/bash

# Dil ayarını sabitle (Hesaplama hatalarını önler)
export LC_NUMERIC=C

# ========================================
# AYARLAR VE RENKLER
# ========================================
G='\033[0;32m'   # Yeşil
R='\033[0;31m'   # Kırmızı
C='\033[0;36m'   # Cyan
Y='\033[1;33m'   # Sarı
M='\033[0;35m'   # Mor
B='\033[1;34m'   # Mavi
W='\033[1;37m'   # Beyaz
BLINK='\033[5m'  # Yanıp Sönme
BOLD='\033[1m'   # Kalın
NC='\033[0m'     # Reset

# ========================================
# GİRİŞ - MOD SEÇİMİ
# ========================================
clear
echo -e "${M}╔═════════════════════════════════════════════════════╗${NC}"
echo -e "${M}║${NC}         ${BOLD}SİMÜLASYON MODU (DEMO) BAŞLATILIYOR${NC}         ${M}║${NC}"
echo -e "${M}╚═════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${W}Bu modda hiçbir gerçek disk silinmez, sadece görsel şovdur.${NC}"
echo ""
echo -e "${C}[Enter] : Animasyonlu Başlat${NC}"
echo -e "${C}[H]     : Hızlı Mod (Animasyonsuz)${NC}"
echo -ne "${Y}Seçiminiz: ${NC}"
read -r MOD_SECIM

if [[ "$MOD_SECIM" =~ ^[Hh] ]]; then
    HIZLI_MOD=1
else
    HIZLI_MOD=0
fi

# ========================================
# YARDIMCI FONKSİYONLAR
# ========================================

# Akıllı Sleep
custom_sleep() {
    if [ "$HIZLI_MOD" -eq 0 ]; then
        sleep "$1"
    fi
}

# Yazma Animasyonu (Renk korumalı)
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
    local sleep_time=$(awk "BEGIN {print $duration/$total_steps}" 2>/dev/null || echo "0.05")
    
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
        progress=$((progress + 2))
        sleep $sleep_time
    done
    echo ""
}

# Fake DD Progress (Gerçekçi görünüm)
fake_dd_progress() {
    local source=$1
    local target=$2
    local total_mb=4096 # 4GB simülasyonu
    
    echo -e "${C}[DEMO] Veri akışı başlatılıyor...${NC}"
    custom_sleep 1
    
    if [ "$HIZLI_MOD" -eq 1 ]; then
        echo -e "4294967296 bytes (4.3 GB, 4.0 GiB) copied, 5.2 s, 800 MB/s"
        return
    fi

    local copied_mb=0
    local start_time=$(date +%s)
    
    # 0'dan 100'e kadar sahte döngü
    for i in {1..100}; do
        copied_mb=$((copied_mb + 41)) # Her adımda 41MB artır
        local bytes=$((copied_mb * 1024 * 1024))
        local speed=$((RANDOM % 50 + 80)) # 80-130 MB/s arası rastgele hız
        local time_elapsed=$(awk "BEGIN {print $i/10}")
        
        # \r ile satır başı yapıp üzerine yazıyoruz (Gerçek DD gibi)
        printf "\r%d bytes (%d MB, %.1f GiB) copied, %.1f s, %d MB/s" "$bytes" "$copied_mb" "$(awk "BEGIN {print $copied_mb/1024}")" "$time_elapsed" "$speed"
        
        sleep 0.05
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

# Bekleme
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
            sleep 0.2
            echo -ne "\r${G}[${NC}${G}✔${NC}${G}]${NC} ${W}Bulundu   : ${NC}$item"
            echo ""
            sleep 0.1
        fi
    done
}

# İleri Butonu
ileri() {
    echo ""
    echo -e "${M}╔═════════════════════════════════════════════════════╗${NC}"
    echo -e "${M}║${NC}                                                     ${M}║${NC}"
    echo -ne "${M}║${NC}     "; yaz "▶▶▶ Devam etmek için ENTER'a bas ◀◀◀" "$BOLD$Y" 0.01
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
    sleep 0.4
    echo -ne "\r${G}[${NC}${G}✔${NC}${G}]${NC} $1"
    echo ""
    sleep 0.1
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

# Matrix Rain
matrix_rain() {
    if [ "$HIZLI_MOD" -eq 1 ]; then return; fi
    local lines=5
    for ((i=1; i<=lines; i++)); do
        local rand_text=$(cat /dev/urandom | tr -dc '01' | fold -w 60 | head -n 1 2>/dev/null || echo "101010101010101010101010101010")
        echo -e "${G}${rand_text}${NC}"
        sleep 0.05
    done
}

# ========================================
# SENARYO BAŞLIYOR
# ========================================
clear

# Demo Uyarısı
echo -e "${Y}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${Y}║                                                    ║${NC}"
echo -e "${Y}║         ${BLINK}${BOLD}🎬 DEMO MODU AKTİF 🎬${NC}                     ${Y}║${NC}"
echo -e "${Y}║                                                    ║${NC}"
echo -e "${Y}║  ${W}Bu modda komutlar çalıştırılmaz.                ${Y}║${NC}"
echo -e "${Y}║  ${W}Sadece görsel arayüz test edilir.               ${Y}║${NC}"
echo -e "${Y}║                                                    ║${NC}"
echo -e "${Y}╚════════════════════════════════════════════════════╝${NC}"
custom_sleep 2
echo ""
yaz "Simülasyon başlatılıyor..." "$W" 0.05
echo ""

# Matrix Animasyonu
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

echo -e "${Y}                    [🎬 DEMO MODE 🎬]${NC}"
custom_sleep 0.3

yukleme_cemberi 2 "Sistem başlatılıyor"
echo ""
yaz "                    by YAŞAR EFE" "$W" 0.03
custom_sleep 0.3
yaz "              [USB Klonlama Sistemi v2.0 - DEMO]" "$C" 0.03
echo ""
custom_sleep 0.5

yildiz_patlat "Hoş Geldin!"

echo -e "${W}Bu araç, bir USB'yi diğerine BİREBİR kopyalar.${NC}"
custom_sleep 0.5
echo -e "${Y}⚠️  ${BLINK}DEMO MODUNDA HİÇBİR VERİ SİLİNMEZ!${NC}"
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

yaz "[⚙]  Sistem bileşenleri taranıyor... (DEMO)" "$W" 0.03
echo ""
custom_sleep 1

scan_anim "Kernel Modülleri" "Disk Araçları" "I/O Sistemleri" "Buffer Yöneticisi"

echo ""
progress_bar 2 "[●] Araç uyumluluğu test ediliyor"
echo ""

basarili "lsblk modülü aktif (simülasyon)"
basarili "dd transfer motoru hazır (simülasyon)"
basarili "Hesaplama motoru çevrimiçi (simülasyon)"

echo ""
yukleme_cemberi 2 "[✓] Son kontroller yapılıyor"

yildiz_patlat "Tüm sistemler operasyonel!"

ileri

# ========================================
# ADIM 2: DISK TESPİTİ (FAKE)
# ========================================
clear
echo -e "${B}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${B}║${NC}  ${BOLD}${W}ADIM 2/5: DISK TESPİTİ (DEMO)${NC}                   ${B}║${NC}"
echo -e "${B}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[🔍] Tüm depolama cihazları taranıyor... (DEMO)" "$W" 0.03
bekle 2 20
echo ""

progress_bar 3 "[●] Blok cihazları analiz ediliyor"
echo ""
custom_sleep 0.5

echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${C}│${NC} ${BOLD}${W}Tespit Edilen Diskler (DEMO - Sahte Veri):${NC}        ${C}│${NC}"
echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"
echo ""
custom_sleep 0.3

echo -e "${Y}[ℹ] OS diski: ${R}/dev/sda${Y} (bu listeye dahil değil)${NC}"
echo ""

# FAKE DISK LİSTESİ (Profesyonel lsblk formatı)
echo " 1. sdb      3.8G  SanDisk_Cruzer"
echo " 2. sdc     14.9G  Kingston_DT100"
echo " 3. sdd       32G  Toshiba_TransMemory"

echo ""
custom_sleep 0.5
echo -e "${Y}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${Y}│${NC} ${BOLD}Hedef Belirleme Protokolü${NC}                         ${Y}│${NC}"
echo -e "${Y}└─────────────────────────────────────────────────────┘${NC}"
custom_sleep 0.3

echo ""
# Kullanıcıdan fake input alıyoruz ama sonucu biz belirliyoruz
echo -ne "${C}➤${NC} ${W}KAYNAK disk numarası (kopyalanacak): ${NC}"
if [ "$HIZLI_MOD" -eq 1 ]; then echo "1"; else read -r FAKE_INPUT_1; fi
custom_sleep 0.5

echo -ne "${C}➤${NC} ${W}HEDEF disk numarası (üzerine yazılacak): ${NC}"
if [ "$HIZLI_MOD" -eq 1 ]; then echo "2"; else read -r FAKE_INPUT_2; fi
custom_sleep 0.5

# Demo için hardcoded değerler
HOCA="sdb"
SENIN="sdc"

echo ""
yukleme_cemberi 2 "[◆] Seçimler doğrulanıyor"
echo ""
progress_bar 2 "[●] Hedef kilitleniyor"
echo ""

basarili "Kaynak tespit edildi: /dev/$HOCA (DEMO)"
basarili "Hedef kilitlendi: /dev/$SENIN (DEMO)"

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

yaz "[📋] İşlem parametreleri derleniyor... (DEMO)" "$W" 0.03
bekle 2 15
echo ""

echo -e "${C}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${C}│${NC} ${BOLD}${W}Transfer Matrisi:${NC}                                 ${C}│${NC}"
echo -e "${C}└─────────────────────────────────────────────────────┘${NC}"
custom_sleep 0.3
echo ""
echo -e "  ${C}Kaynak Cihaz:${NC} ${G}/dev/$HOCA (3.8 GB)${NC}"
custom_sleep 0.3
echo -e "  ${C}Hedef Cihaz :${NC} ${R}/dev/$SENIN (14.9 GB)${NC}"
custom_sleep 0.5
echo ""

if [ "$HIZLI_MOD" -eq 0 ]; then
    for i in {3..1}; do
        echo -ne "${Y}[!] Uyarı gösteriliyor... ${i}${NC}\r"
        sleep 1
    done
fi
echo ""

echo -e "${Y}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${Y}║                                                    ║${NC}"
echo -e "${Y}║${NC}  ${BOLD}⚠️  DEMO UYARI ⚠️${NC}                                 ${Y}║${NC}"
echo -e "${Y}║                                                    ║${NC}"
echo -e "${Y}║${NC}    ${W}Normal modda /dev/$SENIN üzerindeki${NC}             ${Y}║${NC}"
echo -e "${Y}║${NC}    ${W}TÜM VERİLER silinirdi!${NC}                        ${Y}║${NC}"
echo -e "${Y}║                                                    ║${NC}"
echo -e "${Y}║${NC}    ${G}Ama bu DEMO - hiçbir şey silinmez 😊${NC}          ${Y}║${NC}"
echo -e "${Y}║                                                    ║${NC}"
echo -e "${Y}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 1

echo -e "${C}Demo modunda otomatik onay veriliyor...${NC}"
custom_sleep 1
echo ""
basarili "Güvenlik onayı alındı (DEMO)"
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
echo -e "${B}║${NC}  ${BOLD}${W}ADIM 4/5: SİSTEM HAZIRLIK AŞAMASI (DEMO)${NC}         ${B}║${NC}"
echo -e "${B}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[🔧] Hedef disk hazırlanıyor... (Simülasyon)" "$W" 0.03
echo ""
custom_sleep 1

progress_bar 3 "[●] Bağlı sistemler analiz ediliyor"
echo ""

yukleme_cemberi 2 "[◆] Mount noktaları kapatılıyor"
basarili "Tüm mount noktaları kaldırıldı (simülasyon)"

echo ""
progress_bar 2 "[●] Disk buffer temizleniyor"
echo ""

yukleme_cemberi 2 "[◆] Kernel buffer sync ediliyor"
basarili "Kernel buffer temizlendi (simülasyon)"

echo ""
progress_bar 2 "[●] I/O kuyruğu optimize ediliyor"
echo ""

yukleme_cemberi 1 "[◆] DMA kanalları açılıyor"
basarili "DMA transfer modu aktif (simülasyon)"

echo ""
yildiz_patlat "Hedef disk transfer için hazır!"

ileri

# ========================================
# ADIM 5: FLAŞLAMA (FAKE)
# ========================================
clear
echo -e "${G}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${G}║${NC}  ${BOLD}${W}ADIM 5/5: FLAŞLAMA OPERASYONU (DEMO)${NC}             ${G}║${NC}"
echo -e "${G}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 0.5

yaz "[🚀] Transfer motoru çalıştırılıyor... (Simülasyon)" "$W" 0.03
bekle 2 20
echo ""

yukleme_cemberi 3 "[◆] Veri transferi başlatılıyor"
echo ""

echo -e "${M}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${M}│${NC} ${BOLD}${W}Gerçek Zamanlı Transfer İzleme (DEMO):${NC}            ${M}│${NC}"
echo -e "${M}└─────────────────────────────────────────────────────┘${NC}"
echo ""
custom_sleep 1

echo -e "${C}[●] Transfer başladı... (Simüle DD Progress)${NC}"
echo ""

# FAKE DD İŞLEMİ
fake_dd_progress "/dev/$HOCA" "/dev/$SENIN"

echo ""
echo ""
yukleme_cemberi 3 "[◆] Transfer tamamlandı, doğrulanıyor"
echo ""

progress_bar 3 "[●] Veri bütünlüğü kontrol ediliyor (simülasyon)"
echo ""

yukleme_cemberi 2 "[◆] Buffer sync yapılıyor (simülasyon)"
basarili "Tüm veriler diske yazıldı (simülasyon)"

echo ""
custom_sleep 1

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
echo -e "${G}║${NC}       ${BOLD}${BLINK}✔  DEMO BAŞARIYLA TAMAMLANDI!  ✔${NC}           ${G}║${NC}"
echo -e "${G}║                                                    ║${NC}"
echo -e "${G}║                                                    ║${NC}"
echo -e "${G}╚════════════════════════════════════════════════════╝${NC}"
echo ""
custom_sleep 1

if [ "$HIZLI_MOD" -eq 0 ]; then
    # Başarı yıldızları
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
custom_sleep 0.5

echo -e "${Y}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${Y}║           🎬 DEMO MODU BİLGİLENDİRME 🎬            ║${NC}"
echo -e "${Y}╚════════════════════════════════════════════════════╝${NC}"
echo ""
yaz "  [📦] Bu bir simülasyondu - hiçbir disk değişmedi" "$C" 0.02
custom_sleep 0.5
yaz "  [✔] Gerçek versiyonda /dev/$SENIN kopyalanırdı" "$G" 0.02
custom_sleep 0.5
yaz "  [ℹ] Gerçek script için normal modu kullan" "$W" 0.02
custom_sleep 0.5
echo ""
echo -e "${M}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${M}│${NC}                                                     ${M}│${NC}"
echo -ne "${M}│${NC}  "; yaz "Demo izlediğin için teşekkürler Yaşar Efe! 🎬" "$Y$BOLD" 0.03;
echo -e "${M}│${NC}                                                     ${M}│${NC}"
echo -e "${M}└─────────────────────────────────────────────────────┘${NC}"
echo ""
