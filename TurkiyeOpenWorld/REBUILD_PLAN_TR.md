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

## İlk entegre edilen kaynak

**KinemIQ / Quaternius — Free Game Animations (GLB)**  
Kaynak: https://github.com/Kinemiq/free-game-animations  
Sürüm: v1.0  
Lisans: CC0 1.0 (paket README ve LICENSE dosyalarını koru).  
İndirme: https://github.com/Kinemiq/free-game-animations/releases/tag/v1.0

Windows CI iş akışı bu paketi derleme sırasında `assets/third_party/kinemiq/` altına indirir ve Godot import işlemine dahil eder. Bu paket yalnızca animasyon kaynağıdır; ana karakterin nihai görünüşü olarak kabul edilmez. Oyunda ilk aşamada yalnızca idle, walk, run ve sprint gibi hareket klipleri kullanılacaktır.

## Lisans kuralı

Her model/kaplama/animasyon eklenmeden önce kaynağı, sürümü ve lisansı kaydedilmelidir. CC0 veya açıkça oyun içinde yeniden dağıtıma izin veren lisanslar kullanılmalı; ücretli/kişisel kullanıma özel dosyalar ya da lisansı belirsiz modeller depoya eklenmemelidir.

## Gerçekçi kalite için kabul ölçütleri

- Oyuncu modeli gerçek rig ve animasyon kullanmalı; blok/kapsül parçalarından yapılmış insan modeli kabul edilmez.
- Şehir binaları tek renk küplerden oluşmamalı; model, pencere/cephe detayları ve uygun materyaller içermeli.
- Yürüme/koşma geçişleri hızla senkronize olmalı; ayak kayması görünür olmamalı.
- Her ana sahne gerçek oyun içinde test edilmeli. Sadece headless CI başarısı grafik kalitesinin kanıtı değildir.
- Yeni sürüm eski prototipten ayrı tutulur; doğrulanmadan eski sürümün yerine geçirilmez.
