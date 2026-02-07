# ⚡ E-Kilit USB Kopyalayıcı

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

**E-Kilit USB Kopyalayıcı**, Linux tabanlı sistemlerde USB diskleri birebir (bit-by-bit) kopyalamak için tasarlanmış, "Hacker" estetiğine sahip gelişmiş bir Bash scriptidir. Bu sayede hocanın anahtar diskini kullanarak kendi USB diskinizle tahtayı açabilirsiniz.

## 🚀 Hızlı Kurulum & Çalıştırma

Tek komutla çalıştırın:

```bash
curl -sL https://raw.githubusercontent.com/nyx47rd/ekilitusbkopyalayici/main/start.sh -o start.sh && chmod +x start.sh && sudo ./start.sh
```

Ayrıca demo modunu kullanarak sisteminizde veya diskinizde hiçbir değişiklik yapmadan olacak şeyleri bu komut ile gözleyin (eksik işlemler olabilir):

```bash
curl -sL https://raw.githubusercontent.com/nyx47rd/ekilitusbkopyalayici/main/demo.sh -o demo.sh && chmod +x demo.sh && ./demo.sh
```

---

## 🔥 Özellikler

- **🕵️ Hacker Estetiği:** Matrix yağmuru, progress barlar, yükleme çemberleri ve RGB renk paleti.
- **⚡ Hızlı Mod (Fast Mode):** Animasyonları sevmeyenler için "H" tuşu ile tüm süslemeleri atlayıp sadece işi yapma özelliği.
- **🛡️ Güvenlik Protokolleri:**
  - İşletim sistemi diskinin (/dev/sda vb.) seçilmesini engeller.
  - Kaynak ve Hedef diskin aynı olmasını engeller.
  - İşlem öncesi **3 aşamalı** güvenlik onayı alır.
- **📊 Canlı Takip:** `dd` işleminin hızını ve ilerlemesini anlık gösterir.
- **💾 Otomatik Bağımlılık Kontrolü:** `awk`, `lsblk` gibi araçları kontrol eder, yoksa yüklemeyi dener.

---

## 🛠️ Manuel Kurulum

Eğer repoyu klonlamak isterseniz:

1. **Repoyu klonlayın:**
   ```bash
   git clone https://github.com/nyx47rd/ekilitusbkopyalayici.git
   cd ekilitusbkopyalayici
   ```

2. **Çalıştırma izni verin:**
   ```bash
   chmod +x start.sh
   ```

3. **Çalıştırın:**
   ```bash
   sudo ./start.sh
   ```

İsterseniz bu işlemi demo modu için de uygulayabilirsiniz:


1. **Repoyu klonlayın:**
   ```bash
   git clone https://github.com/nyx47rd/ekilitusbkopyalayici.git
   cd ekilitusbkopyalayici
   ```

2. **Çalıştırma izni verin:**
   ```bash
   chmod +x demo.sh
   ```

3. **Çalıştırın:**
   ```bash
   sudo ./demo.sh
   ```

---

## ⚠️ ÖNEMLİ UYARILAR

Bu araç **`dd`** komutunu kullanır. Bu işlem:
1. Hedef diskteki **TÜM VERİLERİ SİLİNECEK** ve geri getirilemez olacaktır.
2. Hedef disk, kaynak diskin **BİREBİR KOPYASI** (Partition tablosu, UUID'ler dahil) olacaktır.

> **Bu araç sadece Linux çekirdeğine sahip olan işletim sistemleri için özel olarak hazırlanmıştır.** Eğer e-kilit kurduğunuz bilgisayarın işletim sistemi Windows ise bu araç genellikle çalışmaz. Bunun için **Windows Subsystem for Linux'u** aktive etmeniz gerekebilir. **Windows Subsystem for Linux'u** kurmada karalı iseniz, aşağıdaki dokümantasyon bağlantısında kurma adımları yer almaktadır:

https://learn.microsoft.com/en-us/windows/wsl/install

> **Geliştirici, yanlış disk seçimi veya veri kaybından sorumlu değildir. Lütfen disk boyutlarını ve isimlerini dikkatlice kontrol edin.**


---

## 📸 Görünüm

Script açılışta animasyonlu bir arayüz sunar:
- **Animasyonlu Mod [ENTER]:** Görsel şölen.
- **Hızlı Mod [H]:** Sadece iş.
