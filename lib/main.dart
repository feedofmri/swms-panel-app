import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/websocket_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_theme.dart';
import 'features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'features/alerts/viewmodel/alerts_viewmodel.dart';
import 'features/controls/viewmodel/controls_viewmodel.dart';
import 'features/settings/viewmodel/settings_viewmodel.dart';
import 'features/dashboard/view/dashboard_screen.dart';
import 'features/alerts/view/alerts_screen.dart';
import 'features/controls/view/controls_screen.dart';
import 'features/settings/view/settings_screen.dart';
import 'features/esp_monitor/view/esp_monitor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  final storageService = StorageService();
  await storageService.initialize();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final webSocketService = WebSocketService();

  // Auto-connect if we have a stored IP address
  final storedIp = await storageService.getEspIpAddress();
  if (storedIp != null && storedIp.isNotEmpty) {
    webSocketService.connect(storedIp);
  }

  runApp(SWMSPanelApp(
    storageService: storageService,
    notificationService: notificationService,
    webSocketService: webSocketService,
  ));
}

class SWMSPanelApp extends StatelessWidget {
  final StorageService storageService;
  final NotificationService notificationService;
  final WebSocketService webSocketService;

  const SWMSPanelApp({
    super.key,
    required this.storageService,
    required this.notificationService,
    required this.webSocketService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        Provider<StorageService>.value(value: storageService),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<WebSocketService>.value(value: webSocketService),

        // ViewModels
        ChangeNotifierProvider<DashboardViewModel>(
          create: (context) => DashboardViewModel(
            webSocketService: webSocketService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider<AlertsViewModel>(
          create: (context) => AlertsViewModel(
            webSocketService: webSocketService,
            storageService: storageService,
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider<ControlsViewModel>(
          create: (context) => ControlsViewModel(
            webSocketService: webSocketService,
          ),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            webSocketService: webSocketService,
            storageService: storageService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SWMS Panel',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
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

  final List<Widget> _screens = const [
    DashboardScreen(),
    AlertsScreen(),
    ControlsScreen(),
    SettingsScreen(),
    EspMonitorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<AlertsViewModel>(
        builder: (context, alertsViewModel, child) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (alertsViewModel.unreadAlerts.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${alertsViewModel.unreadAlerts.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Alerts',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings_remote),
                label: 'Controls',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.monitor),
                label: 'ESP Monitor',
              ),
            ],
          );
        },
      ),
    );
  }
}
