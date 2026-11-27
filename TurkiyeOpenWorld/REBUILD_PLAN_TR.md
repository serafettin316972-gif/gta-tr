# GTA TR — Yeni grafik altyapısı (Türkçe)

Bu dal, mevcut prototipi bozmadan GTA V seviyesinde bir görsel hedefe doğru ayrı bir yeniden yapım çalışmasıdır. Şu an **tamamlanmış bir GTA V kalitesinde oyun değildir**; bu dosya ilk gerçek varlık entegrasyonu adımını belgeler.

## Hedef

- Godot 4.x, Windows x64.
- Hedef makine: Intel Core i7-8700T ve dahili GPU sınıfında donanım; kalite/perf seçenekleri.
- İnsan karakteri: gerçek rig'li 3D model, idle/walk/run animasyonları; prosedürel kapsül/box karakter kullanılmayacak.
- Kamera: üçüncü şahıs, yumuşak takip, duvar engel kontrolü.
- Şehir: modüler, gerçek 3D bina/prop modelleri, PBR materyaller, yol/kaldırım detayları.
- Araçlar: lisansı doğrulanmış 3D araç modelleri ve tekerlek/süspansiyon animasyonu.
- Optimizasyon: LOD, görünürlük menzili, occlusion, sınırlı gerçek zamanlı gölge ve ölçeklenebilir render ayarları.

## Varlık entegrasyonu

Bu ilk aşamada henüz harici karakter veya şehir modeli depoya eklenmedi. Yalnızca açık lisanslı, oyunda yeniden dağıtıma izin veren ve bu oyunun ihtiyaçlarıyla doğrudan ilgili olan insan karakteri, hareket animasyonu, şehir ve araç varlıkları seçilecek. Her dosya eklenmeden önce lisans ve gerçek oyun içi uyumluluk kontrol edilecek.

## Lisans kuralı

Her model/kaplama/animasyon eklenmeden önce kaynağı, sürümü ve lisansı kaydedilmelidir. CC0 veya açıkça oyun içinde yeniden dağıtıma izin veren lisanslar kullanılmalı; ücretli/kişisel kullanıma özel dosyalar ya da lisansı belirsiz modeller depoya eklenmemelidir.

## Gerçekçi kalite için kabul ölçütleri

- Oyuncu modeli gerçek rig ve animasyon kullanmalı; blok/kapsül parçalarından yapılmış insan modeli kabul edilmez.
- Şehir binaları tek renk küplerden oluşmamalı; model, pencere/cephe detayları ve uygun materyaller içermeli.
- Yürüme/koşma geçişleri hızla senkronize olmalı; ayak kayması görünür olmamalı.
- Her ana sahne gerçek oyun içinde test edilmeli. Sadece headless CI başarısı grafik kalitesinin kanıtı değildir.
- Yeni sürüm eski prototipten ayrı tutulur; doğrulanmadan eski sürümün yerine geçirilmez.
