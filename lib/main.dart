import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'dart:ui';

import 'providers/auth_provider.dart';
import 'providers/santri_provider.dart';
import 'providers/pembayaran_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/absensi_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/qr_scan_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/santri/santri_list_screen.dart';
import 'screens/santri/santri_form_screen.dart';
import 'screens/pembayaran/pembayaran_screen.dart';
import 'screens/pembayaran/bayar_spp_screen.dart';
import 'screens/infak/infak_screen.dart';
import 'screens/pengeluaran/pengeluaran_screen.dart';
import 'screens/jurnal/jurnal_screen.dart';
import 'screens/saran/saran_screen.dart';
import 'screens/pengaturan/pengaturan_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';
import 'screens/absensi/absensi_screen.dart';
import 'screens/alumni/alumni_screen.dart';
import 'screens/keuangan/keuangan_screen.dart';
import 'screens/laporan/laporan_screen.dart';
import 'screens/pembayaran/pembayaran_lain_screen.dart';
import 'screens/prestasi/prestasi_santri_screen.dart';
import 'screens/akun/akun_screen.dart';
import 'services/background_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Handle errors outside Flutter framework (e.g. Dart async errors)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true; // handled
  };

  await BackgroundService.initialize();
  runApp(const TPQApp());
}

class TPQApp extends StatefulWidget {
  const TPQApp({super.key});

  @override
  State<TPQApp> createState() => _TPQAppState();
}

class _TPQAppState extends State<TPQApp> {
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial deep link (app was closed)
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (_) {}

    // Handle deep links while app is running
    _linkSub = linkStream.listen((String? link) {
      if (link != null) _handleDeepLink(link);
    });
  }

  void _handleDeepLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return;

    if (uri.scheme == 'tpqlink' && uri.host == 'login') {
      final token = uri.queryParameters['token'];
      // user and server params for future use
      final serverUrl = uri.queryParameters['server'];

      if (token != null) {
        // Navigate to handle login via deep link
        final navKey = _navigatorKey;
        if (navKey.currentContext != null) {
          final authProvider =
              Provider.of<AuthProvider>(navKey.currentContext!, listen: false);
          authProvider.loginWithToken(token, serverUrl ?? '');
        }
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DashboardProvider>(
          create: (_) => DashboardProvider(),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SantriProvider>(
          create: (_) => SantriProvider(),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PembayaranProvider>(
          create: (_) => PembayaranProvider(),
          update: (_, auth, prev) => prev!..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => AbsensiProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'TPQ Futuhil Hidayah',
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: false,
                scrolledUnderElevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  elevation: 0,
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shadowColor: Colors.black.withAlpha(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.textPrimary,
                contentTextStyle: const TextStyle(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: Colors.white,
                selectedColor: AppColors.primary.withAlpha(40),
                disabledColor: AppColors.border,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                labelStyle: const TextStyle(color: AppColors.textPrimary),
                secondaryLabelStyle: const TextStyle(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              listTileTheme: const ListTileThemeData(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                iconColor: AppColors.primary,
              ),
              dividerTheme: const DividerThemeData(
                color: AppColors.border,
                thickness: 1,
                space: 1,
              ),
              navigationBarTheme: NavigationBarThemeData(
                height: 72,
                backgroundColor: Colors.white,
                shadowColor: Colors.black.withAlpha(10),
                indicatorColor: AppColors.primary.withAlpha(36),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: states.contains(WidgetState.selected)
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  );
                }),
              ),
            ),
            home: auth.isAuthenticated
                ? const MainScreen()
                : const LoginScreen(),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/qr-scan': (_) => const QRScanScreen(),
              '/dashboard': (_) => const MainScreen(),
              '/santri': (_) => const SantriListScreen(),
              '/santri/tambah': (_) => const SantriFormScreen(),
              '/pembayaran': (_) => const PembayaranScreen(),
              '/bayar-spp': (_) => const BayarSPPScreen(),
              '/infak': (_) => const InfakScreen(),
              '/pengeluaran': (_) => const PengeluaranScreen(),
              '/jurnal': (_) => const JurnalScreen(),
              '/saran': (_) => const SaranScreen(),
              '/pengaturan': (_) => const PengaturanScreen(),
              '/notifikasi': (_) => const NotifikasiScreen(),
              '/prestasi-santri': (_) => const PrestasiSantriScreen(),
              '/akun': (_) => const AkunScreen(),
              '/absensi': (_) => const AbsensiScreen(),
              '/alumni': (_) => const AlumniScreen(),
              '/keuangan': (_) => const KeuanganScreen(),
              '/laporan': (_) => const LaporanScreen(),
              '/pembayaran-lain': (_) => const PembayaranLainScreen(),
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canManage = auth.user?.isFullAccess ?? false;
    final isPengajar = auth.user?.isPengajar ?? false;

    final screens = isPengajar
        ? const [
            PrestasiSantriScreen(embedded: true),
            SantriListScreen(),
            SaranScreen(),
            NotifikasiScreen(embedded: true),
            AkunScreen(embedded: true),
          ]
        : const [
            DashboardScreen(),
            SantriListScreen(),
            PembayaranScreen(),
            BayarSPPScreen(embedded: true),
            JurnalScreen(),
          ];

    final titles = isPengajar
        ? const [
            'Buku Prestasi Santri',
            'Data Santri',
            'Kotak Saran',
            'Notifikasi',
            'Akun',
          ]
        : const [
            'Dashboard',
            'Data Santri',
            'Pembayaran',
            'Bayar SPP',
            'Jurnal Kas',
          ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Keluar Aplikasi'),
            content: const Text('Yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
        if (shouldExit == true) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_currentIndex]),
          actions: [
            if (!isPengajar)
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifikasi'),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'akun':
                    Navigator.pushNamed(context, '/akun');
                    break;
                  case 'pengaturan':
                    Navigator.pushNamed(context, '/pengaturan');
                    break;
                  case 'saran':
                    Navigator.pushNamed(context, '/saran');
                    break;
                  case 'pengeluaran':
                    Navigator.pushNamed(context, '/pengeluaran');
                    break;
                  case 'absensi':
                    Navigator.pushNamed(context, '/absensi');
                    break;
                  case 'logout':
                    auth.logout();
                    break;
                }
              },
              itemBuilder: (_) => [
                if (!isPengajar)
                  const PopupMenuItem(
                      value: 'absensi', child: Text('Absensi')),
                if (!isPengajar && canManage)
                  const PopupMenuItem(
                      value: 'pengeluaran', child: Text('Pengeluaran')),
                if (!isPengajar && canManage)
                  const PopupMenuItem(value: 'saran', child: Text('Kotak Saran')),
                if (!isPengajar && canManage)
                  const PopupMenuItem(
                      value: 'pengaturan', child: Text('Pengaturan')),
                if (!isPengajar)
                  const PopupMenuItem(value: 'akun', child: Text('Akun')),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        body: screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          surfaceTintColor: Colors.white,
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: isPengajar
              ? const [
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: 'Prestasi',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outlined),
                    selectedIcon: Icon(Icons.people),
                    label: 'Santri',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.mail_outline),
                    selectedIcon: Icon(Icons.mail),
                    label: 'Saran',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.notifications_outlined),
                    selectedIcon: Icon(Icons.notifications),
                    label: 'Notif',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Akun',
                  ),
                ]
              : const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outlined),
                    selectedIcon: Icon(Icons.people),
                    label: 'Santri',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'SPP',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.payment_outlined),
                    selectedIcon: Icon(Icons.payment),
                    label: 'Bayar SPP',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.book_outlined),
                    selectedIcon: Icon(Icons.book),
                    label: 'Jurnal',
                  ),
                ],
        ),
        // FAB only visible for roles that can add/edit data
        floatingActionButton: (!isPengajar && canManage)
            ? (_currentIndex == 1
                ? FloatingActionButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/santri/tambah'),
                    child: const Icon(Icons.person_add),
                  )
                : _currentIndex == 2
                    ? FloatingActionButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/bayar-spp'),
                        child: const Icon(Icons.add),
                      )
                    : _currentIndex == 4
                        ? FloatingActionButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/infak'),
                            child: const Icon(Icons.favorite),
                          )
                        : null)
            : null,
      ),
    );
  }
}
