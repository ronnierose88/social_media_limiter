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
    List<Map<String, dynamic>> today = [];

    for (var objective in objectives) {
      if (objective['date'] == todayDate) {
        today.add(objective);
      }
    }

  return today;
}

  // Checks if all the objectives in the current date have been completed
  bool get allTodayObjectivesCompleted {
    
    // False if there are not any objectives for the day
    if (todayObjectives.isEmpty) {
      return false;
    }

    // True if all the objectives are completed. False if any of them are not completed
    for (var objective in todayObjectives) {
      if (objective['completed'] == false) {
        return false;
      }
    }

    return true;
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
      ObjectivesSection(objectives: objectives, addObjective: addObjective, toggleObjectiveCompleted: toggleObjectiveCompleted, deleteObjective: deleteobjective),
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
class ObjectivesSection extends StatefulWidget {
  // List of objectives, each containing title, date, and completed
  final List<Map<String, dynamic>> objectives;

  // Functions to add, toggle, and delete objectives
  final Function(String, String) addObjective;
  final Function(String) toggleObjectiveCompleted;
  final Function(String) deleteObjective;

  const ObjectivesSection({
    super.key,
    required this.objectives,
    required this.addObjective,
    required this.toggleObjectiveCompleted,
    required this.deleteObjective,
  });

  @override
  State<ObjectivesSection> createState() => _ObjectivesSectionState();
}

class _ObjectivesSectionState extends State<ObjectivesSection> {

  // Controller for the text field where users input new objectives
  final TextEditingController _objectiveController = TextEditingController();

  // Stores the selected date
  DateTime selectedDate = DateTime.now();

  // Opens the date picker
  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365))
    );

    // If a date is selected, save it
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Adds a new objective
  void addObjective() {
    
    // Gets the text from text field
    String title = _objectiveController.text.trim();

    // Does not add objective if title is empty
    if (title.isEmpty) {
      return;
    }

    // Formats the selected date
    String date = DateFormat('dd-MM-yyyy').format(selectedDate);

    // Calls the function to add the objective
    widget.addObjective(title, date);
  }

@override
Widget build(BuildContext context) {

  return Padding(
    padding: const EdgeInsets.all(16.0),

    child: Column(
      children: [

        // Text field for inputting new objectives
        TextField(
          controller: _objectiveController,
          decoration: const InputDecoration(
            labelText: 'New Objective',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8.0),

        // Button to pick a date for the new objective
        FilledButton(
          onPressed: () => pickDate(context),
          child: Text(
            'Pick Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}',
          ),
        ),
        const SizedBox(height: 8.0),

        // Button to add the new objective
        FilledButton(
          onPressed: addObjective,
          child: const Text('Add Objective'),
        ),
        const SizedBox(height: 16.0),

      // Displays the list of objectives
      Expanded(
          child: ListView.builder(
            itemCount: widget.objectives.length,
            itemBuilder: (context, index) {
              final objective = widget.objectives[index];
              return Card(
                child: ListTile(

                  // Objective title
                  title: Text(objective['title']),

                  // Date of the objective
                  subtitle: Text('Date: ${objective['date']}'),

                  // Checkbox to mark objective as completed
                  leading: Checkbox(
                    value: objective['completed'],
                    onChanged: (value) {
                      widget.toggleObjectiveCompleted(objective['title']);
                    },
                  ),

                    
                  // Delete button to remove the objective
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      widget.deleteObjective(objective['title']);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}
  
// Widget for analytics section

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
