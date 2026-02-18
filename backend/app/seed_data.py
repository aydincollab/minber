"""Seed data for hutbeler when scraper cannot reach Diyanet website."""

from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date
import logging

logger = logging.getLogger(__name__)

# Seed hutbeler - realistic Turkish hutbe content matching HutbeCreate schema
SEED_HUTBELER = [
    {
        "title": "İman ve Sorumluluk Bilinci",
        "content": """Muhterem Müslümanlar!

İman, insanın hayatına anlam kazandıran, onu sorumluluklarının bilincine vardıran en temel değerdir. Yüce Allah Kur'an-ı Kerim'de şöyle buyurur: "Onlar ki iman ettiler ve kalpleri Allah'ı anmakla huzur bulur. Bilin ki kalpler ancak Allah'ı anmakla huzur bulur." (Ra'd Suresi, 13/28)

İman sahibi bir Müslüman, her an Allah'ın gözetimi altında olduğunun şuurundadır. Bu şuur, onu hayatın her alanında sorumlu davranmaya sevk eder. İmanlı insan, ailesi­ne karşı, topluma karşı ve tüm yaratılmışlara karşı sorumluluklarını yerine getirmeye çalışır.

Peygamber Efendimiz (s.a.v.) bir hadis-i şeriflerinde şöyle buyurmuştur: "Hepiniz çobansınız ve hepiniz sürüsünden sorumlusunuz." Bu hadis, her Müslümanın üzerine düşen sorumlulukları hatırlatmaktadır.

İman, sadece kalple tasdik etmek değil, aynı zamanda dil ile ikrar etmek ve organlarla amel etmektir. Gerçek iman, insanın tüm davranışlarına yansıyan, onu güzel ahlaka ve erdemli yaşama yönlendiren bir güçtür.

Aziz Müslümanlar! İmanımızı güçlendirelim, sorumluluklarımızın bilincinde olalım. Allah'ın rızasını kazanmak için gayret gösterelim. Unutmayalım ki iman, kulun en büyük sermayesidir.""",
        "summary": "İman, insanın hayatına anlam kazandıran ve onu sorumluluklarının bilincine vardıran en temel değerdir. İmanlı insan, Allah'ın gözetimi altında olduğunun şuuruyla hareket eder...",
        "date": date(2025, 1, 3),
        "year": 2025,
        "category": "İman",
        "reading_time_minutes": 2,
        "source_url": None,
        "is_featured": True,
    },
    {
        "title": "Namazın Manevi İklimi",
        "content": """Aziz Kardeşlerim!

Namaz, Müslümanın miracıdır. Allah ile kul arasındaki en özel buluşma anıdır. Yüce Rabbimiz Kur'an-ı Kerim'de "Namazı dosdoğru kılın, zekâtı verin ve Peygamber'e itaat edin ki size merhamet edilsin." (Nur Suresi, 24/56) buyurarak namazın önemine dikkat çekmektedir.

Namaz, sadece bir ritüelden ibaret değildir. Namaz, insanın tüm benliğiyle Allah'a yöneldiği, O'na hamd ve şükrettiği, O'ndan af ve mağfiret dilediği mübarek bir ibadettir. Beş vakit namaz, günün beş farklı diliminde Allah'ı anmamızı, O'nu hatırlamamızı sağlar.

Peygamber Efendimiz (s.a.v.) "Namaz dinin direğidir" buyurmuştur. Namaz, Müslümanın İslam'a bağlılığının en açık göstergesidir. Namazını terk eden, dinin temel direğini yıkmış olur.

Namaz, insanı kötülüklerden alıkoyan, ona doğru yolu gösteren bir nur kaynağıdır. Gönül huzuruyla kılınan her namaz, kulun Allah katındaki derecesini yükseltir, günahlarını siler.

Muhterem Cemaat! Namazlarımızı vaktinde, huşu içinde kılalım. Çocuklarımıza namaz sevgisi aşılayalım. Namaz ile huzuru, namazla mutluluğu yakalayalım.""",
        "summary": "Namaz, Müslümanın miracıdır. Allah ile kul arasındaki en özel buluşma anıdır. Beş vakit namaz, günün beş farklı diliminde Allah'ı anmamızı sağlar...",
        "date": date(2025, 2, 7),
        "year": 2025,
        "category": "İbadet",
        "reading_time_minutes": 2,
        "source_url": None,
        "is_featured": False,
    },
    {
        "title": "Aile Huzurunun Sırları",
        "content": """Muhterem Müslümanlar!

Aile, toplumun en küçük ama en önemli yapı taşıdır. Huzurlu bir aile, huzurlu bir toplumun temelidir. Kur'an-ı Kerim'de Allah Teala şöyle buyurur: "Ayetlerinden biri de, size kendinizden eşler yaratması, onlarla huzur bulmanız ve aranızda sevgi ve merhamet var etmesidir." (Rum Suresi, 30/21)

Ailede huzur, karşılıklı sevgi, saygı ve anlayışla mümkündür. Eşler birbirlerine karşı sabırlı, merhametli ve fedakâr olmalıdır. Anne ve baba, çocuklarına karşı sorumludur; onları İslami değerlerle yetiştirmek, onlara güzel ahlak öğretmek ebeveynlerin en önemli görevidir.

Peygamber Efendimiz (s.a.v.) "Sizin en hayırlınız, ailesine karşı en hayırlı olanınızdır" buyurmuştur. Bu hadis, aile içindeki ilişkilerin ne kadar önemli olduğunu göstermektedir.

Ailede iletişim çok önemlidir. Birbirimizi dinlemeliyiz, anlamalıyız. Sorunları konuşarak, sevgi ve saygı çerçevesinde çözmeliyiz. Unutmayalım ki ailede huzur, herkesin fedakarlık göstermesiyle mümkündür.

Aziz Müslümanlar! Ailelerimize sahip çıkalım, evlerimizi huzur ve mutluluk yuvası haline getirelim. Allah, huzurlu aileler nasip etsin.""",
        "summary": "Aile, toplumun en küçük ama en önemli yapı taşıdır. Huzurlu bir aile, huzurlu bir toplumun temelidir. Ailede huzur, karşılıklı sevgi, saygı ve anlayışla mümkündür...",
        "date": date(2025, 3, 14),
        "year": 2025,
        "category": "Aile",
        "reading_time_minutes": 2,
        "source_url": None,
        "is_featured": False,
    },
    {
        "title": "Güzel Ahlak ve Fazilet",
        "content": """Aziz Kardeşlerim!

İslam dini, güzel ahlakın dinidir. Peygamber Efendimiz (s.a.v.) "Ben güzel ahlakı tamamlamak için gönderildim" buyurarak, ahlakın İslam'daki yerini net bir şekilde ortaya koymuştur.

Güzel ahlak, insanın hem Allah'a hem de kullarına karşı sorumluluklarını yerine getirmesidir. Doğruluk, dürüstlük, adalet, merhamet, cömertlik, tevazu gibi değerler İslam ahlakının temel taşlarıdır.

Kur'an-ı Kerim'de Yüce Allah, Peygamberimize hitaben "Sen elbette yüce bir ahlak üzeresin" (Kalem Suresi, 68/4) buyurarak, Peygamberimizin ahlakını övmüştür. Müslümanlar olarak bizim de örnek aldığımız, Peygamberimizin ahlakıdır.

Güzel ahlak sahibi olmak, sabır gerektirir. İnsanlarla olan ilişkilerimizde sabredelim, affedici olalım. Kimseye kötülük yapmayalım, iyiliği yayalım. Emanete riayet edelim, sözümüzde duralım.

Muhterem Cemaat! Unutmayalım ki kıyamet günü müminin terazisinde en ağır basan şey güzel ahlaktır. Ahlakımızı güzelleştirelim, Peygamber Efendimizin izinden gidelim. Allah bizleri güzel ahlak sahibi kullarından eylesin.""",
        "summary": "İslam dini, güzel ahlakın dinidir. Doğruluk, dürüstlük, adalet, merhamet, cömertlik, tevazu gibi değerler İslam ahlakının temel taşlarıdır...",
        "date": date(2025, 4, 18),
        "year": 2025,
        "category": "Ahlak",
        "reading_time_minutes": 2,
        "source_url": None,
        "is_featured": False,
    },
    {
        "title": "Toplumsal Dayanışma ve Kardeşlik",
        "content": """Muhterem Müslümanlar!

İslam, birlik ve beraberlik dinidir. Müslümanlar arasındaki kardeşlik bağı, kan bağından daha güçlüdür. Kur'an-ı Kerim'de Allah Teala "Müminler ancak kardeştirler" (Hucurat Suresi, 49/10) buyurarak, mü'minler arasındaki kardeşlik bağına dikkat çekmektedir.

Toplumsal dayanışma, İslam'ın önemli esaslarındandır. Birbirimize yardım etmeli, birbirimizin derdine ortak olmalıyız. Komşumuzun açken biz tok uyuyamayız. Toplumda zor durumda olanların yanında olmalıyız.

Peygamber Efendimiz (s.a.v.) "Mü'minlerin birbirlerine karşı sevgi, merhamet ve şefkat göstermelerinde, bedenin bir uzvu rahatsız olsa, diğer uzuvların da uykusuzluk ve ateşle ona ortak olması gibidir" buyurmuştur.

Zekât, sadaka, infak gibi ibadetler, toplumsal dayanışmanın araçlarıdır. İmkânı olanlar, ihtiyaç sahiplerine yardım etmeli, toplumda adalet ve dengeyi sağlamalıyız.

Aziz Müslümanlar! Birlik ve beraberlik içinde olalım. Toplumsal dayanışmayı güçlendirelim. Unutmayalım ki toplum olarak ancak birbirimize destek olarak ayakta kalabiliriz. Allah birliğimizi daim eylesin.""",
        "summary": "İslam, birlik ve beraberlik dinidir. Müslümanlar arasındaki kardeşlik bağı, kan bağından daha güçlüdür. Toplumsal dayanışma, İslam'ın önemli esaslarındandır...",
        "date": date(2025, 5, 23),
        "year": 2025,
        "category": "Toplum",
        "reading_time_minutes": 2,
        "source_url": None,
        "is_featured": False,
    },
]


async def load_seed_data(db: AsyncSession):
    """Load seed hutbe data into the database."""
    from app.schemas.hutbe import HutbeCreate
    from app.services.hutbe_service import HutbeService
    
    logger.info("Loading seed hutbe data...")
    
    loaded_count = 0
    for hutbe_dict in SEED_HUTBELER:
        try:
            hutbe_data = HutbeCreate(**hutbe_dict)
            await HutbeService.create_hutbe(db, hutbe_data)
            loaded_count += 1
            logger.info(f"Loaded seed hutbe: {hutbe_dict['title']}")
        except Exception as e:
            logger.error(f"Error loading seed hutbe '{hutbe_dict.get('title', 'Unknown')}': {e}")
            continue
    
    await db.commit()
    logger.info(f"Seed data loading completed. Loaded {loaded_count} hutbeler.")
    return loaded_count
