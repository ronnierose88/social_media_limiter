import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Starting point of application, launches SocialMediaLimiter widget
void main() {
  runApp(const SocialMediaLimiter());
}

// Root widget of the app, containing theme and home page
class SocialMediaLimiter extends StatelessWidget {
  const SocialMediaLimiter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Name of application
      title: 'Social Media Limiter',

      // Sets default colour scheme throughout the app
      theme: ThemeData(colorSchemeSeed: Colors.indigo),

      home: const MainPage(),
    );
  }
}

// MainPage which controls bottom navigation and stores objective data
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  
  // Stores which navigation tab is selected
  // 0 = Home, 1 = Objectives, 2 = Analytics, 3 = Settings
  int selectedIndex = 0;

  // Stores all objectives, each containing title, date, and completed
  List<Map<String, dynamic>> objectives = [];

  // Titles for each page, used in AppBar
  final List<String> pageTitles = [
    'Home',
    'Objectives',
    'Analytics',
    'Settings',
  ];

  // Gives the current date in proper format
  String get todayDate {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  // Filters objectives into a list of objectives of the current date
  List<Map<String, dynamic>> get todayObjectives {
    return objectives.where((objective) {
      return objective['date'] == todayDate;
    }).toList();
  }

  // Checks if all the objectives in the current date have been completed
  bool get allTodayObjectivesCompleted {
    
    // False if there are not any objectives for the day
    if (todayObjectives.isEmpty) {
      return false;
    }

    // True if all the objectives are completed. False if any of them are not completed
    return todayObjectives.every((objective) {
      return objective['completed'] == true;
    });
  }

  // Adds a new objective to list with title, current date, and completed as false
  void addObjective(String title, String date) {
    final newObjective = {'title': title, 'date': date, 'completed': false};

    // Updates the state of the app to include the new objective
    setState(() {
      objectives.add(newObjective);
    });
  }

  // Changes objective between completed and incompleted
  void toggleObjectiveCompleted(String title) {
    setState(() {

      // Searches through all objectives and toggles the completed status of the one with the matching title
      for (final objective in objectives) {
        if (objective['title'] == title) {
          objective['completed'] = !objective['completed'];
        }
      }
    });
  }

  // Deletes an objective with the matching title from the list of objectives
  void deleteobjective(String title) {
    setState(() {
      objectives.removeWhere((objective) {
        return objective['title'] == title;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    // List of pages in the app
    final List<Widget> pages = [
      const HomeSection(),
      const ObjectivesSection(),
      const AnalyticsSection(),
      const SettingsSection(),
    ];

    return Scaffold(

      // App bar shown at the top of the page with title of current page
      appBar: AppBar(title: Text(pageTitles[selectedIndex]), centerTitle: true),
      body: pages[selectedIndex],

      // Navigation bar displayed at bottom of page
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        // List of navigation destinations, each with an icon and label
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Objectives'),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// Widget for home section
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home Section'));
  }
}

// Widget for objectives section
class ObjectivesSection extends StatelessWidget {
  const ObjectivesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Objectives Section'));
  }
}

// Widget for analytics section
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Analytics Section'));
  }
}

// Widget for settings section
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Section'));
  }
}
