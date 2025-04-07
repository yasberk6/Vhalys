# Durum Senaryoları

| Senaryo ID | YB1 |
| Senaryo Adı | Giriş Yapma |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcının daha önceden sisteme kayıtlı olması gerekir. |
| Hedef Şartlar | Kullanıcı sisteme başarılı şekilde giriş yapar ve hizmetlere erişim kazanır. |
| Ana Başarı Senaryosu | 1.Kullanıcı uygulamayı açar.
2.Giriş ekranında kullanıcı adı ve şifresini girer.
3.“Giriş Yap” butonuna tıklar.
4.Sistem kimlik bilgilerini doğrular.
5.Kullanıcı başarılı şekilde giriş yapar ve ana sayfaya yönlendirilir. |
| Genişlemeler | 3a: Giriş Başarısız
    1. Kullanıcı adı veya şifre yanlışsa uyarı gösterilir.
    2. Kullanıcı yeniden giriş yapmaya yönlendirilir.
4a: Sistem Hatası
    1. Sistem geçici olarak yanıt veremiyorsa kullanıcıya bilgi verilir.
    2. Kullanıcı daha sonra tekrar denemesi istenir. |

| Senaryo ID | YB2 |
| Senaryo Adı | Üye Olma |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcının sisteme daha önceden kayıt olmamış olması gerekir. |
| Hedef Şartlar | Kullanıcı sisteme kayıt olur ve giriş yapmaya hazır hale gelir. |
| Ana Başarı Senaryosu | 1.Kullanıcı uygulamayı açar.
2.Kayıt ol ekranına gider.
3.Gerekli bilgileri (ad, e-posta, şifre vb.) doldurur.
4.“Üye Ol” butonuna tıklar.
5.Sistem kullanıcıyı kaydeder ve onay mesajı gösterir. |
| Genişlemeler | 3a: Eksik bilgi girildi
    1. Kullanıcıya eksik alanlar uyarısı verilir.
    2. Eksik alanların doldurulması istenir.
4a: E-posta zaten kayıtlı
    1. Kullanıcıya 'Bu e-posta ile daha önce kayıt olunmuş' uyarısı gösterilir. |

| Senaryo ID | YB3 |
| Senaryo Adı | Fikir Ekleme |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcının sisteme giriş yapmış olması gerekir. |
| Hedef Şartlar | Kullanıcı başarılı şekilde yeni bir fikir ekler. |
| Ana Başarı Senaryosu | 1.Kullanıcı fikir ekleme sayfasına gider.
2.Fikir başlığı ve içeriğini girer.
3.Kategori seçer ve isteğe bağlı medya ekler.
4.“Fikri Paylaş” butonuna tıklar.
5.Fikir Firestore'a kaydedilir. |
| Genişlemeler | 2a: Başlık veya içerik boş
    1. Kullanıcıya zorunlu alanların doldurulması gerektiği bildirilir. |

| Senaryo ID | YB4 |
| Senaryo Adı | Fikir Listeleme |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Fikirlerin sistemde mevcut olması gerekir. |
| Hedef Şartlar | Kullanıcı fikirleri kriterlere göre listeleyerek görüntüler. |
| Ana Başarı Senaryosu | 1.Kullanıcı fikirler sayfasına gider.
2.Kategori, tarih veya popülerlik filtresi uygular.
3.Filtreye göre fikirler listelenir. |
| Genişlemeler | - |

| Senaryo ID | YB5 |
| Senaryo Adı | Fikir Güncelleme ve Silme |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcı sisteme giriş yapmış ve fikir sahibi olmalıdır. |
| Hedef Şartlar | Kullanıcı sadece kendi fikirlerini günceller veya siler. |
| Ana Başarı Senaryosu | 1.Kullanıcı fikirlerim sayfasına gider.
2.Düzenlemek veya silmek istediği fikri seçer.
3.Güncelleme veya silme işlemini gerçekleştirir. |
| Genişlemeler | 2a: Başka kullanıcı fikrine müdahale
    1. Yetkisiz işlem uyarısı gösterilir. |

| Senaryo ID | YB6 |
| Senaryo Adı | Yorum Ekleme |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcı sisteme giriş yapmış olmalıdır. |
| Hedef Şartlar | Kullanıcı bir fikre yorum ekler. |
| Ana Başarı Senaryosu | 1.Kullanıcı yorum yapmak istediği fikir sayfasına gider.
2.Yorum alanına yazı girer.
3.Yorumu gönderir.
4.Yorum ilgili fikirle ilişkilendirilerek Firestore'a kaydedilir. |
| Genişlemeler | 2a: Yorum alanı boş
    1. Yorum girilmediği için işlem iptal edilir. |

| Senaryo ID | YB7 |
| Senaryo Adı | Yorum Listeleme |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Yorumların daha önceden yapılmış olması gerekir. |
| Hedef Şartlar | Kullanıcı yorumları görüntüler. |
| Ana Başarı Senaryosu | 1.Kullanıcı bir fikir detayına girer.
2.Yorumlar fikirle birlikte gösterilir.
3.Yorumlar tarihe veya popülerliğe göre sıralanabilir. |
| Genişlemeler | - |

| Senaryo ID | YB8 |
| Senaryo Adı | Yorum Güncelleme ve Silme |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcının yorum sahibi olması ve giriş yapmış olması gerekir. |
| Hedef Şartlar | Kullanıcı yalnızca kendi yorumunu günceller veya siler. |
| Ana Başarı Senaryosu | 1.Kullanıcı kendi yorumlarını açar.
2.Düzenle veya sil seçeneğini kullanır.
3.Yorum güncellenir veya silinir. |
| Genişlemeler | 2a: Başkasının yorumuna müdahale
    1. Yetkisiz işlem uyarısı gösterilir. |

| Senaryo ID | YB9 |
| Senaryo Adı | Beğeni İşlemi |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcı giriş yapmış olmalıdır. |
| Hedef Şartlar | Kullanıcı fikir veya yorumu beğenir. |
| Ana Başarı Senaryosu | 1.Kullanıcı fikir veya yorum detayına girer.
2.Beğen butonuna tıklar.
3.Beğeni sayısı artar ve veritabanına kaydedilir. |
| Genişlemeler | - |

| Senaryo ID | YB10 |
| Senaryo Adı | Kategori Seçimi |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Kullanıcının fikir listesine ulaşması gerekir. |
| Hedef Şartlar | Kullanıcı belirli kategorideki fikirleri listeler. |
| Ana Başarı Senaryosu | 1.Kullanıcı kategori seçme alanına tıklar.
2.İlgili kategori seçilir.
3.Seçilen kategoriye ait fikirler listelenir. |
| Genişlemeler | - |

| Senaryo ID | YB11 |
| Senaryo Adı | Popüler Fikirleri Listeleme |
| Ana Aktör | Kullanıcı |
| Ön Koşullar | Fikirlerin beğeni ve yorum sayılarının sistemde kayıtlı olması gerekir. |
| Hedef Şartlar | Kullanıcı en çok beğenilen veya yorumlanan fikirleri görüntüler. |
| Ana Başarı Senaryosu | 1.Kullanıcı popüler fikirler sekmesine tıklar.
2.Sistem en popüler fikirleri sıralar.
3.Fikirler kullanıcıya sunulur. |
| Genişlemeler | - |
