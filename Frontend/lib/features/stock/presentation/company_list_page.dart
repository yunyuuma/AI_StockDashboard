import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/stock_repository.dart';
import '../data/favorite_repository.dart';
import '../domain/company.dart';
import '../domain/app_session.dart';

class CompanyListPage extends StatefulWidget {
  const CompanyListPage({super.key});
  @override
  State<CompanyListPage> createState() => _CompanyListPageState();
}

class _CompanyListPageState extends State<CompanyListPage> {
  final _repo = StockRepository();
  final _favRepo = FavoriteRepository();
  final _searchCtrl = TextEditingController();

  List<Company> _companies = [];
  Set<String> _favCodes = {};
  bool _loading = false;
  String? _error;
  int _page = 0;
  String _market = '';
  bool _hasMore = true;
  bool _showFavOnly = false;

  static const _markets = ['', 'プライム', 'スタンダード', 'グロース'];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (AppSession.userId == null) return;
    try {
      final codes = await _favRepo.fetchFavoriteCodes(AppSession.userId!);
      if (mounted) setState(() => _favCodes = codes.toSet());
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) { _page = 0; _companies = []; _hasMore = true; }
    if (!_hasMore) return;

    setState(() { _loading = true; _error = null; });
    try {
      final q = _searchCtrl.text.trim();
      final list = await _repo.fetchStocks(page: _page, size: 30, q: q.isEmpty ? null : q, market: _market.isEmpty ? null : _market);
      setState(() {
        _companies.addAll(list);
        _hasMore = list.length == 30;
        _page++;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFav(Company c) async {
    if (AppSession.userId == null) return;
    try {
      if (_favCodes.contains(c.code)) {
        await _favRepo.deleteFavorite(AppSession.userId!, c.code);
        setState(() => _favCodes.remove(c.code));
      } else {
        await _favRepo.addFavorite(AppSession.userId!, c.code);
        setState(() => _favCodes.add(c.code));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<Company> get _displayed => _showFavOnly
      ? _companies.where((c) => _favCodes.contains(c.code)).toList()
      : _companies;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('銘柄一覧', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [
          IconButton(onPressed: () => context.go('/mypage'), icon: const Icon(Icons.person_outline)),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '銘柄コード・銘柄名・業種で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _load(reset: true); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _load(reset: true),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _markets.map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(m.isEmpty ? '全市場' : m),
                        selected: _market == m,
                        onSelected: (_) { setState(() => _market = m); _load(reset: true); },
                      ),
                    )).toList(),
                  ),
                ),
              ),
              FilterChip(
                label: const Text('お気に入り'),
                selected: _showFavOnly,
                avatar: const Icon(Icons.star, size: 16),
                onSelected: (v) => setState(() => _showFavOnly = v),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => _load(reset: true), child: const Text('再試行')),
                ]))
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification && n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      _load();
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: ListView.separated(
                      itemCount: _displayed.length + (_loading ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        if (i == _displayed.length) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                        final c = _displayed[i];
                        final isFav = _favCodes.contains(c.code);
                        return ListTile(
                          onTap: () => context.go('/stock/${c.code}'),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text(c.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${c.market} · ${c.industry}', style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey),
                            onPressed: () => _toggleFav(c),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}
