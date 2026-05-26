import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/stock/domain/app_session.dart';
import 'features/stock/presentation/login_page.dart';
import 'features/stock/presentation/register_page.dart';
import 'features/stock/presentation/two_factor_page.dart';
import 'features/stock/presentation/company_list_page.dart';
import 'features/stock/presentation/my_page.dart';
import 'features/stock/presentation/stock_detail_page.dart';
import 'features/stock/presentation/settings_page.dart';
import 'features/trading/presentation/trading_home_page.dart';
import 'features/trading/presentation/position_list_page.dart';
import 'features/trading/presentation/trade_history_page.dart';
import 'features/trading/presentation/order_list_page.dart';
import 'features/trading/presentation/portfolio_page.dart';
import 'features/ai/presentation/ai_advisor_home_page.dart';
import 'features/ai/presentation/ai_advisor_page.dart';
import 'features/ai/presentation/ai_stock_advisor_page.dart';
import 'features/ai/presentation/ai_trading_review_page.dart';
import 'features/ai/presentation/ai_chat_page.dart';
import 'features/admin/presentation/admin_home_page.dart';
import 'features/admin/presentation/admin_user_management_page.dart';
import 'features/admin/presentation/admin_company_profile_list_page.dart';
import 'features/admin/presentation/admin_company_profile_edit_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSession.load();
  runApp(const StockApp());
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = AppSession.isLoggedIn;
    final path = state.uri.path;
    final publicPaths = ['/login', '/register', '/2fa'];
    final isPublic = publicPaths.any((p) => path.startsWith(p));
    if (!loggedIn && !isPublic) return '/login';
    if (loggedIn && path == '/') return AppSession.isAdmin ? '/admin' : '/companies';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const _Splash()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(
      path: '/2fa',
      builder: (_, state) {
        final p = state.uri.queryParameters;
        return TwoFactorPage(
          challengeId: p['challengeId'] ?? '',
          userId: p['userId'] ?? '',
          userName: p['userName'] ?? '',
          email: p['email'] ?? '',
          role: p['role'] ?? 'USER',
        );
      },
    ),
    GoRoute(path: '/companies', builder: (_, __) => const CompanyListPage()),
    GoRoute(path: '/mypage', builder: (_, __) => const MyPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    GoRoute(
      path: '/stock/:code',
      builder: (_, state) => StockDetailPage(code: state.pathParameters['code']!),
    ),
    // Trading
    GoRoute(path: '/trading', builder: (_, __) => const TradingHomePage()),
    GoRoute(path: '/trading/positions', builder: (_, __) => const PositionListPage()),
    GoRoute(path: '/trading/trades', builder: (_, __) => const TradeHistoryPage()),
    GoRoute(path: '/trading/orders', builder: (_, __) => const OrderListPage()),
    GoRoute(path: '/trading/portfolio', builder: (_, __) => const PortfolioPage()),
    // AI Advisor
    GoRoute(path: '/ai-advisor', builder: (_, __) => const AiAdvisorHomePage()),
    GoRoute(path: '/ai-advisor/portfolio', builder: (_, __) => const AiAdvisorPage()),
    GoRoute(path: '/ai-advisor/review', builder: (_, __) => const AiTradingReviewPage()),
    GoRoute(path: '/ai-advisor/chat', builder: (_, __) => const AiChatPage()),
    GoRoute(
      path: '/ai-advisor/chat/:code',
      builder: (_, state) => AiChatPage(stockCode: state.pathParameters['code']),
    ),
    GoRoute(
      path: '/ai-advisor/stock/:code',
      builder: (_, state) => AiStockAdvisorPage(code: state.pathParameters['code']!),
    ),
    // Admin
    GoRoute(path: '/admin', builder: (_, __) => const AdminHomePage()),
    GoRoute(path: '/admin/users', builder: (_, __) => const AdminUserManagementPage()),
    GoRoute(path: '/admin/company-profiles', builder: (_, __) => const AdminCompanyProfileListPage()),
    GoRoute(
      path: '/admin/company-profiles/:code',
      builder: (_, state) => AdminCompanyProfileEditPage(stockCode: state.pathParameters['code']!),
    ),
  ],
);

class StockApp extends StatelessWidget {
  const StockApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '株式学習アプリ',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2563EB),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(color: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        ),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
