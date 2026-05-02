import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Model representing a currency
@immutable
class Currency extends Equatable {
  /// The unique code of the currency (e.g., USD, INR)
  final String code;

  /// The symbol of the currency (e.g., $, ₹)
  final String symbol;

  /// The name of the currency (e.g., US Dollar, Indian Rupee)
  final String name;

  /// The flag emoji of the country associated with the currency
  final String flag;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });

  @override
  List<Object?> get props => [code, symbol, name, flag];

  /// Create a copy of this currency with the given fields replaced
  Currency copyWith({
    String? code,
    String? symbol,
    String? name,
    String? flag,
  }) {
    return Currency(
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      flag: flag ?? this.flag,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'code': code,
        'symbol': symbol,
        'name': name,
        'flag': flag,
      };

  /// Create from JSON
  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        flag: json['flag'] as String,
      );
}

/// List of common currencies
class Currencies {
  /// Indian Rupee (default)
  static const Currency inr = Currency(
    code: 'TRY',
    symbol: '₺',
    name: 'Türk Lirası',
    flag: '🇮🇳',
  );

  /// US Dollar
  static const Currency usd = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    flag: '🇺🇸',
  );

  /// Euro
  static const Currency eur = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    flag: '🇪🇺',
  );

  /// British Pound
  static const Currency gbp = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    flag: '🇬🇧',
  );

  /// Japanese Yen
  static const Currency jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    flag: '🇯🇵',
  );

  /// Canadian Dollar
  static const Currency cad = Currency(
    code: 'CAD',
    symbol: 'C\$',
    name: 'Canadian Dollar',
    flag: '🇨🇦',
  );

  /// Australian Dollar
  static const Currency aud = Currency(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
    flag: '🇦🇺',
  );

  /// Chinese Yuan
  static const Currency cny = Currency(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
    flag: '🇨🇳',
  );

  /// Swiss Franc
  static const Currency chf = Currency(
    code: 'CHF',
    symbol: 'Fr',
    name: 'Swiss Franc',
    flag: '🇨🇭',
  );

  /// Singapore Dollar
  static const Currency sgd = Currency(
    code: 'SGD',
    symbol: 'S\$',
    name: 'Singapore Dollar',
    flag: '🇸🇬',
  );

  /// List of all available currencies (200+). Flags are intentionally omitted.
  static final List<Currency> all = _buildAllCurrencies();

  static List<Currency> _buildAllCurrencies() {
    // Start with explicitly defined commonly used constants
    final List<Currency> list = [
      inr,
      usd,
      eur,
      gbp,
      jpy,
      cad,
      aud,
      cny,
      chf,
      sgd,
    ];

    final Set<String> existing = list.map((e) => e.code).toSet();

    const List<List<String>> raw = [
      // code, name, symbol (no flag)
      ['AED', 'United Arab Emirates Dirham', 'د.إ'],
      ['AFN', 'Afghan Afghani', '؋'],
      ['ALL', 'Albanian Lek', 'L'],
      ['AMD', 'Armenian Dram', '֏'],
      ['ANG', 'Netherlands Antillean Guilder', 'ƒ'],
      ['AOA', 'Angolan Kwanza', 'Kz'],
      ['ARS', 'Argentine Peso', 'AR\$'],
      ['AWG', 'Aruban Florin', 'ƒ'],
      ['AZN', 'Azerbaijani Manat', '₼'],
      ['BAM', 'Bosnia-Herzegovina Convertible Mark', 'KM'],
      ['BBD', 'Barbadian Dollar', 'Bds\$'],
      ['BDT', 'Bangladeshi Taka', '৳'],
      ['BGN', 'Bulgarian Lev', 'лв'],
      ['BHD', 'Bahraini Dinar', 'د.ب'],
      ['BIF', 'Burundian Franc', 'FBu'],
      ['BMD', 'Bermudan Dollar', 'BD\$'],
      ['BND', 'Brunei Dollar', 'B\$'],
      ['BOB', 'Bolivian Boliviano', 'Bs.'],
      ['BRL', 'Brazilian Real', 'R\$'],
      ['BSD', 'Bahamian Dollar', 'B\$'],
      ['BTN', 'Bhutanese Ngultrum', 'Nu.'],
      ['BWP', 'Botswanan Pula', 'P'],
      ['BYN', 'Belarusian Ruble', 'Br'],
      ['BZD', 'Belize Dollar', 'BZ\$'],
      ['CDF', 'Congolese Franc', 'FC'],
      ['CLP', 'Chilean Peso', 'CL\$'],
      ['COP', 'Colombian Peso', 'COL\$'],
      ['CRC', 'Costa Rican Colón', '₡'],
      ['CUP', 'Cuban Peso', '₱'],
      ['CVE', 'Cape Verdean Escudo', '\$'],
      ['CZK', 'Czech Koruna', 'Kč'],
      ['DJF', 'Djiboutian Franc', 'Fdj'],
      ['DKK', 'Danish Krone', 'kr'],
      ['DOP', 'Dominican Peso', 'RD\$'],
      ['DZD', 'Algerian Dinar', 'دج'],
      ['EGP', 'Egyptian Pound', '£'],
      ['ERN', 'Eritrean Nakfa', 'Nfk'],
      ['ETB', 'Ethiopian Birr', 'Br'],
      ['FJD', 'Fijian Dollar', 'FJ\$'],
      ['FKP', 'Falkland Islands Pound', '£'],
      ['GEL', 'Georgian Lari', '₾'],
      ['GGP', 'Guernsey Pound', '£'],
      ['GHS', 'Ghanaian Cedi', '₵'],
      ['GIP', 'Gibraltar Pound', '£'],
      ['GMD', 'Gambian Dalasi', 'D'],
      ['GNF', 'Guinean Franc', 'FG'],
      ['GTQ', 'Guatemalan Quetzal', 'Q'],
      ['GYD', 'Guyanaese Dollar', 'GY\$'],
      ['HKD', 'Hong Kong Dollar', 'HK\$'],
      ['HNL', 'Honduran Lempira', 'L'],
      ['HRK', 'Croatian Kuna', 'kn'],
      ['HTG', 'Haitian Gourde', 'G'],
      ['HUF', 'Hungarian Forint', 'Ft'],
      ['IDR', 'Indonesian Rupiah', 'Rp'],
      ['ILS', 'Israeli New Shekel', '₪'],
      ['IMP', 'Isle of Man Pound', '£'],
      ['IQD', 'Iraqi Dinar', 'ع.د'],
      ['IRR', 'Iranian Rial', '﷼'],
      ['ISK', 'Icelandic Króna', 'kr'],
      ['JEP', 'Jersey Pound', '£'],
      ['JMD', 'Jamaican Dollar', 'J\$'],
      ['JOD', 'Jordanian Dinar', 'د.ا'],
      ['KES', 'Kenyan Shilling', 'KSh'],
      ['KGS', 'Kyrgystani Som', 'сом'],
      ['KHR', 'Cambodian Riel', '៛'],
      ['KMF', 'Comorian Franc', 'CF'],
      ['KPW', 'North Korean Won', '₩'],
      ['KRW', 'South Korean Won', '₩'],
      ['KWD', 'Kuwaiti Dinar', 'د.ك'],
      ['KYD', 'Cayman Islands Dollar', 'CI\$'],
      ['KZT', 'Kazakhstani Tenge', '₸'],
      ['LAK', 'Laotian Kip', '₭'],
      ['LBP', 'Lebanese Pound', 'ل.ل'],
      ['LKR', 'Sri Lankan Rupee', 'Rs'],
      ['LRD', 'Liberian Dollar', 'L\$'],
      ['LSL', 'Lesotho Loti', 'L'],
      ['LYD', 'Libyan Dinar', 'ل.د'],
      ['MAD', 'Moroccan Dirham', 'د.م.'],
      ['MDL', 'Moldovan Leu', 'L'],
      ['MGA', 'Malagasy Ariary', 'Ar'],
      ['MKD', 'Macedonian Denar', 'ден'],
      ['MMK', 'Myanma Kyat', 'Ks'],
      ['MNT', 'Mongolian Tugrik', '₮'],
      ['MOP', 'Macanese Pataca', 'MOP\$'],
      ['MRU', 'Mauritanian Ouguiya', 'UM'],
      ['MUR', 'Mauritian Rupee', '₨'],
      ['MVR', 'Maldivian Rufiyaa', 'Rf'],
      ['MWK', 'Malawian Kwacha', 'MK'],
      ['MXN', 'Mexican Peso', 'MX\$'],
      ['MYR', 'Malaysian Ringgit', 'RM'],
      ['MZN', 'Mozambican Metical', 'MT'],
      ['NAD', 'Namibian Dollar', 'N\$'],
      ['NGN', 'Nigerian Naira', '₦'],
      ['NIO', 'Nicaraguan Córdoba', 'C\$'],
      ['NOK', 'Norwegian Krone', 'kr'],
      ['NPR', 'Nepalese Rupee', '₨'],
      ['NZD', 'New Zealand Dollar', 'NZ\$'],
      ['OMR', 'Omani Rial', 'ر.ع.'],
      ['PAB', 'Panamanian Balboa', 'B/.'],
      ['PEN', 'Peruvian Sol', 'S/.'],
      ['PGK', 'Papua New Guinean Kina', 'K'],
      ['PHP', 'Philippine Peso', '₱'],
      ['PKR', 'Pakistani Rupee', '₨'],
      ['PLN', 'Polish Złoty', 'zł'],
      ['PYG', 'Paraguayan Guaraní', '₲'],
      ['QAR', 'Qatari Riyal', 'ر.ق'],
      ['RON', 'Romanian Leu', 'lei'],
      ['RSD', 'Serbian Dinar', 'дин'],
      ['RUB', 'Russian Ruble', '₽'],
      ['RWF', 'Rwandan Franc', 'FRw'],
      ['SAR', 'Saudi Riyal', '﷼'],
      ['SBD', 'Solomon Islands Dollar', 'SI\$'],
      ['SCR', 'Seychellois Rupee', '₨'],
      ['SDG', 'Sudanese Pound', 'ج.س.'],
      ['SEK', 'Swedish Krona', 'kr'],
      ['SHP', 'Saint Helena Pound', '£'],
      ['SLL', 'Sierra Leonean Leone', 'Le'],
      ['SOS', 'Somali Shilling', 'S'],
      ['SRD', 'Surinamese Dollar', 'SRD\$'],
      ['SSP', 'South Sudanese Pound', '£'],
      ['STN', 'São Tomé and Príncipe Dobra', 'Db'],
      ['SYP', 'Syrian Pound', '£'],
      ['SZL', 'Swazi Lilangeni', 'E'],
      ['THB', 'Thai Baht', '฿'],
      ['TJS', 'Tajikistani Somoni', 'ЅМ'],
      ['TMT', 'Turkmenistani Manat', 'm'],
      ['TND', 'Tunisian Dinar', 'د.ت'],
      ['TOP', 'Tongan Paʻanga', 'T\$'],
      ['TRY', 'Türk Lirası', '₺'],
      ['TTD', 'Trinidad and Tobago Dollar', 'TT\$'],
      ['TWD', 'New Taiwan Dollar', 'NT\$'],
      ['TZS', 'Tanzanian Shilling', 'TSh'],
      ['UAH', 'Ukrainian Hryvnia', '₴'],
      ['UGX', 'Ugandan Shilling', 'USh'],
      ['UYU', 'Uruguayan Peso', '\$U'],
      ['UZS', 'Uzbekistan Som', "so'm"],
      ['VES', 'Venezuelan Bolívar Soberano', 'Bs.'],
      ['VND', 'Vietnamese Đồng', '₫'],
      ['VUV', 'Vanuatu Vatu', 'VT'],
      ['WST', 'Samoan Tala', 'T'],
      ['XAF', 'Central African CFA Franc', 'FCFA'],
      ['XCD', 'East Caribbean Dollar', 'EC\$'],
      ['XOF', 'West African CFA Franc', 'CFA'],
      ['XPF', 'CFP Franc', '₣'],
      ['YER', 'Yemeni Rial', '﷼'],
      ['ZAR', 'South African Rand', 'R'],
      ['ZMW', 'Zambian Kwacha', 'ZK'],
      ['ZWL', 'Zimbabwean Dollar', 'Z\$'],

      // Additional territories and lesser-used
      ['ADP', 'Andorran Peseta (historic)', '₧'],
      ['AFA', 'Afghan Afghani (old)', 'Afs'],
      ['ALK', 'Albanian Lek (old)', 'L'],
      ['AON', 'Angolan New Kwanza (old)', 'Kz'],
      ['ARM', 'Argentinian Peso Moneda (old)', 'm\$n'],
      ['ATS', 'Austrian Schilling (historic)', 'S'],
      ['AZM', 'Azerbaijani Manat (old)', 'ман'],
      ['BEF', 'Belgian Franc (historic)', '₣'],
      ['BGL', 'Bulgarian Hard Lev (old)', 'лв'],
      ['BOP', 'Bolivian Peso (old)', '\$b'],
      ['BYR', 'Belarusian Ruble (old)', 'Br'],
      ['CHE', 'WIR Euro (complementary)', 'CHE'],
      ['CHW', 'WIR Franc (complementary)', 'CHW'],
      ['CYP', 'Cypriot Pound (historic)', '£'],
      ['DEM', 'German Mark (historic)', 'DM'],
      ['EEK', 'Estonian Kroon (historic)', 'KR'],
      ['ESP', 'Spanish Peseta (historic)', '₧'],
      ['FIM', 'Finnish Markka (historic)', 'mk'],
      ['FRF', 'French Franc (historic)', '₣'],
      ['GHC', 'Ghanaian Cedi (old)', '₵'],
      ['GRD', 'Greek Drachma (historic)', '₯'],
      ['HRD', 'Croatian Dinar (historic)', 'din'],
      ['IEP', 'Irish Pound (historic)', '£'],
      ['ITL', 'Italian Lira (historic)', '₤'],
      ['LVL', 'Latvian Lats (historic)', 'Ls'],
      ['LTL', 'Lithuanian Litas (historic)', 'Lt'],
      ['LUF', 'Luxembourgish Franc (historic)', '₣'],
      ['MGF', 'Malagasy Franc (old)', '₣'],
      ['MTL', 'Maltese Lira (historic)', '₤'],
      ['NLG', 'Dutch Guilder (historic)', 'ƒ'],
      ['PTE', 'Portuguese Escudo (historic)', 'Esc'],
      ['ROL', 'Romanian Leu (old)', 'lei'],
      ['RUR', 'Russian Ruble (old)', 'р.'],
      ['SKK', 'Slovak Koruna (historic)', 'Sk'],
      ['SIT', 'Slovenian Tolar (historic)', 'SIT'],
      ['SUR', 'Soviet Rouble (historic)', 'руб.'],
      ['TRL', 'Turkish Lira (old)', '₤'],
      ['TPE', 'Timorese Escudo (historic)', 'Esc'],
      ['TMM', 'Turkmenistani Manat (old)', 'm'],
      ['UAK', 'Ukrainian Karbovanets (historic)', 'крб.'],
      ['UYI', 'Uruguayan Peso (Indexed Units)', '\$U'],
      ['VEF', 'Venezuelan Bolívar (old)', 'Bs.F'],
      ['ZMK', 'Zambian Kwacha (old)', 'ZK'],

      // Precious metals and special codes
      ['XAU', 'Gold (troy ounce)', 'XAU'],
      ['XAG', 'Silver (troy ounce)', 'XAG'],
      ['XPT', 'Platinum (troy ounce)', 'XPT'],
      ['XPD', 'Palladium (troy ounce)', 'XPD'],

      // Popular cryptocurrencies to exceed 200 entries
      ['BTC', 'Bitcoin', '₿'],
      ['ETH', 'Ethereum', 'Ξ'],
      ['BNB', 'BNB', '฿'],
      ['XRP', 'Ripple', 'XRP'],
      ['ADA', 'Cardano', '₳'],
      ['DOGE', 'Dogecoin', 'Ð'],
      ['SOL', 'Solana', '◎'],
      ['DOT', 'Polkadot', '●'],
      ['MATIC', 'Polygon', 'M'],
      ['TRX', 'TRON', 'TRX'],
      ['XLM', 'Stellar', '★'],
      ['XMR', 'Monero', 'ɱ'],
      ['LTC', 'Litecoin', 'Ł'],
      ['BCH', 'Bitcoin Cash', 'Ƀ'],
      ['ETC', 'Ethereum Classic', 'Ξ'],
      ['ATOM', 'Cosmos', 'ATOM'],
      ['ICP', 'Internet Computer', 'ICP'],
      ['FIL', 'Filecoin', 'FIL'],
      ['APT', 'Aptos', 'APT'],
      ['ARB', 'Arbitrum', 'ARB'],
      ['OP', 'Optimism', 'OP'],
      ['ALGO', 'Algorand', 'Ⱥ'],
      ['AVAX', 'Avalanche', 'AVAX'],
      ['NEAR', 'NEAR Protocol', 'NEAR'],
      ['VET', 'VeChain', 'VET'],
      ['EGLD', 'MultiversX', 'EGLD'],
      ['KSM', 'Kusama', 'KSM'],
      ['USDT', 'Tether', '₮'],
      ['USDC', 'USD Coin', '\$'],
      ['DAI', 'Dai', 'D'],
      ['BUSD', 'Binance USD', '\$'],
      ['TUSD', 'TrueUSD', '\$'],
      ['PAX', 'Pax Dollar', '\$'],
    ];

    for (final e in raw) {
      final code = e[0];
      if (!existing.contains(code)) {
        list.add(Currency(code: e[0], name: e[1], symbol: e[2], flag: ''));
        existing.add(code);
      }
    }

    return list;
  }

  /// Get a currency by its code
  static Currency? fromCode(String code) {
    try {
      return all.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }
}
