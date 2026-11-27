# Türkiye Open World — GTA tarzı yeniden yapım

Bu dal, mevcut prototipin üzerine ayrı bir yeniden yapım çalışmasıdır. Godot 4.3 ve Windows x64 hedeflenir.

## Bu sürümde yapılanlar
- Üçüncü şahıs kamera ve yumuşatılmış WASD hareketi.
- Koyu eşofman, açık renk şeritler, beyaz tişört, koyu saç ve birleşik kaş tasarımını koruyan, eklem noktalarından yürüyüş/koşu animasyonu alan karakter prototipi.
- Balkon, pencere, çatı parapeti ve su deposu ayrıntıları eklenmiş, çarpışma alanı olan apartman blokları.
- Yol çizgileri, yaya geçidi ve sokak lambaları.
- Farklı renklerde araç gövdeleri, camlar, farlar, stop lambaları ve tekerlek göbekleri.
- Basit görünümlü kapsüller yerine kıyafet/ten rengi çeşitliliği olan yürüyen yayalar.
- Uzak mesafe sisi ve sınırlandırılmış güneş gölgeleri.

## Kontroller
- WASD: yürü / araç sür
- Shift: koş
- Space: zıpla / araçta fren
- E: etkileşim / araca bin veya in
- Tab: envanter
- P: telefon
- M: harita
- F5 / F9: kaydet / yükle
- Esc: fareyi serbest bırak / yakala

## Önemli kalite notu
Bu hâlâ gerçek taranmış/riglenmiş AAA karakter ve şehir varlıkları içeren tamamlanmış bir GTA V eşdeğeri değildir. Karakter, yayalar, binalar ve araçlar şu an Godot içinde oluşturulan optimize edilmiş prototip modelleridir. Harici model eklenmeden önce lisans ve performans kontrolü yapılacaktır. Entegre GPU hedefi nedeniyle gerçekçi görünüm ile akıcılık arasında denge kurulmalıdır.

## Windows x64 derlemesi
GitHub Actions, `gta5-style-rebuild` dalına yapılan ilgili değişikliklerde otomatik olarak Godot 4.3 Windows x64 derlemesini başlatır. Başarılı derlemede Actions sayfasında ZIP artifact'i ve GitHub Release bulunur. Derleme başarıyla bitmeden EXE hazır kabul edilmemelidir.
