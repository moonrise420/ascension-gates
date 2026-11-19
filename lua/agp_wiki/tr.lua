-- Ascension Gates help (wiki), Türkçe. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Yardım",
    search = "Ara...",
    size = "Yazı boyutu",
    short = "KISACA",
    intro = "Ascension Gates hakkında her şey: parçalar ne yapar ve onları nasıl kullanırsın.",
    open = "Yardımı aç",
},
pages = {

{ id = "start", title = "Buradan başla", icon = "icon16/star.png", body = [[
= Ascension Gates bir Stargate paketidir: kapılar, halkalar, gemiler, silahlar, kalkanlar ve enerji. Bu yardım her parçayı kısa adımlarla anlatır.
# Her şey nerede
- **Eşya oluştur:** [Q] tuşuna bas, **Ascension Gates** sekmesi (sol üstte). Kategoriler solda.
- **Araçlar:** [Q], sağ taraf, **Ascension Gates** sekmesi (Stargate'ler, kapılar, silahlar, anahtarlar) ve **PowerGrid** sekmesi (enerji, güç, yaşam desteği).
- **Ayarlar:** [Q] > Ascension Gates > Config. Gemi ayarları: **AGP gemileri**.
- **Enerji ve yaşam desteği ayarları:** [Q] > PowerGrid > Ayarlar > **PowerGrid**.
- **Bu yardım:** konsol komutu **agp_wiki** veya [Q] > Ascension Gates > Config > **Yardım (Wiki)**.
# İlk adımlar
1. [Q] tuşuna bas ve **Ascension Gates** sekmesini aç.
2. İki Stargate ve bir DHD oluştur (kategori **Stargate ve Halkalar**).
3. DHD'ye bak ve [E] tuşuna bas. Diğer kapıyı çevir.
4. Kapıdan geç.
> Fareyi bir ayarın üstüne getir: kısa bir satır ne yaptığını söyler.
# Bu yardımın sayfaları
- {page:gates|Stargate, DHD ve halkalar}
- {page:hatak|Ha'tak ana gemisi}
- {page:glider|Death Glider}
- {page:alkesh|Al'kesh ve diğer gemiler}
- {page:spacegrid|PowerGrid: güç ve enerji}
- {page:goauldpower|Goa'uld güç merkezi ve kristaller}
- {page:lifesupport|Yaşam desteği ve uzay}
- {page:weapons|El silahları}
- {page:keys|Tuşları değiştir}
- {page:admin|Yöneticiler için ayarlar}
- {page:problems|Sorunlar ve çözümler}
]] },

{ id = "gates", title = "Stargate, DHD ve halkalar", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Bir kapı ve bir DHD oluştur, DHD'de E tuşuna bas, adresi çevir. Halkalar seni yakındaki halka platformları arasında taşır.
# Nereden alınır
- [Q] > Ascension Gates > **Stargate ve Halkalar**: kapılar, DHD'ler, halkalar ve halka panelleri.
- Araçlar ([Q] > sağ taraf > Ascension Gates > Tech): Mobile DHD, Supergate DHD, Iris, Goa'uld Iris.
# DHD ile çevir
1. DHD'yi kapının yanına koy (1000 birimden yakın).
2. DHD üzerindeki bir sembole bak ve [E] tuşuna bas: yanar.
3. Adresin tüm sembollerine bas, sonra büyük orta düğmeye bas.
- Hiç sembol basılı değilken orta düğme: çevirme menüsü açılır.
- Kapı açıkken orta düğme: kapı kapanır.
# Kapı menüsü ile çevir
1. Kapıya bak ve [E] tuşuna bas.
2. Adresi yaz veya listeden seç.
3. **Dial** düğmesine tıkla. **Abort Dialling / Close Gate** durdurur.
- Aynı menüde kapının kendi adresini, grubunu, adını ve özel olup olmadığını ayarlarsın.
# Iris
- **Iris** aracı: kapıya sol tık. Tuşlar: sayısal tuş takımındaki [2] açıp kapatır.
- **Iris Bilgisayarı** (Stargate ve Halkalar): irisli bir kapıya dokundur, [E] = menü (kodlar, otomatik kapanma).
- **GDO** (silah): sağ tık = kodunu yaz, sol tık = açık bir kapıya gönder.
# Halkalar
- Halka platformu + halka paneli, birbirine yakın (panel 500 birim içindeki halkalar için çalışır).
- Panel düğmesinde [E] onu basar. Rakamsız **DIAL** = en yakın halkalara. Rakamlı = o halka adresine.
- Halka tabanında [E]: ona bir ad (adres) ver.
- **Ring Caller** (silah): sol tık en yakın halkaları çağırır, sağ tık çevirme penceresini açar.
! Halkalar, indikleri yerde kıpırdamadan durursan seni ezer. Platformun ortasında dur veya platformdan in.
]] },

{ id = "hatak", title = "Ha'tak ana gemisi", icon = "icon16/house.png", body = [[
= Dev bir Goa'uld ana gemisi. İçinde yürüyebilir, uçabilir, savaşabilir ve güç verebilirsin. İçi dışından çok daha büyüktür.
# Oluştur
- [Q] > Ascension Gates > **Daha büyük ana gemiler** > Ha'tak.
- Nişan aldığın yerin yüksekliğinde belirir (gökyüzüne nişan alırsan önünde). Havada durur.
# İçeri gir
- **Hangar:** piramidin altındaki büyük kapı. Üzerinde [E] onu açar. İçeri gir: doğrudan içerideki hangardasın.
- Hangar kapısı dışarıda ve içeride tek kapıdır: iki tarafta da açık veya kapalı. Yanında içeride ve dışarıda bir kapı kumandası (altın plaka) var.
- **Halkalar:** geminin yakınındaki dış halkaları veya içerideki halka panelini kullan.
- Kapıda veya yanındaki altın kontrolde [E]: kapı açılır veya kapanır.
- Açık kapı: kapı aralığına bak ve kapatmak için [E] bas.
> İçeriden her zaman geldiğin yoldan çıkabilirsin: hangar açıklığı iki yöne de çalışır.
# Katlar
1. **Hangar katı:** hangar, halka odası, kel'no'reem odası, Jaffa kışlası, glider bölümü.
2. **Pel'tak (köprü):** taht, pilot koltuğu, silahlar, seyrüsefer ve komuta konsolları.
3. **Kapı odası:** DHD'li Stargate.
4. **Komuta katı:** sarkofajlı odalar, cephanelik, bilgisayar çekirdeği.
5. **Makine dairesi:** makine odası, hücreler, kalkan odası.
- Katlar arası yolculuk: halka panelinde [E] > katı seç.
# Kim kullanabilir
- **Mürettebat** = sahibi ve arkadaşları (eşya koruması arkadaşları).
- Yabancılar gemiyi **kontrol kristali** ile alabilir. Bak {page:hatak_systems|Ha'tak sistemleri}.
# Daha fazla
- {page:hatak_fly|Uçuş, atlama ve silahlar}
# Ana menü (tüm gemi tek pencerede)
- Aç: tahtta, pilot koltuğunda veya nişancı olarak [1], veya pel'taktaki komuta konsolunda [E].
- **SHIP:** gövde, güç, kalkanlar, kim uçuyor. Hiperuzay, silahlar, mühendislik, adresler.
- **DOORS:** her kapı: aç, kapat, kilitle. Tüm kapılar tek seferde açık veya kapalı.
- **SYSTEMS:** kalkanlar, gizlenme, alarm, kilitleme, gemi günlüğü, kendini imha.
- {page:hatak_systems|Güç, bilgisayar, kalkanlar, hasar ve odalar}
]] },

{ id = "hatak_fly", title = "Ha'tak: uç, atla, savaş", icon = "icon16/arrow_up.png", body = [[
= Pel'taktaki pilot koltuğuna otur. W/S/A/D = uçuş, R = hiperuzay, V = kamera. Silahlar silah konsolundadır.
# Dümene geç
1. Pel'take (köprüye) git.
2. **tahta** ([E]) veya pilot koltuğuna ([E] pilot konsolunda) otur.
3. Koltuktan [E] ile kalk.
- Önce taht gelir: ikisi de doluysa taht uçar.
- [1] **ana menüyü** açar (nişancı modunda da).
- Geminin önü hangar tarafıdır: [W] o yöne uçar.
# Uçuş tuşları
- [W] ileri, [S] geri.
- [A] / [D] sola / sağa dön.
- [Space] yukarı, [Ctrl] aşağı.
- [Shift] basılı tut: 4 kat daha hızlı.
- [V]: kamera. Geminin arkasında ve üstünde başlar (fare tekerleği = uzaklık). Sonra: koltuk, sonra ön uçtan görünüm.
- Pel'taktaki pencere dışarıdaki gerçek manzarayı gösterir.
- [R]: hiperuzay menüsü.
- Pilot yoksa: gemi yavaşlar ve durur.
> Gemi uçarken içerideki kimse kaymaz.
# Hiperuzay atlayışı
1. Pilot koltuğunda [R] tuşuna bas (veya seyrüsefer konsolunda [E]).
2. Bir hedef seç: kayıtlı işaretler, bir Stargate veya başka bir oyuncu. Ya da x y z yaz.
3. **Jump** düğmesine tıkla. Gemi dolar (3 sn), bir pencere açılır, içinden uçarsın.
- **İşaret 1/2/3 buraya** yeri hatırlar.
- %30 hipersürücü gücü gerekir. Atlayışlar arasında 8 sn bekleme.
# Silahlar
- **Silah konsolunda** [E]: yukarıdan radar ve hedef listesi.
- **OFF:** ateş yok. **DEFEND:** yalnızca gemiye saldıran şeye ateş eder. **AUTO:** NPC'lere ve yabancılara da.
- **FIRE:** seçilen hedefe tek salvo. **KEEP FIRING:** tekrar tekrar.
- **MANUAL (GUNNER)** veya nişancı koltuğuna otur: nişanı sen alırsın.
## Nişancı tuşları
- Fare nişan alır, [Mouse1] ateş, [Mouse2] basılı tut yakınlaştır.
- [R] sonraki top grubu (üst, ön, yanlar, arka, alt).
- [E] ayrıl.
! Ateş etmek kendi gizlenmeni kapatır.
]] },

{ id = "hatak_systems", title = "Ha'tak sistemleri ve odaları", icon = "icon16/cog.png", body = [[
= Kristaller her şeye güç verir. Birini çek, bir sistem zayıflar. Bilgisayar çekirdeği halkaları, kapıları, sensörleri ve mesajları yönetir.
# Makine odası: güç kristalleri
- Güç çekirdeği (hub) 3 kristal tutar. Tepsiler 3'er kristal tutar: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- Kristalde [E]: onu çekip taşırsın.
- Boş yuvada [E]: onu takarsın.
- Yanmış kristaller (koyu) sert darbelerden olur. Onları **yedek rafa** koy: 60 sn'de dolar.
- İki naquadah jeneratörü: [E] onları açar (her biri +%15).
- **Dördüncü hub kolu:** bir kristal daha (+%15) veya bir **ZPM** (%130). ZPM'yi yerçekimi silahıyla yaklaştır: yerine oturur.
- **Mühendislik konsolu:** tüm gücü gösterir. Düğmeler bir sisteme daha çok güç yollar.
# Bilgisayar çekirdeği: veri kristalleri
- 4 rafta mavi kristaller: **Rings**, **Doors**, **Sensors**, **Communication**. 3'ten 2'si takılı olmalı, yoksa o işlev durur.
- **Kendini imha:** 1, 2 veya 4 dakika. **ABORT** durdurur.
- **Gemi günlüğü:** gemide ne oldu.
- **Adresler:** haritadaki her kapı. **DIAL** kapı odasından çevirir.
- **Güvenlik:** alarm açık/kapalı, kilitleme (tüm kapılar kilitli, mürettebat yine de açabilir).
# Kalkanlar ve gizlenme
- Kalkan odası konsolu veya komuta konsolu: **RAISE / LOWER SHIELDS**.
- **AUTO:** biri saldırınca kalkanlar kendiliğinden kalkar.
- Kalkan her silahı durdurur, sahibinin silahını da: atışlar altın baloncukta durur.
- **CLOAK:** gemi görünmez olur. %30 kalkan gücü gerekir. Gizliyken kalkanlar düşer.
# Yaşam desteği
- Gemide hava, ısı ve yerçekimi, uzayda da.
- Çekirdekten güç ve %10 üstü gövde gerekir. O olmazsa içerisi dışarısı gibidir (uzayda hava yok).
- Ana menü: durum SHIP'te, aç/kapa SYSTEMS'te.
# Hasar
- Yalnızca ağır darbeler sayılır. Kalkan dururken darbeleri o alır.
- **İçerideki** patlamalar iki kat fazla acıtır ve yakındaki kristalleri yakar.
- Gövde %50, %25 ve %10 olunca alarm. 0 olunca gemi patlar (yöneticiler bunu kapatabilir).
- **Tamir aracı** gövdeyi tamir eder.
# Odalar
- **Glider bölümü:** 4 Death Glider. [E] = uç. Fırlatma tünelinden dışarı uç. Kaybolan gliderlar 60 sn sonra geri gelir.
- Fırlatma tünellerinin içte ve dışta kapıları var. Onlara glider ile uçtuğunda kendiliğinden açılır. Ana menüde aç veya kapat.
- **Kışla:** ranza konsolunda [E] = gemide yeniden doğarsın. Zırh sandığı: [E] = +50 zırh (dakikada bir).
- **Kel'no'reem:** paspasın üstünde çömel ([Ctrl]) = yavaşça iyileşirsin.
- **Sarkofaj:** [E] ile içine yatıp iyileş.
- **Silahlar:** [E] duvardaki bir asa silahına: onu alırsın (2 dakika sonra yenisi gelir). [E] bir zat sandığına: bir zat.
- **Hücreler:** hücrenin yanındaki panelde [E] kuvvet alanını açar kapatır (yalnızca mürettebat).
# Gemiyi ele geçirme (hijack)
1. İçeride bir yere saklanmış **kontrol kristalini** bul. [E] onu alır.
2. Pel'taktaki kristal yuvasına git (sağ duvar). [E] başlatır.
3. 40 sn yakında kal. Alarm çalar.
4. Bitti: sen ve arkadaşların yeni mürettebatsınız.
- Eski mürettebat durdurabilir: yuvada [E].
]] },

{ id = "glider", title = "Death Glider", icon = "icon16/bullet_go.png", body = [[
= Küçük bir Goa'uld savaş uçağı. W = uç, fare = yönlendir, Mouse1 = ateş. Hiçbir tuşa basmazsan havada durur.
# Nereden alınır
- [Q] > Ascension Gates > **Filo: Gemiler ve avcılar** > Death Glider. Veya Ha'tak glider bölümünde.
# Tuşlar
- Glider'da [E]: bin. Tekrar [E]: in.
- [W] ileri uç, [S] yavaşça geri. [Shift] basılı tut: daha hızlı.
- Fare: yönlendir.
- [1]: kokpit görünümü aç / kapa.
- Tuş yok: havada yerinde durur.
- [Mouse1]: iki asa topuyla da ateş.
- Fare tekerleği: yatır. [Mouse3]: tekrar düze döndür.
- Ok tuşları: kamera uzaklığı ve yüksekliği.
- [Backspace]: kendini imha.
# Serbest uçuş (sunucu ayarı)
- **agp_glider_free_flight 1** ile: [S] geri, [A] / [D] yana, [Space] yukarı, [Ctrl] aşağı.
# HUD
- Sol altta: gövde, hız, asa topları, tuşlar.
- 300 gövde. 0 olunca patlar.
> Tuşları değiştir: {page:keys|Tuşları değiştir}.
]] },

{ id = "alkesh", title = "Al'kesh ve diğer gemiler", icon = "icon16/bullet_go.png", body = [[
= Her gemi: E = bin ve in, W/A/S/D ve fare = uç, Mouse1 = ateş.
# Al'kesh
- [Q] > Ascension Gates > **Filo: Gemiler ve avcılar**. Oluşturmak için yere nişan al.
- [W] [S] [A] [D] uçuş. [Space] yukarı, [Ctrl] aşağı. [Shift] basılı tut: daha hızlı.
- [Mouse1] ateş. Fare tekerleği yatır, [Mouse3] tekrar düz.
- [Enter]: iniş modu (düz tutar).
- [E] in. [Backspace] kendini imha.
# Büyük gemiler
- Aurora, Destiny, Gate Seeder, O'Neill, Ori ana gemisi, Prometheus, Replicator ana gemisi, Gezgin gemisi, Wraith kruvazörü.
- Al'kesh ile aynı tuşlar. Ayrıca [Mouse2] hedefi izle, [G] kalkan.
# Küçük gemiler
- **Puddle Jumper:** [Mouse1] dronlar (bölmeleri kendisi açar), [Mouse2] basılı tut = dronlar nişanını izler, [Alt] gizlenme, [2] kapı, [T] havada kalma, [G] kalkan, [R] en yakın geçidi çevir.
- **Tel'tak:** [Mouse2] asa topları, [G] kalkan, [Alt] gizlenme, [R] basılı tut: hiperuzay, [2] kapı. Halka ışını: [Enter] (iniş modu), sonra [Mouse1].
- **F-302:** [Mouse1] toplar, [Mouse2] füzeler, [Alt] parlama fişekleri, [B] hızlanma, [2] fırlat.
- **Daedalus:** [Mouse1] raylı toplar, [Mouse2] Asgard ışını, [1] ile [8] arası füzeler.
- **Wraith Dart:** [C] insanları topla, [Alt] onları bırak.
> Tuşları değiştir: {page:keys|Tuşları değiştir}.
]] },

{ id = "spacegrid", title = "PowerGrid: güç ve enerji", icon = "icon16/lightning.png", body = [[
= PowerGrid enerji için araç sekmesidir. Güç parçalarını yerleştir, bağla, ZPM'lerle veya jeneratörlerle besle.
# Nerede
- [Q] > sağ taraf > **PowerGrid** sekmesi.
- **PowerGrid:** PowerGrid parçaları aracı (tüm parçalar tek bir resim ızgarasında).
- **Enerji:** ZPM, ZPM hub'ları, naquadah jeneratörleri, Goa'uld güç merkezi, PowerGrid Bağlantısı.
- **Ayarlar:** PowerGrid ayarları ve bu yardım.
# Parça yerleştir
1. **PowerGrid parçaları** aracını al.
2. Sağdaki bir resme tıkla (örneğin bir enerji hücresi).
3. Durması gereken yere nişan al. Hayaletini görürsün.
4. Sol tık [Mouse1]: yerleştirildi. Sağ tık [Mouse2]: 90 derece döndürülmüş yerleştirildi.
- Bir parçaya nişan al ve [R] tuşuna bas: o parça seçilir.
- Gemide veya proptta, nişan aldığın şeye kaynaklanır (kutu **Nişan aldığına kaynat**).
# Parçalar
- **Enerji hücreleri (XS - XL):** enerji depolar.
- **Güneş panelleri:** üstleri açık gökyüzüyken enerji üretir.
- **Rüzgar türbini:** enerji üretir, ne kadar yüksekteyse o kadar çok.
- **Kara Delik Enerjisi:** her kaynağı tutar (izin verilmedikçe yalnızca yöneticiler).
- **Güç düğümleri:** üstlerine yerleştirilen her şeyi bağlar. Ekranları ağı gösterir.
- **Güç ekranları:** bağlı oldukları ağı gösterir.
- **Güç vanası:** açık = enerji iki ağ arasında akar, kapalı = ağlar ayrıdır. [E] değiştirir.
- **Kaynak tankları:** bir kaynak tutar (oksijen, su ...). Boşken [E] kaynağı değiştirir.
- **Yaşam desteği:** bak {page:lifesupport|Yaşam desteği}.
# Bağlama (parçalar enerjiyi nasıl paylaşır)
- Yöneticiler modu seçer: **Manual**, **Automatic**, **Mix** veya **Off** (PowerGrid ayarları).
- **Manual:** **PowerGrid Bağlantısı** aracı: parçalara sol tık (maviye döner), bağlanacakları parçaya veya güç düğümüne sağ tık. [R] seçimi temizler; bir parçada [R] bağlantılarını kaldırır.
- **Automatic:** birbirine kaynaklı parçalar kendiliğinden paylaşır.
- **Off:** her şeyin serbest enerjisi vardır.
! Spacebuild kurulu mu? O zaman Spacebuild'in ağı kullanılır. PowerGrid'in güç düğümleri o zaman Spacebuild düğümü olarak çalışır: PowerGrid Bağlantısı aracı ile bağla. Yöneticiler **Her zaman PowerGrid** seçeneğini açabilir.
# Enerji kaynakları
- **ZPM:** **ZPM MK III** aracı. Onu bir ZPM hub'ına veya bir {page:goauldpower|Goa'uld güç merkezine} tak.
- **Naquadah jeneratörü:** Energy içindeki araç.
- **Goa'uld güç kristalleri:** {page:goauldpower|Goa'uld güç merkezinde}.
]] },

{ id = "goauldpower", title = "Goa'uld güç merkezi ve kristaller", icon = "icon16/rainbow.png", body = [[
= Altın güç çekirdekli pirinç bir hub. 4 kolu Goa'uld güç kristallerini veya ZPM'leri alır. Çekirdek ne kadar çok gücü varsa o kadar parlak atar.
# Nereden alınır
- Araç: [Q] > PowerGrid > Enerji > **Goa'uld Power Hub + Crystals**.
- Veya oluşturma sekmesi: Ascension Gates > **PowerGrid**.
# Kullan
1. Araçla sol tık [Mouse1]: bir hub.
2. Bir kola nişan al ve sağ tık [Mouse2]: o kola bir kristal oturur.
3. ZPM: ZPM aracını al, bir kola nişan al, sol tık: ZPM o kola oturur.
4. Hub'ı diğer parçalar gibi ağına bağla ({page:spacegrid|PowerGrid}).
- Bir kristali veya ZPM'yi kola dokundur (yerçekimi veya fizik silahıyla): yerine oturur.
- Kristalde veya ZPM'de [E]: dışarı çıkar.
- Hub'da [E]: kristalleri, ZPM'leri ve enerjiyi sohbette gösterir.
- Hub'a bak: küçük bir levha kristalleri ve enerjiyi gösterir.
> Bir ZPM, bir kristalin on katı güç verir ve çekirdeği daha çok zorlar.
# Araçtaki kaydırıcı
- **Kristal şarjı:** yeni kristallerin ne kadar dolu olduğu (0 ile 100 % arası).
]] },

{ id = "lifesupport", title = "Yaşam desteği ve uzay", icon = "icon16/heart.png", body = [[
= Uzayda hava yoktur ve soğuktur. Giysin seni bir süre korur. Yaşam desteği bir gemiyi veya alanı güvenli yapar.
# Ne zaman açık?
- Yöneticiler seçer: yalnızca uzay haritaları (varsayılan), her harita veya kapalı ({page:admin|Yöneticiler için ayarlar}).
# Senin giysin
- Üç değer: **hava**, **enerji**, **soğutucu**. Doğduğunda hepsi doludur.
- Hava yok veya su altındasın: hava azalır. İyi hava: tekrar dolar.
- Soğuk: enerji azalır. Sıcak: soğutucu azalır.
- 0 olan bir değer sana zarar verir.
- Sol alttaki kutu yalnızca bir sorun olduğunda görünür.
# Life Support Core
- Gemide: tüm gemi hava alır. [E] değiştirir.
- Gemide değilse: bir hava balonu. [E] boyutu değiştirir (300 ile 2000, sonra kapalı).
- Enerji ve oksijen gerekir (oksijeni sudan yapar).
# Giysini doldur
- **Giysi Dağıtıcı:** [E] kendi ağından hava, enerji ve soğutucuyu doldurur.
- **Hava Kompresörü:** solunabilir havadan oksijen. **Su Pompası:** suyun içinde dururken su.
# Kapı raporu
- Bir kapı çevrilince kısa bir rapor alırsın: öbür taraftaki hava, sıcaklık, yerçekimi ve giysiye ihtiyacın olup olmadığı.
]] },

{ id = "weapons", title = "El silahları", icon = "icon16/bomb.png", body = [[
= Onları [Q] > Ascension Gates > Silahlar içinde bul. Mouse1 = ana kullanım, Mouse2 = ikinci kullanım.
# Goa'uld
- **Zat'nik'tel:** 1. atış sersemletir, 2. öldürür, 3. yok eder.
- **Asa silahı:** [Mouse2] hazırla, [Mouse1] ateş.
- **El cihazı:** [Mouse1] kullan, [Mouse2] sonraki mod.
- **İyileştirme cihazı:** iyileştirmek için bir oyuncuya doğrult.
- **Mobil DHD:** onu bir kapının üstüne koy.
# Dünya (SGC)
- **P90 (PDW):** [Mouse1] ateş, [Mouse2] nişan, [R] doldur.
- **Beretta:** [Mouse1] ateş, [R] doldur.
- **GDO:** [Mouse2] kod yaz, [Mouse1] gönder.
# Diğerleri
- **Ori el silahı / asası, Wraith blasteri, Ronon'un silahı, Asuran silahı.**
- **Tac:** at, tekrar = patlat. [Mouse2] öldür / sersemlet / duman.
- **Tamir aracı:** tamir etmek için bir gemide, kapıda veya DHD'de tut.
- **Kontrol koltuğu (Kadim, Silahlar sekmesi):** [E] ile otur (hub'ında dolu bir ZPM ister). [1] = hedef listesi: dronları bir hedefe kilitle veya serbest nişan al.
- **Kişisel kalkan, Sodan pelerini:** [Mouse1] aç, [Mouse2] kapat.
- **Mimetik görüntüleme cihazı:** önündeki yakın bir kişiyi görüntülemek için [Mouse1] basılı tut, [Mouse2] projeksiyon aç / kapat, [R] görüntüyü sil.
]] },

{ id = "keys", title = "Tuşları değiştir", icon = "icon16/keyboard.png", body = [[
= Küçük gemilerin çoğunun tuşlarını Keybinders menüsünde değiştirebilirsin.
# Nasıl
1. [Q] > sağ taraf > Ascension Gates > **Keybinders**.
2. Gemiyi seç.
3. Bir satıra bir kez tıkla, sonra hızlıca ikinci kez (turuncu olur).
4. Yeni tuşa veya fare düğmesine bas. [Esc] iptal eder.
- Gemiler: Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- Ha'tak normal GMod tuşlarını ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) ve [V] tuşunu kullanır.
- Kendi tuşun için: onu **agp_hatak_camera** komutuna bağla (konsol: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Yöneticiler için ayarlar", icon = "icon16/shield.png", body = [[
= Yöneticiler (ve tek oyunculuda sen) sunucu ayarlarını değiştirir. Diğer herkes yalnızca görür. Kısa bir ipucu için fareyi ayarın üstüne getir.
# Gemi ayarları: [Q] > Ascension Gates > Config > AGP gemileri
- **Ele geçirme:** yalnızca mürettebat / kontrol kristali ile / herkes.
- **Silahlar sahibe ve arkadaşlara ateş eder:** evet veya hayır.
- **Silah + radar menzili:** toplar ne kadar uzağa ateş eder ve radar ne kadar uzağı görür.
- **Radar: en fazla hedef sayısı.**
- **Yabancıların çıkarabileceği kristaller:** 0 ile 15 (varsayılan 2). Mürettebatın sınırı yok.
- **Gemi yok edilebilir:** evet (varsayılan) veya hayır (gövde 1'de kalır).
- **Gövde dayanıklılığı (yeni gemiler):** 10.000 ile 1.000.000 (varsayılan 100.000).
- **Gizlenme izinli:** evet veya hayır.
- **Planör hangarı: kayıp planörler geri gelir:** evet veya hayır, ve kaç saniye sonra (varsayılan 60).
- **Kalkan balonu (tüm gemiler):** yalnızca isabet alınca ve açılıp kapanırken (varsayılan) ya da her zaman görünür.
- **Kendini imha: geri sayım (tüm gemiler):** 1 ile 600 saniye arası (varsayılan 5).
# Enerji ayarları: [Q] > PowerGrid > Ayarlar > PowerGrid
- **Parçalar nasıl bağlanır:** Elle / Otomatik / Karma / Kapalı. Bak {page:spacegrid|PowerGrid}.
- **Her zaman PowerGrid:** Spacebuild ile bile PowerGrid kullan (harita değişimi gerekir).
- **Kara Delik Enerjisi:** yalnızca yöneticiler veya herkes.
- **Uzay simülasyonu:** yalnızca uzay haritaları / her harita / kapalı. Bak {page:lifesupport|Yaşam desteği}.
- **Geçit varış raporu:** açık veya kapalı.
# Yalnızca senin için (her oyuncu)
- Kablolar, makine sesleri, ekranındaki kapı raporu, mesafe, sıcaklık ve yerçekimi birimleri.
]] },

{ id = "problems", title = "Sorunlar ve çözümler", icon = "icon16/help.png", body = [[
= Bir şey çalışmıyor mu? Önce buraya bak.
# Q menüsündeki simgeler pembe oluyor ve hiçbir şey oluşmuyor
- [Ctrl] basılı tutuyorsun (veya takıldı). [Ctrl] + tık simgeleri oluşturmak yerine **seçer** (pembe).
- Çözüm: [Ctrl] tuşunu bırak (bir kez bas), simge alanında boş bir yere tıkla.
# Bir simgeye tıklıyorum ve hiçbir şey çıkmıyor
- Uzak gökyüzüne değil, önündeki zemine bak.
- Büyük gemiler zeminin yükseğinde veya önünde belirir. Etrafına bak.
- Yöneticiler parçaları kapatabilir veya sınırlayabilir (Ascension Gates > Config > Hakkında & Katkı > Ayarlar).
# Glider düşüyor
- Death Glider hiçbir tuşa basmadığında yüksekliğini korur. Düşüyor mu? Yok edilmiş veya haritanın dışında olabilir.
# Ha'tak konsolu "crew only" diyor
- Yalnızca sahibi ve arkadaşları kullanabilir. Ya da gemiyi kontrol kristali ile al ({page:hatak_systems|Ha'tak sistemleri}).
# Bir gemi sistemi OFFLINE diyor
- Makine odasındaki kristalleri ve bilgisayar çekirdeğindeki mavi veri kristallerini kontrol et.
# Karakter bir kapı aralığında veya kapıda takıldı
- Gemi iç mekanlarının kapı aralıkları, diğer taraf kapalıyken seni geçirmez. Önce kapıyı aç.
- Hâlâ takılıyorsa: noclip ([V]) veya yeniden doğ.
# Bir araç #tool.something.name gibi bir yazı gösteriyor
- Bir yazı eksik. Lütfen hangi araç olduğunu bana söyle.
]] },

},
}
