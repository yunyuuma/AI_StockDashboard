class Company {
  final String code;
  final String name;
  final String market;
  final String industry;
  bool favorite;

  Company({
    required this.code,
    required this.name,
    required this.market,
    required this.industry,
    this.favorite = false,
  });

  factory Company.fromJson(Map<String, dynamic> j) => Company(
        code: j['code'] ?? '',
        name: j['name'] ?? '',
        market: j['market'] ?? '',
        industry: j['sector'] ?? j['industry'] ?? '',
      );
}
