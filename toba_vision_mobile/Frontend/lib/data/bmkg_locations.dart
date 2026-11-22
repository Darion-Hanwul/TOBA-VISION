/// Master data wilayah dan kode stasiun BMKG untuk sentra perkebunan tembakau dan seluruh Indonesia.
/// Menggunakan standar kode administrasi Kemendagri / BPS (adm1 s/d adm4).
class BmkgLocation {
  final String code;
  final String name;
  final String kecamatan;
  final String kabupaten;
  final String province;
  final String description;
  final String? desa;
  final bool isTemanggung;

  const BmkgLocation({
    required this.code,
    required this.name,
    required this.kecamatan,
    required this.kabupaten,
    required this.province,
    required this.description,
    this.desa,
    this.isTemanggung = true,
  });

  String get displayName {
    final List<String> parts = [];
    if (desa != null && desa!.trim().isNotEmpty) {
      final d = desa!.trim();
      parts.add(d.toLowerCase().startsWith('desa') ? d : 'Desa $d');
    }
    if (kecamatan.trim().isNotEmpty) {
      parts.add('Kec. ${kecamatan.trim()}');
    }
    if (kabupaten.trim().isNotEmpty) {
      parts.add('Kab. ${kabupaten.trim()}');
    }
    if (province.trim().isNotEmpty) {
      parts.add('Prov. ${province.trim()}');
    }
    return parts.join(', ');
  }
}

class BmkgLocations {
  // Default wilayah utama: Temanggung - Bulu (Sentra Lereng Sumbing)
  static const BmkgLocation defaultLocation = BmkgLocation(
    code: '33.23.01.2001',
    name: 'Bulu, Temanggung',
    kecamatan: 'Bulu',
    kabupaten: 'Temanggung',
    province: 'Jawa Tengah',
    description: 'Lereng Sumbing • Sentra Tembakau Gurih & Srintil',
    desa: 'Bulu',
    isTemanggung: true,
  );

  /// 1. DAFTAR LENGKAP 38 PROVINSI RESMI DI INDONESIA (Sesuai BMKG & Kemendagri)
  static const List<String> daftarProvinsi = [
    'Jawa Tengah',
    'Jawa Timur',
    'Nusa Tenggara Barat',
    'Daerah Istimewa Yogyakarta',
    'Jawa Barat',
    'DKI Jakarta',
    'Banten',
    'Bali',
    'Sumatera Utara',
    'Sumatera Barat',
    'Riau',
    'Kepulauan Riau',
    'Jambi',
    'Sumatera Selatan',
    'Kepulauan Bangka Belitung',
    'Bengkulu',
    'Lampung',
    'Aceh',
    'Nusa Tenggara Timur',
    'Kalimantan Barat',
    'Kalimantan Tengah',
    'Kalimantan Selatan',
    'Kalimantan Timur',
    'Kalimantan Utara',
    'Sulawesi Utara',
    'Gorontalo',
    'Sulawesi Tengah',
    'Sulawesi Barat',
    'Sulawesi Selatan',
    'Sulawesi Tenggara',
    'Maluku',
    'Maluku Utara',
    'Papua Barat',
    'Papua',
    'Papua Tengah',
    'Papua Pegunungan',
    'Papua Selatan',
    'Papua Barat Daya',
  ];

  /// 2. DAFTAR KABUPATEN / KOTA LENGKAP PER PROVINSI
  static const Map<String, List<String>> daftarKabupatenPerProvinsi = {
    'Jawa Tengah': [
      'Temanggung',
      'Wonosobo',
      'Magelang',
      'Boyolali',
      'Klaten',
      'Kendal',
      'Semarang',
      'Purworejo',
      'Kebumen',
      'Banyumas',
      'Cilacap',
      'Purbalingga',
      'Banjarnegara',
      'Sukoharjo',
      'Karanganyar',
      'Sragen',
      'Wonogiri',
      'Blora',
      'Rembang',
      'Pati',
      'Kudus',
      'Jepara',
      'Demak',
      'Grobogan',
      'Batang',
      'Pekalongan',
      'Pemalang',
      'Tegal',
      'Brebes',
      'Kota Magelang',
      'Kota Surakarta',
      'Kota Salatiga',
      'Kota Semarang',
      'Kota Pekalongan',
      'Kota Tegal',
    ],
    'Jawa Timur': [
      'Jember',
      'Pamekasan',
      'Sumenep',
      'Sampang',
      'Bangkalan',
      'Probolinggo',
      'Pasuruan',
      'Banyuwangi',
      'Bondowoso',
      'Situbondo',
      'Lumajang',
      'Bojonegoro',
      'Tuban',
      'Lamongan',
      'Gresik',
      'Sidoarjo',
      'Mojokerto',
      'Jombang',
      'Nganjuk',
      'Madiun',
      'Magetan',
      'Ngawi',
      'Ponorogo',
      'Pacitan',
      'Kediri',
      'Blitar',
      'Tulungagung',
      'Trenggalek',
      'Malang',
      'Kota Surabaya',
      'Kota Malang',
      'Kota Madiun',
      'Kota Kediri',
      'Kota Blitar',
      'Kota Probolinggo',
      'Kota Pasuruan',
      'Kota Mojokerto',
      'Kota Batu',
    ],
    'Nusa Tenggara Barat': [
      'Lombok Timur',
      'Lombok Tengah',
      'Lombok Barat',
      'Lombok Utara',
      'Kota Mataram',
      'Sumbawa',
      'Sumbawa Barat',
      'Dompu',
      'Bima',
      'Kota Bima',
    ],
    'Daerah Istimewa Yogyakarta': [
      'Sleman',
      'Bantul',
      'Kulon Progo',
      'Gunungkidul',
      'Kota Yogyakarta',
    ],
    'Jawa Barat': [
      'Garut',
      'Majalengka',
      'Sumedang',
      'Bandung',
      'Bandung Barat',
      'Cirebon',
      'Kuningan',
      'Indramayu',
      'Subang',
      'Karawang',
      'Purwakarta',
      'Bogor',
      'Sukabumi',
      'Cianjur',
      'Tasikmalaya',
      'Ciamis',
      'Pangandaran',
      'Bekasi',
      'Kota Bandung',
      'Kota Bogor',
      'Kota Bekasi',
      'Kota Depok',
      'Kota Cimahi',
      'Kota Tasikmalaya',
      'Kota Cirebon',
      'Kota Sukabumi',
      'Kota Banjar',
    ],
    'DKI Jakarta': [
      'Jakarta Pusat',
      'Jakarta Selatan',
      'Jakarta Barat',
      'Jakarta Timur',
      'Jakarta Utara',
      'Kepulauan Seribu',
    ],
    'Banten': [
      'Serang',
      'Pandeglang',
      'Lebak',
      'Tangerang',
      'Kota Tangerang',
      'Kota Tangerang Selatan',
      'Kota Serang',
      'Kota Cilegon',
    ],
    'Bali': [
      'Badung',
      'Bangli',
      'Buleleng',
      'Gianyar',
      'Jembrana',
      'Karangasem',
      'Klungkung',
      'Tabanan',
      'Kota Denpasar',
    ],
    'Sumatera Utara': [
      'Deli Serdang',
      'Karo',
      'Dairi',
      'Simalungun',
      'Toba',
      'Tapanuli Utara',
      'Langkat',
      'Kota Medan',
    ],
    'Sumatera Barat': [
      'Tanah Datar',
      'Agam',
      'Lima Puluh Kota',
      'Solok',
      'Kota Padang',
      'Kota Bukittinggi',
    ],
    'Lampung': [
      'Lampung Selatan',
      'Lampung Tengah',
      'Lampung Timur',
      'Tanggamus',
      'Kota Bandar Lampung',
    ],
    'Sulawesi Selatan': [
      'Bone',
      'Bantaeng',
      'Jeneponto',
      'Gowa',
      'Maros',
      'Kota Makassar',
    ],
  };

  /// 3. DAFTAR KECAMATAN PER KABUPATEN POPULER
  static const Map<String, List<String>> daftarKecamatanPerKabupaten = {
    // --- KABUPATEN TEMANGGUNG (LENGKAP 20 KECAMATAN) ---
    'Temanggung': [
      'Bulu',
      'Parakan',
      'Kledung',
      'Ngadirejo',
      'Tlogomulyo',
      'Bansari',
      'Selopampang',
      'Candiroto',
      'Tretep',
      'Tembarak',
      'Temanggung',
      'Kedu',
      'Kranggan',
      'Pringsurat',
      'Kaloran',
      'Kandangan',
      'Jumo',
      'Bejen',
      'Wonoboyo',
      'Gemawang',
    ],
    'Wonosobo': [
      'Kejajar',
      'Garung',
      'Mojotengah',
      'Wonosobo',
      'Selomerto',
      'Wadaslintang',
      'Kepil',
      'Sapuran',
      'Kalikajar',
      'Kertek',
      'Leksono',
      'Sukoharjo',
      'Watumalang',
      'Kaliwiro',
      'Kalibawang',
    ],
    'Magelang': [
      'Windusari',
      'Bandongan',
      'Kaliangkrik',
      'Salaman',
      'Borobudur',
      'Muntilan',
      'Mungkid',
      'Tempuran',
      'Kajoran',
      'Secang',
      'Grabag',
      'Ngablak',
      'Pakis',
      'Sawangan',
      'Dukun',
      'Srumbung',
    ],
    'Boyolali': [
      'Selo',
      'Cepogo',
      'Musuk',
      'Ampel',
      'Gladagsari',
      'Boyolali',
      'Mojosongo',
      'Teras',
      'Banyudono',
      'Sambi',
      'Ngemplak',
      'Simo',
      'Karanggede',
    ],
    'Klaten': [
      'Manisrenggo',
      'Prambanan',
      'Jogonalan',
      'Gantiwarno',
      'Wedi',
      'Bayat',
      'Cawas',
      'Trucuk',
      'Kebonarum',
      'Karangnongko',
      'Kemalang',
      'Delanggu',
      'Polanharjo',
      'Jatinom',
      'Tulung',
      'Klaten Utara',
      'Klaten Tengah',
      'Klaten Selatan',
    ],
    'Lumajang': [
      'Candipuro',
      'Pasirian',
      'Tempeh',
      'Lumajang',
      'Senduro',
      'Pasrujambe',
      'Pronojiwo',
      'Yosowilangun',
      'Kunir',
      'Rowokangkung',
      'Tekung',
      'Jatiroto',
      'Randuagung',
      'Sukodono',
      'Padang',
      'Gucialit',
      'Klakah',
      'Ranuyoso',
      'Kedungjajang',
      'Sumbersuko',
      'Tempursari',
    ],
    'Probolinggo': [
      'Paiton',
      'Kraksaan',
      'Besuk',
      'Kotaanyar',
      'Pakuniran',
      'Gading',
      'Krucil',
      'Tiris',
      'Banyuanyar',
      'Tegalsiwalan',
      'Leces',
      'Bantaran',
      'Kuripan',
      'Sumber',
      'Sukapura',
      'Lumbang',
      'Wonomerto',
      'Tongas',
      'Sumberasih',
      'Dringu',
      'Gending',
      'Maron',
      'Krejengan',
      'Pejarakan',
    ],
    'Jember': [
      'Jember',
      'Ajung',
      'Ambulu',
      'Arjasa',
      'Balung',
      'Bangsalsari',
      'Gumukmas',
      'Jelbuk',
      'Jenggawah',
      'Kalisat',
      'Kencong',
      'Ledokombo',
      'Mayang',
      'Mumbulsari',
      'Puger',
      'Rambipuji',
      'Semboro',
      'Silo',
      'Sukorambi',
      'Sukowono',
      'Sumberbaru',
      'Tanggul',
      'Tempurejo',
      'Umbulsari',
      'Wuluhan',
      'Kaliwates',
      'Patrang',
      'Sumbersari',
    ],
    'Pamekasan': [
      'Pamekasan',
      'Proppo',
      'Tlanakan',
      'Pademawu',
      'Galis',
      'Larangan',
      'Kadur',
      'Pegantenan',
      'Pakong',
      'Waru',
      'Batu Marmar',
      'Pasean',
      'Palengaan',
    ],
    'Sumenep': [
      'Sumenep',
      'Batuan',
      'Kalianget',
      'Manding',
      'Talango',
      'Bluto',
      'Saronggi',
      'Lenteng',
      'Guluk-Guluk',
      'Gandil',
      'Pragaan',
      'Ambunten',
      'Pasongsongan',
      'Rubaru',
      'Dungkek',
      'Gapura',
      'Batang Batang',
    ],
    'Lombok Timur': [
      'Selong',
      'Sikur',
      'Aikmel',
      'Pringgabaya',
      'Masbagik',
      'Suela',
      'Sembalun',
      'Wanasaba',
      'Terara',
      'Montong Gading',
      'Keruak',
      'Jerowaru',
      'Sakra',
      'Sakra Barat',
      'Sakra Timur',
      'Labuhan Haji',
      'Pringgasela',
      'Sambelia',
      'Lenek',
    ],
    'Sleman': [
      'Sleman',
      'Tempel',
      'Turi',
      'Pakem',
      'Cangkringan',
      'Ngaglik',
      'Mlati',
      'Seyegan',
      'Minggir',
      'Moyudan',
      'Godean',
      'Gamping',
      'Depok',
      'Kalasan',
      'Berbah',
      'Prambanan',
      'Ngemplak',
    ],
    'Bantul': [
      'Bantul',
      'Sedayu',
      'Kasihan',
      'Sewon',
      'Pajangan',
      'Bambanglipuro',
      'Pandak',
      'Srandakan',
      'Sanden',
      'Kretek',
      'Pundong',
      'Imogiri',
      'Dlingo',
      'Pleret',
      'Piyungan',
      'Banguntapan',
      'Jetis',
    ],
    'Garut': [
      'Garut Kota',
      'Tarogong Kaler',
      'Tarogong Kidul',
      'Samarang',
      'Pasirwangi',
      'Cikajang',
      'Cisurupan',
      'Bayongbong',
      'Cilawu',
      'Leles',
      'Kadungora',
      'Wanaraja',
      'Pangatikan',
      'Sukawening',
      'Karangpawitan',
      'Banyuresmi',
    ],
  };

  /// 4. DAFTAR LENGKAP SELURUH DESA / KELURAHAN PER KECAMATAN DI KABUPATEN TEMANGGUNG
  static const Map<String, List<String>> daftarDesaTemanggung = {
    'Bulu': [
      'Bulu',
      'Lamuk',
      'Danurejo',
      'Gondosuli',
      'Campursari',
      'Gandu',
      'Malangsari',
      'Mondoretno',
      'Pandemulyo',
      'Pasuruhan',
      'Pengilon',
      'Pagergunung',
      'Tegallurung',
      'Wonosari',
      'Wonotirto',
    ],
    'Parakan': [
      'Parakan Kauman',
      'Parakan Wetan',
      'Dangkel',
      'Mandisari',
      'Nglondong',
      'Ringinanom',
      'Sunggingsari',
      'Traji',
      'Wanutengah',
      'Watukumpul',
    ],
    'Kledung': [
      'Kledung',
      'Batursari',
      'Jambu',
      'Kalirejo',
      'Kwadungan Gunung',
      'Kwadungan Jurang',
      'Paponan',
      'Petarangan',
      'Pringapus',
      'Tlahap Baru',
      'Tlahap Wetan',
    ],
    'Ngadirejo': [
      'Ngadirejo',
      'Campursari',
      'Dlimoyo',
      'Gandu',
      'Gejagan',
      'Giripurno',
      'Kataan',
      'Katekan',
      'Mangunsari',
      'Medari',
      'Munggangsari',
      'Petirejo',
      'Tegalrejo',
    ],
    'Tlogomulyo': [
      'Tlogomulyo',
      'Lamuk',
      'Balerejo',
      'Candisari',
      'Kerokan',
      'Langgeng',
      'Legoksari',
      'Losari',
      'Tanjungsari',
      'Tleter',
    ],
    'Bansari': [
      'Bansari',
      'Balesari',
      'Candisari',
      'Gunungsari',
      'Mojosari',
      'Pringapus',
      'Rejosari',
      'Tanurejo',
      'Tlogowero',
    ],
    'Selopampang': [
      'Selopampang',
      'Bulan',
      'Gambasan',
      'Kacepit',
      'Ngaditirto',
      'Plumbon',
      'Salamrejo',
      'Tanggulan',
    ],
    'Candiroto': [
      'Candiroto',
      'Bantir',
      'Batursari',
      'Canggal',
      'Kentengsari',
      'Krawitan',
      'Lempuyang',
      'Muneng',
      'Plosogaden',
      'Sidoharjo',
    ],
    'Tretep': [
      'Tretep',
      'Bojong',
      'Bonjor',
      'Campurejo',
      'Donorojo',
      'Simpar',
      'Sigedong',
      'Tempelsari',
      'Tiertomulyo',
    ],
    'Tembarak': [
      'Tembarak',
      'Botoputih',
      'Drono',
      'Gandu',
      'Kemloko',
      'Menggoro',
      'Purwodadi',
      'Tawangsari',
      'Wonokerso',
    ],
    'Temanggung': [
      'Temanggung I',
      'Temanggung II',
      'Butuh',
      'Giyanti',
      'Jampiroso',
      'Jampirejo',
      'Jurang',
      'Kowangan',
      'Kertosari',
      'Madureso',
      'Manding',
      'Mudal',
      'Sidorejo',
      'Walitelon Selatan',
      'Walitelon Utara',
    ],
    'Kedu': [
      'Kedu',
      'Bojonegoro',
      'Candimulyo',
      'Danurejo',
      'Karangtejo',
      'Kundisari',
      'Mojotengah',
      'Salamsari',
      'Tegalsari',
    ],
    'Kranggan': [
      'Kranggan',
      'Badran',
      'Bengkal',
      'Kemloko',
      'Klepu',
      'Kramat',
      'Ngropoh',
      'Nguwet',
      'Pare',
      'Pendowo',
      'Purwosari',
      'Sanggrahan',
    ],
    'Pringsurat': [
      'Pringsurat',
      'Gowak',
      'Karangwuni',
      'Kebumen',
      'Klepu',
      'Kupen',
      'Ngipik',
      'Nglorog',
      'Pingit',
      'Rejosari',
      'Soborejo',
      'Soropadan',
      'Wonokerso',
    ],
    'Kaloran': [
      'Kaloran',
      'Gandon',
      'Gandunia',
      'Geblog',
      'Getas',
      'Kalimanggis',
      'Kemiri',
      'Kwarakan',
      'Tegowanuh',
      'Tempuran',
      'Tleter',
    ],
    'Kandangan': [
      'Kandangan',
      'Baledu',
      'Blimbing',
      'Caruban',
      'Gesing',
      'Kedawung',
      'Kedungumpul',
      'Malebo',
      'Margolelo',
      'Ngemplak',
      'Rowo',
      'Samiranan',
      'Tlogopucang',
      'Wadas',
    ],
    'Jumo': [
      'Jumo',
      'Gedongsari',
      'Giyono',
      'Gununggempol',
      'Jamusan',
      'Jombor',
      'Karangtejo',
      'Kertorejo',
      'Morobongo',
      'Padureso',
      'Sukomarto',
    ],
    'Bejen': [
      'Bejen',
      'Banjarsari',
      'Congkrang',
      'Duren',
      'Jlegong',
      'Kebondalem',
      'Kemuning',
      'Larangan Luwok',
      'Lowungu',
      'Ngalian',
      'Petung',
      'Prangkokan',
      'Selosabrang',
      'Tanjungsari',
    ],
    'Wonoboyo': [
      'Wonoboyo',
      'Cemoro',
      'Kebonsari',
      'Pitrosari',
      'Purwosari',
      'Rejosari',
      'Semen',
      'Tawangsari',
      'Tening',
      'Wates',
      'Wonocoyo',
    ],
    'Gemawang': [
      'Gemawang',
      'Banaran',
      'Cles',
      'Jambuwok',
      'Kalirejo',
      'Karangseneng',
      'Krempong',
      'Muncar',
      'Ngadisepi',
      'Sucen',
    ],

    // --- KABUPATEN LUMAJANG (LENGKAP 21 KECAMATAN) ---
    'Candipuro': ['Candipuro', 'Jarit', 'Jugosari', 'Sumberrejo', 'Sumberwuluh', 'Tambahrejo', 'Penanggal', 'Kloposawit', 'Tumpeng', 'Sumbermujur'],
    'Pasirian': ['Pasirian', 'Bades', 'Bago', 'Condro', 'Madiredo', 'Nguter', 'Selok Awar-Awar', 'Selok Anyar', 'Sememu'],
    'Tempeh': ['Tempeh Tengah', 'Tempeh Lor', 'Tempeh Kidul', 'Besuk', 'Gesang', 'Jatisari', 'Jokarto', 'Pandanarum', 'Pandanwangi', 'Pulo', 'Sumberjati', 'Wongorejo'],
    'Lumajang': ['Rogotrunan', 'Ditotrunan', 'Tompokersan', 'Citrodiwangsan', 'Kepuharjo', 'Jogotrunan', 'Jogoyudan', 'Banjarwaru', 'Blukon', 'Denok', 'Labruk Lor'],
    'Senduro': ['Senduro', 'Argosari', 'Bedayu', 'Burno', 'Kandangan', 'Kandangtepus', 'Pandansari', 'Purworejo', 'Ranupani', 'Sarikemuning'],
    'Pasrujambe': ['Pasrujambe', 'Jambearum', 'Jambekumbu', 'Kertosari', 'Pagowan', 'Sukorejo', 'Karanganom'],
    'Pronojiwo': ['Pronojiwo', 'Oro-Oro Ombo', 'Sumberurip', 'Supiturang', 'Tamanayu', 'Sidomulyo'],
    'Yosowilangun': ['Yosowilangun Lor', 'Yosowilangun Kidul', 'Darungan', 'Karanganyar', 'Karangrejo', 'Krajan Lor', 'Kraton', 'Mbingkat', 'Nogosari', 'Tunjungrejo', 'Wotgalih'],
    'Kunir': ['Kunir Lor', 'Kunir Kidul', 'Dorogowok', 'Jatirejo', 'Jatimulyo', 'Kabangan', 'Karanglo', 'Kedungmoro', 'Sukorejo', 'Sukosari'],
    'Rowokangkung': ['Rowokangkung', 'Dawuhan Wetan', 'Kedungrejo', 'Nogosari', 'Sidorejo', 'Sumbersari'],
    'Tekung': ['Tekung', 'Karangbendo', 'Klampok', 'Mangunsari', 'Tukum', 'Wonogriyo', 'Wonokerto', 'Wonosari'],
    'Jatiroto': ['Jatiroto', 'Banyuputih Kidul', 'Kaliboto Lor', 'Kaliboto Kidul', 'Rojopolo', 'Sukosari'],
    'Randuagung': ['Randuagung', 'Banyuputih Lor', 'Buwek', 'Gedangmas', 'Kalidilem', 'Ledoktempuro', 'Pajarakan', 'Ranulogong', 'Salak', 'Tunjung'],
    'Sukodono': ['Sukodono', 'Bondoyudo', 'Dawuhan Lor', 'Karangsari', 'Kebonagung', 'Klampok', 'Kutorenon', 'Selokbesuki', 'Sumberejo', 'Uranggantung'],
    'Padang': ['Padang', 'Babakan', 'Barat', 'Bodang', 'Kedawung', 'Mojo', 'Tangge'],
    'Gucialit': ['Gucialit', 'Dadapan', 'Jeruk', 'Kenongo', 'Pakel', 'Sombo', 'Tumpeng', 'Wonokerto'],
    'Klakah': ['Klakah', 'Duren', 'Kebonan', 'Kudus', 'Mlawang', 'Ranupakis', 'Sawaran Lor', 'Sruni', 'Tegalciut', 'Tegalrandu'],
    'Ranuyoso': ['Ranuyoso', 'Alun-Alun', 'Jenggrong', 'Meninjo', 'Penawungan', 'Ranubedali', 'Samaran', 'Tegalbangsri', 'Wates Kulon', 'Wates Wetan', 'Wonoayu'],
    'Kedungjajang': ['Kedungjajang', 'Bandaran', 'Bence', 'Curahpetung', 'Grobogan', 'Jowo', 'Krasak', 'Pandansari', 'Sawaran Kulon', 'Tempursari', 'Umbul', 'Wonorejo'],
    'Sumbersuko': ['Sumbersuko', 'Grati', 'Kebonsari', 'Labruk Kidul', 'Mojosari', 'Petahunan', 'Purwosono', 'Sentul'],
    'Tempursari': ['Tempursari', 'Bulu Jaran Lor', 'Bulu Jaran Kidul', 'Pundungsari', 'Purorejo', 'Tegalrejo', 'Tempurejo'],

    // --- KABUPATEN JEMBER ---
    'Tanggul': ['Tanggul Kulon', 'Tanggul Wetan', 'Klatakan', 'Darmaungan', 'Manggisan', 'Patemon', 'Selodakon', 'Kramat Sukoharjo'],
    'Jember': ['Jember Kidul', 'Jember Lor', 'Kepatihan', 'Kaliwates', 'Patrang', 'Sumbersari'],
  };

  /// Daftar Master Lokasi BMKG terpetakan
  static const List<BmkgLocation> all = [
    // --- KABUPATEN TEMANGGUNG (SENTRA UTAMA) ---
    BmkgLocation(
      code: '33.23.01.2001',
      name: 'Bulu, Temanggung',
      kecamatan: 'Bulu',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Lereng Sumbing • Sentra Tembakau Gurih & Srintil',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.09.2001',
      name: 'Parakan, Temanggung',
      kecamatan: 'Parakan',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Pusat Perdagangan & Pasar Niaga Tembakau Legendaris',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.16.2001',
      name: 'Kledung, Temanggung',
      kecamatan: 'Kledung',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Celah Sindoro-Sumbing • Dataran Tinggi Tembakau Dingin',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.10.2001',
      name: 'Ngadirejo, Temanggung',
      kecamatan: 'Ngadirejo',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Lereng Sindoro • Tembakau Rajangan Halus Berkualitas',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.17.2001',
      name: 'Bansari, Temanggung',
      kecamatan: 'Bansari',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Lereng Timur Sindoro • Daun Tembakau Emas Prima',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.03.2001',
      name: 'Tlogomulyo, Temanggung',
      kecamatan: 'Tlogomulyo',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Sentra Legendaris Tembakau Srintil Lamuk Termahal',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.04.2001',
      name: 'Selopampang, Temanggung',
      kecamatan: 'Selopampang',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Lereng Selatan Sumbing • Aroma Wangi Khas',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.12.2001',
      name: 'Candiroto, Temanggung',
      kecamatan: 'Candiroto',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Kawasan Sindoro Utara • Daun Tembakau Tebal Mantap',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.14.2001',
      name: 'Tretep, Temanggung',
      kecamatan: 'Tretep',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Dataran Tinggi Lereng Prahu & Sindoro Utara',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.20.2001',
      name: 'Tembarak, Temanggung',
      kecamatan: 'Tembarak',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Lereng Sumbing Timur • Penghasil Rajangan Halus',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.02.2001',
      name: 'Temanggung Kota',
      kecamatan: 'Temanggung',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Pusat Kota & Administrasi Temanggung',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.19.2001',
      name: 'Kedu, Temanggung',
      kecamatan: 'Kedu',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Wilayah Lembah Pertanian Subur',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.05.2001',
      name: 'Kranggan, Temanggung',
      kecamatan: 'Kranggan',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Kawasan Pertanian Selatan Temanggung',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.06.2001',
      name: 'Pringsurat, Temanggung',
      kecamatan: 'Pringsurat',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Jalur Penghubung Magelang-Semarang',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.07.2001',
      name: 'Kaloran, Temanggung',
      kecamatan: 'Kaloran',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Lereng Perbukitan Timur Gunung Payung',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.08.2001',
      name: 'Kandangan, Temanggung',
      kecamatan: 'Kandangan',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Kawasan Perkebunan Temanggung Timur',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.11.2001',
      name: 'Jumo, Temanggung',
      kecamatan: 'Jumo',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Kawasan Sentra Tembakau Lembah Sindoro',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.13.2001',
      name: 'Bejen, Temanggung',
      kecamatan: 'Bejen',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Kawasan Perbukitan Temanggung Utara',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.15.2001',
      name: 'Wonoboyo, Temanggung',
      kecamatan: 'Wonoboyo',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Wilayah Tembakau Dataran Tinggi Perbatasan Kendal',
      isTemanggung: true,
    ),
    BmkgLocation(
      code: '33.23.18.2001',
      name: 'Gemawang, Temanggung',
      kecamatan: 'Gemawang',
      kabupaten: 'Temanggung',
      province: 'Jawa Tengah',
      description: 'Kawasan Perkebunan Kopi & Tembakau',
      isTemanggung: true,
    ),

    // --- SENTRA TEMBAKAU LAINNYA DI INDONESIA ---
    BmkgLocation(
      code: '33.07.01.2001',
      name: 'Kejajar, Wonosobo',
      kecamatan: 'Kejajar',
      kabupaten: 'Wonosobo',
      province: 'Jawa Tengah',
      description: 'Sentra Tembakau Garangan Dataran Tinggi Dieng',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '33.08.01.2001',
      name: 'Windusari, Magelang',
      kecamatan: 'Windusari',
      kabupaten: 'Magelang',
      province: 'Jawa Tengah',
      description: 'Lereng Sumbing Sisi Timur Magelang',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '33.09.01.2001',
      name: 'Selo, Boyolali',
      kecamatan: 'Selo',
      kabupaten: 'Boyolali',
      province: 'Jawa Tengah',
      description: 'Sentra Tembakau Lereng Merapi-Merbabu',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '35.09.01.2001',
      name: 'Jember, Jawa Timur',
      kecamatan: 'Jember',
      kabupaten: 'Jember',
      province: 'Jawa Timur',
      description: 'Sentra Tembakau Cerutu Na-Oogst & Besuki',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '35.09.19.2001',
      name: 'Tanggul, Jember',
      kecamatan: 'Tanggul',
      kabupaten: 'Jember',
      province: 'Jawa Timur',
      description: 'Sentra Tembakau Besuki Na-Oogst & Kasturi Tanggul',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '35.08.10.2001',
      name: 'Pasrujambe, Lumajang',
      kecamatan: 'Pasrujambe',
      kabupaten: 'Lumajang',
      province: 'Jawa Timur',
      description: 'Lereng Semeru • Sentra Tembakau White Burley',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '35.08.05.2001',
      name: 'Tempeh, Lumajang',
      kecamatan: 'Tempeh',
      kabupaten: 'Lumajang',
      province: 'Jawa Timur',
      description: 'Sentra Tembakau Kasturi & Rajangan Lumajang',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '35.08.06.2001',
      name: 'Lumajang, Lumajang',
      kecamatan: 'Lumajang',
      kabupaten: 'Lumajang',
      province: 'Jawa Timur',
      description: 'Pusat Wilayah Pertanian Lumajang',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '35.28.01.2001',
      name: 'Pamekasan, Madura',
      kecamatan: 'Pamekasan',
      kabupaten: 'Pamekasan',
      province: 'Jawa Timur',
      description: 'Sentra Tembakau Madura Aroma Gurih & Tajam',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '35.29.01.2001',
      name: 'Sumenep, Madura',
      kecamatan: 'Sumenep',
      kabupaten: 'Sumenep',
      province: 'Jawa Timur',
      description: 'Sentra Tembakau Madura Timur',
      isTemanggung: false,
    ),
    BmkgLocation(
      code: '52.03.01.2001',
      name: 'Lombok Timur, NTB',
      kecamatan: 'Lombok Timur',
      kabupaten: 'Lombok Timur',
      province: 'Nusa Tenggara Barat',
      description: 'Sentra Tembakau Virginia Oven Terbaik',
      isTemanggung: false,
    ),
  ];

  /// Menemukan lokasi BMKG yang paling cocok dengan teks input / profil petani
  static BmkgLocation findMatchingLocation(String? query) {
    if (query == null || query.trim().isEmpty) return defaultLocation;
    final q = query.toLowerCase().trim();

    // 1. Cocokkan persis kombinasi kecamatan dan kabupaten
    for (final loc in all) {
      if (q.contains(loc.kecamatan.toLowerCase()) && q.contains(loc.kabupaten.toLowerCase())) {
        return loc;
      }
    }

    // 2. Cocokkan dengan nama kecamatan
    for (final loc in all) {
      if (q.contains(loc.kecamatan.toLowerCase())) {
        return loc;
      }
    }

    // 3. Cocokkan dengan nama lengkap
    for (final loc in all) {
      if (q.contains(loc.name.toLowerCase()) || loc.name.toLowerCase().contains(q)) {
        return loc;
      }
    }

    // 4. Cocokkan dengan kabupaten
    for (final loc in all) {
      if (q.contains(loc.kabupaten.toLowerCase())) {
        return loc;
      }
    }

    return defaultLocation;
  }

  /// Membuat BmkgLocation dari komponen spesifik Provinsi, Kabupaten, Kecamatan, Desa
  static BmkgLocation createFromComponents({
    String? provinsi,
    required String kabupaten,
    required String kecamatan,
    String? desa,
  }) {
    final matched = findMatchingLocation('$kecamatan $kabupaten');
    final String cleanDesa = (desa != null && desa.trim().isNotEmpty) ? desa.trim() : '';
    final String cleanKec = kecamatan.trim().isNotEmpty ? kecamatan.trim() : matched.kecamatan;
    final String cleanKab = kabupaten.trim().isNotEmpty ? kabupaten.trim() : matched.kabupaten;
    final String cleanProv = (provinsi != null && provinsi.trim().isNotEmpty)
        ? provinsi.trim()
        : matched.province;

    final String fullName = cleanDesa.isNotEmpty
        ? '$cleanDesa, $cleanKec, $cleanKab, $cleanProv'
        : '$cleanKec, $cleanKab, $cleanProv';

    return BmkgLocation(
      code: matched.code,
      name: fullName,
      kecamatan: cleanKec,
      kabupaten: cleanKab,
      province: cleanProv,
      description: matched.description,
      desa: cleanDesa.isNotEmpty ? cleanDesa : null,
      isTemanggung: cleanKab.toLowerCase().contains('temanggung'),
    );
  }

  /// Ekstraksi komponen Desa, Kecamatan, Kabupaten, Provinsi dari string alamat
  static Map<String, String> parseAddressComponents(String fullAddress) {
    if (fullAddress.trim().isEmpty) {
      return {
        'desa': '',
        'kecamatan': 'Bulu',
        'kabupaten': 'Temanggung',
        'provinsi': 'Jawa Tengah',
      };
    }

    final rawParts = fullAddress.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (rawParts.isEmpty) {
      return {
        'desa': '',
        'kecamatan': 'Bulu',
        'kabupaten': 'Temanggung',
        'provinsi': 'Jawa Tengah',
      };
    }

    String? foundProv;
    String? foundKab;
    String? foundKec;
    String? foundDesa;

    final remainingParts = <String>[];

    for (final part in rawParts) {
      final lower = part.toLowerCase();

      // 1. Cek prefix Provinsi (Prov. atau Provinsi)
      if (lower.startsWith('prov.') || lower.startsWith('provinsi')) {
        final clean = part.replaceAll(RegExp(r'^(prov\.|provinsi)\s*', caseSensitive: false), '').trim();
        foundProv = _matchProvinsi(clean);
        continue;
      }

      // 2. Cek prefix Kabupaten / Kota
      if (lower.startsWith('kab.') || lower.startsWith('kabupaten') || lower.startsWith('kota')) {
        final clean = part.replaceAll(RegExp(r'^(kab\.|kabupaten|kota)\s*', caseSensitive: false), '').trim();
        foundKab = clean;
        continue;
      }

      // 3. Cek prefix Kecamatan
      if (lower.startsWith('kec.') || lower.startsWith('kecamatan')) {
        final clean = part.replaceAll(RegExp(r'^(kec\.|kecamatan)\s*', caseSensitive: false), '').trim();
        foundKec = clean;
        continue;
      }

      // 4. Cek prefix Desa / Kelurahan
      if (lower.startsWith('desa') || lower.startsWith('kelurahan') || lower.startsWith('kel.') || lower.startsWith('ds.')) {
        final clean = part.replaceAll(RegExp(r'^(desa|kelurahan|kel\.|ds\.)\s*', caseSensitive: false), '').trim();
        foundDesa = clean;
        continue;
      }

      // Cek apakah part sama persis atau cocok dengan salah satu nama provinsi resmi
      final provMatch = _matchProvinsi(part);
      if (provMatch != null) {
        foundProv = provMatch;
        continue;
      }

      remainingParts.add(part);
    }

    // Ekstraksi sisa bagian yang belum terpetakan prefix
    // Prioritas 1: Provinsi
    for (final part in List<String>.from(remainingParts)) {
      if (foundProv == null) {
        final p = _matchProvinsi(part);
        if (p != null) {
          foundProv = p;
          remainingParts.remove(part);
          break;
        }
      }
    }

    // Prioritas 2: Kabupaten
    for (final part in List<String>.from(remainingParts)) {
      if (foundKab == null) {
        final k = _matchKabupaten(part, foundProv);
        if (k != null) {
          foundKab = k;
          remainingParts.remove(part);
          break;
        }
      }
    }

    // Prioritas 3: Kecamatan
    for (final part in List<String>.from(remainingParts)) {
      if (foundKec == null) {
        foundKec = part;
        remainingParts.remove(part);
        break;
      }
    }

    // Prioritas 4: Desa
    for (final part in List<String>.from(remainingParts)) {
      if (foundDesa == null) {
        foundDesa = part;
        remainingParts.remove(part);
        break;
      }
    }

    // Jika Kabupaten ditemukan namun Provinsi belum, simpulkan Provinsi dari Kabupaten tersebut
    if (foundKab != null && foundProv == null) {
      for (final entry in daftarKabupatenPerProvinsi.entries) {
        if (entry.value.any((k) => k.toLowerCase() == foundKab!.toLowerCase())) {
          foundProv = entry.key;
          break;
        }
      }
    }

    final String finalProv = foundProv ?? 'Jawa Tengah';
    final listKab = getKabupatenList(finalProv);
    String finalKab = foundKab ?? '';
    if (finalKab.isEmpty || !listKab.any((k) => k.toLowerCase() == finalKab.toLowerCase())) {
      final match = listKab.firstWhere(
        (k) => k.toLowerCase().contains(finalKab.toLowerCase()) || finalKab.toLowerCase().contains(k.toLowerCase()),
        orElse: () => listKab.isNotEmpty ? listKab.first : 'Temanggung',
      );
      finalKab = match;
    } else {
      finalKab = listKab.firstWhere((k) => k.toLowerCase() == finalKab.toLowerCase(), orElse: () => finalKab);
    }

    final listKec = getKecamatanList(finalKab);
    String finalKec = foundKec ?? '';
    if (finalKec.isEmpty || !listKec.any((k) => k.toLowerCase() == finalKec.toLowerCase())) {
      final match = listKec.firstWhere(
        (k) => k.toLowerCase() == finalKec.toLowerCase() ||
               k.toLowerCase().contains(finalKec.toLowerCase()) ||
               finalKec.toLowerCase().contains(k.toLowerCase()),
        orElse: () => listKec.isNotEmpty ? listKec.first : 'Bulu',
      );
      if (finalKec.isNotEmpty && listKec.contains(finalKec)) {
        finalKec = finalKec;
      } else {
        finalKec = match;
      }
    } else {
      finalKec = listKec.firstWhere((k) => k.toLowerCase() == finalKec.toLowerCase(), orElse: () => finalKec);
    }

    return {
      'provinsi': finalProv,
      'kabupaten': finalKab,
      'kecamatan': finalKec,
      'desa': foundDesa ?? '',
    };
  }

  static String? _matchProvinsi(String text) {
    final clean = text.toLowerCase().trim();
    for (final p in daftarProvinsi) {
      if (p.toLowerCase() == clean || p.toLowerCase().replaceAll(' ', '') == clean.replaceAll(' ', '')) {
        return p;
      }
    }
    for (final p in daftarProvinsi) {
      if (clean.contains(p.toLowerCase()) || p.toLowerCase().contains(clean)) {
        return p;
      }
    }
    return null;
  }

  static String? _matchKabupaten(String text, String? provinsi) {
    final clean = text.toLowerCase().trim();
    if (provinsi != null && daftarKabupatenPerProvinsi.containsKey(provinsi)) {
      final kabs = daftarKabupatenPerProvinsi[provinsi]!;
      for (final k in kabs) {
        if (k.toLowerCase() == clean || clean.contains(k.toLowerCase()) || k.toLowerCase().contains(clean)) {
          return k;
        }
      }
    }
    for (final entry in daftarKabupatenPerProvinsi.entries) {
      for (final k in entry.value) {
        if (k.toLowerCase() == clean || clean.contains(k.toLowerCase()) || k.toLowerCase().contains(clean)) {
          return k;
        }
      }
    }
    return null;
  }

  /// Mendapatkan daftar Kabupaten untuk provinsi tertentu
  static List<String> getKabupatenList(String provinsi) {
    final list = daftarKabupatenPerProvinsi[provinsi];
    if (list != null && list.isNotEmpty) return list;
    return ['Temanggung', 'Wonosobo', 'Magelang', 'Boyolali'];
  }

  /// Mendapatkan daftar Kecamatan untuk kabupaten tertentu
  static List<String> getKecamatanList(String kabupaten) {
    // 1. Cek langsung di kamus data
    final list = daftarKecamatanPerKabupaten[kabupaten];
    if (list != null && list.isNotEmpty) return list;

    // 2. Cek kecocokan parsial nama kabupaten
    for (final entry in daftarKecamatanPerKabupaten.entries) {
      if (kabupaten.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(kabupaten.toLowerCase())) {
        return entry.value;
      }
    }

    // 3. Fallback: buatkan daftar kecamatan pusat/wilayah untuk kabupaten tersebut
    final clean = kabupaten.replaceAll(RegExp(r'^(Kabupaten|Kota)\s+', caseSensitive: false), '').trim();
    return [
      clean,
      '$clean Kota',
      '$clean Barat',
      '$clean Timur',
      '$clean Utara',
      '$clean Selatan',
    ];
  }

  /// Mendapatkan daftar Desa untuk kecamatan tertentu
  static List<String> getDesaList(String kecamatan) {
    final list = daftarDesaTemanggung[kecamatan];
    if (list != null && list.isNotEmpty) return list;
    return [];
  }
}
