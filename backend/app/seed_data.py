"""Seed data for Minber database."""
import logging
from datetime import date
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.hutbe import HutbeCreate
from app.services.hutbe_service import HutbeService

logger = logging.getLogger(__name__)

# 10 seed hutbeler - 200-300 words each, Turkish, Diyanet-style
SEED_HUTBELER = [
    {
        "title": "İmanın Kalbimize Nurları",
        "content": """Muhterem Müslümanlar!

İman, hayatımızın temel direğidir. Rabbimize olan inancımız, bizi dünyada ve ahirette huzura kavuşturur. Allah'a iman, O'nun birliğine ve benzersizliğine gönülden inanmaktır. Bu iman, kalbimizi nurla doldurur ve bizi doğru yola iletir.

Sevgili Peygamberimiz (s.a.v.) buyurmuştur: "İman yetmiş küsur şubedir. En yükseği 'Lâ ilâhe illallah' demek, en aşağısı ise yoldan eğri taşı kaldırmaktır." Bu hadis, imanın sadece sözle değil, eylemle de gösterilmesi gerektiğini vurgulamaktadır.

İmanlı bir insan, dünyada karşılaştığı zorluklarda sebat eder. Zira bilir ki, her şey Allah'ın takdiri ile olmaktadır. İman, bize ümit verir, gücümüzü artırır ve manevi bir dayanma gücü kazandırır. Kur'an-ı Kerim'de şöyle buyurulur: "Bilin ki kalpler ancak Allah'ı anmakla huzur bulur."

İmanımızı güçlendirmek için ibadetlerimizi aksatmamalı, Kur'an okumalı ve Peygamberimizin sünnetini takip etmeliyiz. İman, aynı zamanda diğer insanlara karşı merhametli, adil ve dürüst olmayı gerektirir. İmanımızı koruyalım, güçlendirelim ve hayatımızın her alanında gösterelim.

Allah bizleri iman üzere yaşayan ve iman ile göçen kullarından eylesin.""",
        "summary": "İmanın hayatımızdaki önemi ve imanımızı güçlendirmek için yapılması gerekenler.",
        "date": "2024-01-05",
        "year": 2024,
        "category": "İman",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Ailenin Huzuru, Toplumun Temeli",
        "content": """Muhterem Müslümanlar!

Aile, toplumun temel taşıdır. Huzurlu bir aile, huzurlu bir toplumun başlangıcıdır. İslam dini, aile kurumuna büyük önem verir ve aile bireylerinin hak ve sorumluluklarını açıkça belirtir.

Aile içinde sevgi, saygı ve merhamet olmalıdır. Eşler birbirlerine karşı anlayışlı ve şefkatli olmalıdır. Kur'an-ı Kerim'de Allah (c.c.) buyurur: "O, aranızda sevgi ve merhamet meydana getirdi." Bu ayet, eşler arasındaki ilişkinin temelinin sevgi olduğunu gösterir.

Anne ve baba, çocuklarına karşı sorumludur. Onlara İslam'ın güzel ahlakını öğretmek, iyi bir eğitim vermek ve güzel örnekler olmak ebeveynlerin görevidir. Çocuklar da anne babalarına saygı göstermeli, onların nasihatlerini dinlemeli ve onlara itaat etmelidir.

Ailede adalet ve hakkaniyet esas olmalıdır. Kimse diğerinin hakkını yememeli, herkes sorumluluklarını yerine getirmelidir. Aile bireyleri birbirlerinin eksiklerini örtmeli, birbirlerini desteklemeli ve her zaman yanında olmalıdır.

Ailelerimizi İslam'ın prensipleri doğrultusunda inşa edelim. Sevgi, saygı ve merhamet ile dolu aileler kuralım ki, toplumumuz da huzur ve barış bulabilsin.""",
        "summary": "Ailenin önemi ve İslami değerler çerçevesinde huzurlu bir aile ortamı oluşturma.",
        "date": "2024-01-12",
        "year": 2024,
        "category": "Aile",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Doğruluk ve Güven: Müslümanın Alameti",
        "content": """Muhterem Müslümanlar!

Doğruluk, İslam ahlakının temel taşlarından biridir. Müslüman, her zaman doğru sözlü ve güvenilir olmalıdır. Peygamberimiz (s.a.v.) daha peygamberlikten önce "El-Emin", yani güvenilir olarak tanınırdı.

Doğru olmak, sadece sözde değil, davranışta da kendini göstermelidir. Ticaret yaparken, komşuluk ilişkilerinde, aile içinde ve toplumun her alanında doğruluk esastır. Kur'an-ı Kerim'de Allah (c.c.) şöyle buyurur: "Ey iman edenler! Allah'tan korkun ve doğru olanlarla beraber olun."

Yalan söylemek, münafikların özelliğidir. Peygamberimiz (s.a.v.) buyurmuştur: "Münafığın alametleri üçtür: Konuştuğunda yalan söyler, söz verdiğinde sözünde durmaz, kendisine emanet edildiğinde hıyanet eder."

Güvenilir olmak, insanlar arasında köprüler kurar. İnsanlar doğru ve güvenilir olanlarla çalışmaktan mutluluk duyar. Doğruluk, ticaretin bereketini, ilişkilerin devamlılığını ve toplumun huzurunu sağlar.

Hepimiz doğruluk ve güven üzerine bir hayat inşa edelim. Sözümüzde, davranışımızda ve işlerimizde daima dürüst olalım. Allah bizi doğrulardan eylesin.""",
        "summary": "Doğruluk ve güvenilirliğin İslam'daki yeri ve hayatımızdaki önemi.",
        "date": "2024-01-19",
        "year": 2024,
        "category": "Ahlak",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Namazın Ruhumuza Kattıkları",
        "content": """Muhterem Müslümanlar!

Namaz, İslam'ın beş şartından biridir ve mümin ile Rabbi arasında özel bir bağdır. Her gün beş vakit namaz kılmak, Allah'a kulluk etmenin en güzel yollarından biridir.

Peygamberimiz (s.a.v.) buyurmuştur: "Namaz, dinin direğidir." Namaz, bizi kötülüklerden alıkoyar, ruhumuzu arındırır ve Allah'a yaklaştırır. Kur'an-ı Kerim'de şöyle buyurulur: "Namaz, gerçekten fahşâ ve münkerden alıkoyar."

Namaz, sadece bedensel bir ibadet değildir. Huşu ile, yani kalp huzuru ve tam bir teslimiyet ile kılınmalıdır. Namazda iken dünya düşüncelerinden uzaklaşmalı, sadece Allah'a yönelmeliyiz.

Cemaatle namaz kılmak, sevabı yetmiş kat artırır. Camiler, müminlerin bir araya geldiği, kardeşlik duygularının güçlendiği mekânlardır. Cuma ve bayram namazları gibi toplu ibadetler, toplumsal dayanışmayı pekiştirir.

Namazı ihmal etmemeliyiz. Düzenli olarak namazlarımızı kılmalı, çocuklarımıza da küçük yaştan itibaren namaz alışkanlığı kazandırmalıyız. Namaz, dünya ve ahiret mutluluğumuzun anahtarıdır.""",
        "summary": "Namazın önemi, faydaları ve huşu ile namaz kılmanın gerekliliği.",
        "date": "2024-01-26",
        "year": 2024,
        "category": "İbadet",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Allah'ın Birliği ve Yüceliği",
        "content": """Muhterem Müslümanlar!

Tevhid, yani Allah'ın birliğine inanmak, İslam'ın özüdür. Allah tektir, ortağı yoktur, benzeri yoktur. O yaratandır, rızık verendir, her şeye gücü yetendir.

Kur'an-ı Kerim'in İhlas Suresi'nde Allah (c.c.) şöyle buyurur: "De ki: O, Allah birdir. Allah Samed'dir (her şey O'na muhtaçtır). O doğurmamış ve doğrulmamıştır. Hiçbir şey O'na denk değildir."

Tevhid inancı, hayatımızın her alanını etkiler. Allah'tan başka hiçbir varlığa ibadet etmeyiz, sadece O'ndan yardım dileriz. İnsanlardan korkmayız, sadece Allah'tan korkarız. Çünkü gerçek kudret O'nundur.

Şirk, yani Allah'a ortak koşmak, en büyük günahtır. Allah'tan başkasına ibadet etmek, ona dua etmek veya O'nun sıfatlarından birini başkasına vermek şirktir. Mümin, her zaman tevhid üzere olmalı, imanını koruma altına almalıdır.

Yaratılanları seven Allah'ı sever. Ancak kullar arasında sevgi, Allah'ın rızasını kazanmak içindir. Asla Allah sevgisini gölgeleyecek bir sevgi olmamalıdır. Kalplerimizi tevhid inancı ile dolduralım ve Allah'ın birliğine şahitlik edelim.""",
        "summary": "Tevhid inancının esasları ve hayatımızdaki yansımaları.",
        "date": "2024-02-02",
        "year": 2024,
        "category": "İman",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Toplumsal Dayanışma ve Yardımlaşma",
        "content": """Muhterem Müslümanlar!

İslam, müminleri kardeş kabul eder. Toplumda birlik, beraberlik ve dayanışma esastır. Peygamberimiz (s.a.v.) buyurmuştur: "Müminler, birbirlerini sevmekte, birbirlerine acımakta ve birbirlerini korumakta bir vücut gibidir."

Toplumsal yardımlaşma, İslam'ın temel değerlerindendir. Zekât, sadaka ve infak gibi ibadetler, zenginle fakir arasında bir denge kurar. Yoksullar yardım görür, zenginler de mallarının hakkını verirler.

Komşularımıza, akrabalarımıza ve toplumumuza karşı sorumluluklarımız vardır. Hasta ziyaret etmek, yoksullara yardım etmek, kimsesizlerin yanında olmak İslami görevlerimizdendir. Kur'an-ı Kerim'de Allah (c.c.) şöyle buyurur: "İyilik ve takva üzere yardımlaşın."

Toplumda bir ihtiyaç gördüğümüzde, elimizden geleni yapmalıyız. Bir gülümseme bile sadakadır. Birbirimize destek olmalı, zorlukta yanında olmalı ve mutlulukları paylaşmalıyız.

Dayanışma içinde güç vardır. Birlikte olursak, zorluklarla daha kolay başa çıkarız. Allah'ın yardımı, birlik içinde olanlarladır. Toplumsal bağlarımızı güçlendirelim ve kardeşlik içinde yaşayalım.""",
        "summary": "İslam'da toplumsal dayanışmanın önemi ve kardeşlik bilinci.",
        "date": "2024-02-09",
        "year": 2024,
        "category": "Toplum",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Evlilikte Sevgi ve Sorumluluk",
        "content": """Muhterem Müslümanlar!

Evlilik, İslam'da kutsal bir bağdır. Eşler, birbirlerinin tamamlayıcısıdır ve birlikte bir yuva oluştururlar. İslam, eşler arasında adalet, sevgi ve anlayışı esas almıştır.

Peygamberimiz (s.a.v.) buyurmuştur: "Sizin en hayırlınız, ailesine karşı en hayırlı olanınızdır." Bu hadis, aile içindeki davranışlarımızın ne kadar önemli olduğunu gösterir.

Eşler, birbirlerine karşı sabırlı, anlayışlı ve merhametli olmalıdır. Hataları affetmeli, eksiklikleri örtmeli ve birbirlerini desteklemelidir. Kur'an-ı Kerim'de Allah (c.c.) şöyle buyurur: "Onlar sizin için birer libasdır, siz de onlar için birer libasınız."

Evlilikte iletişim çok önemlidir. Sorunları konuşarak çözmeli, öfkeyle değil akılla hareket etmelidir. Birbirinin görüşlerine saygı göstermeli, ortak kararlar almalıdır.

Eşler, dünya ve ahiret arkadaşlarıdır. Birlikte Allah'a ibadet etmeli, birbirlerini hayra teşvik etmelidir. Evlilik, sadece bir beraberlik değil, Allah rızası için kurulan kutsal bir bağdır. Ailelerimizi sevgi ve sorumluluk üzerine inşa edelim.""",
        "summary": "İslam'da evliliğin esasları ve eşler arasındaki sorumluluklar.",
        "date": "2024-02-16",
        "year": 2024,
        "category": "Aile",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Sabır ve Şükür: Mümin'in İki Kanadı",
        "content": """Muhterem Müslümanlar!

Sabır ve şükür, mümin için vazgeçilmez iki haslet olmalıdır. Zorluklarda sabır, nimetlerde şükür, iman ehlinin özelliğidir.

Sabır, Allah'ın takdirine rıza göstermek, zorluklar karşısında sebat etmektir. Kur'an-ı Kerim'de Allah (c.c.) buyurur: "Ey iman edenler! Sabır ve namaz ile yardım isteyin. Şüphesiz Allah sabredenlerle beraberdir."

Hayatta karşılaştığımız sıkıntılar, imtihan vesilesidir. Allah, kullarını sever ve onları imtihan eder. Sabredenlere müjde vardır. Sabır, sadece dilenmekle değil, kalbin mutmain olması ve Allah'a güvenmekle olur.

Şükür ise, Allah'ın verdiği nimetlere karşı minnettarlık göstermektir. Sağlık, aile, rızık ve daha niceleri Allah'ın bize verdiği nimetlerdir. Bunlara karşı şükretmeliyiz. Şükreden kulların nimetleri artar.

Şükür, hem dil ile hem kalp ile hem de organlarla olur. "Elhamdülillah" demek, kalben mutlu olmak ve nimetleri Allah'ın yolunda kullanmak şükrün gereğidir. Sabır ve şükür ile hayatımızı süsleyelim ve Allah'a kulluk edelim.""",
        "summary": "Sabır ve şükrün mümin hayatındaki yeri ve önemi.",
        "date": "2024-02-23",
        "year": 2024,
        "category": "Ahlak",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Zekât: Malın Hakkı ve Bereket Kaynağı",
        "content": """Muhterem Müslümanlar!

Zekât, İslam'ın beş şartından biridir ve malın temizlenmesi anlamına gelir. Belirli miktarda mala sahip olan her müslüman, yılda bir kez zekâtını vermekle yükümlüdür.

Zekât, zengin ile fakir arasında bir denge kurar. Toplumda sosyal adalet sağlar ve yoksullara destek olur. Allah (c.c.) Kur'an'da buyurur: "Onların mallarında, dilencinin ve yoksulun hakkı vardır."

Zekât vermek, malımızın bereketini artırır. Sadaka veren el, alan elden üstündür. Peygamberimiz (s.a.v.) buyurmuştur: "Sadaka, malı eksilmez; bilakis artırır."

Zekât verirken, muhtaç kişilerin durumunu gözetmeliyiz. Yakın akrabalardan, komşulardan ve toplumdan zekât verilecek kişileri tespit edebiliriz. Ayrıca güvenilir hayır kurumları aracılığıyla da zekâtımızı ulaştırabiliriz.

Zekât vermek, sadece bir görev değil, aynı zamanda bir nimettir. Allah, bize mal vermiş ve onunla imtihan etmiştir. Malımızın hakkını vererek hem dünya hem ahiret kazancı elde edelim. Zekâtlarımızı özenle verelim.""",
        "summary": "Zekâtın farziyeti, önemi ve toplumsal etkileri.",
        "date": "2024-03-01",
        "year": 2024,
        "category": "İbadet",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    },
    {
        "title": "Komşuluk Hakkı ve Sorumlulukları",
        "content": """Muhterem Müslümanlar!

Komşuluk, İslam'da büyük önem taşır. Komşuya karşı iyi davranmak, İslam ahlakının gereğidir. Peygamberimiz (s.a.v.) buyurmuştur: "Cebrail, komşu hakkında bana o kadar çok tavsiyelerde bulundu ki, neredeyse komşuyu komşuya mirasçı yapacak sandım."

İyi komşu, selamlaşan, ziyaret eden, yardım eden ve zarar vermeyendir. Komşunun sevinçlerine ortak olmak, kederleriyle ilgilenmek ve ihtiyaçlarında yanında olmak gerekir.

Komşuya sadece müslüman komşu dahil değildir. Farklı dinden veya mezhepten olanlar da komşuluk hakkına sahiptir. İslam'ın evrensel ahlakı, herkese adil davranmayı emreder.

Komşuya eziyet etmek büyük günahtır. Peygamberimiz (s.a.v.) buyurmuştur: "Komşusu zararından emin olmayan kimse, cennete giremez." Bu nedenle, gürültü yapmak, rahatsız etmek veya zarar vermekten kaçınmalıyız.

Komşuluk hakkını gözetelim. Onlarla iyi ilişkiler kuralım, yardımlaşalım ve kardeşlik içinde yaşayalım. Toplumsal huzur, iyi komşuluk ilişkileri ile başlar.""",
        "summary": "İslam'da komşuluk haklarının önemi ve komşuya karşı sorumluluklar.",
        "date": "2024-03-08",
        "year": 2024,
        "category": "Toplum",
        "reading_time_minutes": 5,
        "is_featured": False,
        "source_url": "https://dinhizmetleri.diyanet.gov.tr"
    }
]


async def load_seed_data(db: AsyncSession) -> int:
    """
    Load seed hutbeler data into database.
    
    Args:
        db: Database session
        
    Returns:
        Number of hutbeler loaded
    """
    logger.info("Loading seed data...")
    
    loaded_count = 0
    for hutbe_data in SEED_HUTBELER:
        try:
            # Convert date string to date object
            hutbe_data_copy = hutbe_data.copy()
            if isinstance(hutbe_data_copy['date'], str):
                from datetime import datetime
                hutbe_data_copy['date'] = datetime.strptime(hutbe_data_copy['date'], '%Y-%m-%d').date()
            
            # Create hutbe schema
            hutbe_create = HutbeCreate(**hutbe_data_copy)
            
            # Save to database
            await HutbeService.create_hutbe(db, hutbe_create)
            loaded_count += 1
            logger.info(f"Loaded hutbe: {hutbe_data['title'][:50]}...")
            
        except Exception as e:
            logger.error(f"Error loading hutbe '{hutbe_data.get('title', 'Unknown')}': {e}")
            continue
    
    # Commit the transaction
    await db.commit()
    
    logger.info(f"Seed data loading completed. Loaded {loaded_count} hutbeler.")
    return loaded_count
