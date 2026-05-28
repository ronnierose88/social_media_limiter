import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SocialMediaLimiter());
}
class SocialMediaLimiter extends StatelessWidget {
  const SocialMediaLimiter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media Limiter',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
      ),
      home: const MainPage(),
    );  }
} 

class MainPage extends StatefulWidget {
  const MainPage({super.key});  

  @override
  State<MainPage> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  List<Map<String, dynamic>> objectives = [];
  

  final List<String> pageTitles = [
    'Home',
    'Objectives',
    'Analytics',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeSection(),
      const ObjectivesSection(),
      const AnalyticsSection(),
      const SettingsSection(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[selectedIndex]),
        centerTitle: true,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag),
            label: 'Objectives',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Section'),
    );
  }
}

class ObjectivesSection extends StatelessWidget {
  const ObjectivesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Objectives Section'),
    );
  }
}

class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Analytics Section'),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Section'),
    );
  }
}
