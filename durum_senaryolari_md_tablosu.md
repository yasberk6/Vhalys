
| Senaryo ID | Senaryo Adı | Ana Aktör | Ön Koşullar | Hedef Şartlar | Ana Başarı Senaryosu | Genişlemeler |
|------------|-------------|-----------|-------------|---------------|-----------------------|--------------|
| YB1 | Giriş Yapma | Kullanıcı | Kullanıcının daha önceden sisteme kayıtlı olması gerekir. | Kullanıcı sisteme başarılı şekilde giriş yapar ve hizmetlere erişim kazanır. | 1. Kullanıcı uygulamayı açar.  
2. Giriş ekranında kullanıcı adı ve şifresini girer.  
3. “Giriş Yap” butonuna tıklar.  
4. Sistem kimlik bilgilerini doğrular.  
5. Kullanıcı başarılı şekilde giriş yapar ve ana sayfaya yönlendirilir. | **3a: Giriş Başarısız**  
- Kullanıcı adı veya şifre yanlışsa uyarı gösterilir.  
- Kullanıcı yeniden giriş yapmaya yönlendirilir.  
**4a: Sistem Hatası**  
- Sistem geçici olarak yanıt veremiyorsa kullanıcıya bilgi verilir.  
- Kullanıcı daha sonra tekrar denemesi istenir. |
| YB2 | Üye Olma | Kullanıcı | Kullanıcının sisteme daha önceden kayıt olmamış olması gerekir. | Kullanıcı sisteme kayıt olur ve giriş yapmaya hazır hale gelir. | 1. Kullanıcı uygulamayı açar.  
2. Kayıt ol ekranına gider.  
3. Gerekli bilgileri (ad, e-posta, şifre vb.) doldurur.  
4. “Üye Ol” butonuna tıklar.  
5. Sistem kullanıcıyı kaydeder ve onay mesajı gösterir. | **3a: Eksik bilgi girildi**  
- Kullanıcıya eksik alanlar uyarısı verilir.  
- Eksik alanların doldurulması istenir.  
**4a: E-posta zaten kayıtlı**  
- Kullanıcıya 'Bu e-posta ile daha önce kayıt olunmuş' uyarısı gösterilir. |
| YB3 | Fikir Ekleme | Kullanıcı | Kullanıcının sisteme giriş yapmış olması gerekir. | Kullanıcı başarılı şekilde yeni bir fikir ekler. | 1. Kullanıcı fikir ekleme sayfasına gider.  
2. Fikir başlığı ve içeriğini girer.  
3. Kategori seçer ve isteğe bağlı medya ekler.  
4. “Fikri Paylaş” butonuna tıklar.  
5. Fikir Firestore'a kaydedilir. | **2a: Başlık veya içerik boş**  
- Kullanıcıya zorunlu alanların doldurulması gerektiği bildirilir. |
| YB4 | Fikir Listeleme | Kullanıcı | Fikirlerin sistemde mevcut olması gerekir. | Kullanıcı fikirleri kriterlere göre listeleyerek görüntüler. | 1. Kullanıcı fikirler sayfasına gider.  
2. Kategori, tarih veya popülerlik filtresi uygular.  
3. Filtreye göre fikirler listelenir. | - |
| YB5 | Fikir Güncelleme ve Silme | Kullanıcı | Kullanıcı sisteme giriş yapmış ve fikir sahibi olmalıdır. | Kullanıcı sadece kendi fikirlerini günceller veya siler. | 1. Kullanıcı fikirlerim sayfasına gider.  
2. Düzenlemek veya silmek istediği fikri seçer.  
3. Güncelleme veya silme işlemini gerçekleştirir. | **2a: Başka kullanıcı fikrine müdahale**  
- Yetkisiz işlem uyarısı gösterilir. |
| YB6 | Yorum Ekleme | Kullanıcı | Kullanıcı sisteme giriş yapmış olmalıdır. | Kullanıcı bir fikre yorum ekler. | 1. Kullanıcı yorum yapmak istediği fikir sayfasına gider.  
2. Yorum alanına yazı girer.  
3. Yorumu gönderir.  
4. Yorum ilgili fikirle ilişkilendirilerek Firestore'a kaydedilir. | **2a: Yorum alanı boş**  
- Yorum girilmediği için işlem iptal edilir. |
| YB7 | Yorum Listeleme | Kullanıcı | Yorumların daha önceden yapılmış olması gerekir. | Kullanıcı yorumları görüntüler. | 1. Kullanıcı bir fikir detayına girer.  
2. Yorumlar fikirle birlikte gösterilir.  
3. Yorumlar tarihe veya popülerliğe göre sıralanabilir. | - |
| YB8 | Yorum Güncelleme ve Silme | Kullanıcı | Kullanıcının yorum sahibi olması ve giriş yapmış olması gerekir. | Kullanıcı yalnızca kendi yorumunu günceller veya siler. | 1. Kullanıcı kendi yorumlarını açar.  
2. Düzenle veya sil seçeneğini kullanır.  
3. Yorum güncellenir veya silinir. | **2a: Başkasının yorumuna müdahale**  
- Yetkisiz işlem uyarısı gösterilir. |
| YB9 | Beğeni İşlemi | Kullanıcı | Kullanıcı giriş yapmış olmalıdır. | Kullanıcı fikir veya yorumu beğenir. | 1. Kullanıcı fikir veya yorum detayına girer.  
2. Beğen butonuna tıklar.  
3. Beğeni sayısı artar ve veritabanına kaydedilir. | - |
| YB10 | Kategori Seçimi | Kullanıcı | Kullanıcının fikir listesine ulaşması gerekir. | Kullanıcı belirli kategorideki fikirleri listeler. | 1. Kullanıcı kategori seçme alanına tıklar.  
2. İlgili kategori seçilir.  
3. Seçilen kategoriye ait fikirler listelenir. | - |
| YB11 | Popüler Fikirleri Listeleme | Kullanıcı | Fikirlerin beğeni ve yorum sayılarının sistemde kayıtlı olması gerekir. | Kullanıcı en çok beğenilen veya yorumlanan fikirleri görüntüler. | 1. Kullanıcı popüler fikirler sekmesine tıklar.  
2. Sistem en popüler fikirleri sıralar.  
3. Fikirler kullanıcıya sunulur. | - |
