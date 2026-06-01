# 🎓 OdakSınıf

**Butik Eğitim Kurumları İçin Yeni Nesil İletişim Platformu**

OdakSınıf, butik dershaneler ve özel eğitim kurumları için tasarlanmış, karmaşadan uzak ve eğitim odaklı bir mesajlaşma platformudur. Geleneksel anlık mesajlaşma uygulamalarının (WhatsApp, Telegram) yarattığı bilgi kirliliğini önlemek ve dijital sınıf yönetimini güvenli bir çatı altında toplamak amacıyla geliştirilmiştir.

## 🚀 Öne Çıkan Özellikler

* **Güvenli Erişim (Allowed Emails):** Sadece kurum tarafından e-posta adresi yetkilendirilmiş öğrenciler topluluğa katılabilir. Yabancı girişler tamamen engellenir.
* **Kategorize Edilmiş İletişim:** Derslere, şubelere veya konulara özel alt kanallar oluşturularak sohbet akışı düzenli tutulabilir.
* **Duyuru (Salt Okunur) Modu:** Yöneticiler, kanalları "Sadece Yöneticiler Yazabilir" formatına çevirerek kritik bilgilerin sohbet kalabalığında kaybolmasını önleyebilir.
* **Zengin Medya Paylaşımı:** Sistem performansını korumak amacıyla 500 KB limitli, hızlı ve güvenli dosya/görsel paylaşımı (Base64 Encode) altyapısı mevcuttur.
* **Gelişmiş Moderasyon:** Kurucu yetkisine sahip öğretmenler, kanal akışını bozan herhangi bir mesajı tüm sistemden kalıcı olarak silebilir (Real-time update).

## 🛠️ Kullanılan Teknolojiler ve Mimari

* **İstemci (Frontend):** Flutter (Dart)
* **Arka Uç (Backend):** Firebase (Authentication, Cloud Firestore)
* **Mimari Yaklaşım:** BaaS (Backend as a Service) & Sunucusuz (Serverless) Altyapı

## 📦 Kurulum ve Canlı Test

> **⚠️ Önemli Not:** Projenin derlenmiş test edilebilir `app-release.apk` dosyası teslim tarihinden önce bu ana dizine eklenecektir.

Projeyi yerel geliştirme ortamınızda (Localhost) çalıştırmak için aşağıdaki adımları izleyebilirsiniz:

1. Repoyu bilgisayarınıza klonlayın:
`git clone https://github.com/Fatihkenan/yazilimMuhendisligiProje`

2. Gerekli Flutter paketlerini indirin:
`flutter pub get`

3. Projeyi derleyip başlatın:
`flutter run`

## 👨‍💻 Geliştirici Ekip

Bu proje, İstanbul Gedik Üniversitesi Bilgisayar Mühendisliği Bölümü "Yazılım Mühendisliği" dersi kapsamında aşağıdaki çevik (Agile/Scrum) takım tarafından geliştirilmiştir:

* **Fatih Kenan Kaya** - Scrum Master & Developer
* **Saib** - Product Owner & Developer
* **Belal** - Developer
