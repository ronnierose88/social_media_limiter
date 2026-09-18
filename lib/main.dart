import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Stores the start and end time for social media restrictions
  TimeOfDay restrictionStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay restrictionEndTime = const TimeOfDay(hour: 7, minute: 0);

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

  // Opens a time picker for the restriction start time
  Future<void> pickRestrictionStartTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: restrictionStartTime,
    );

    if (pickedTime != null) {
      setState(() {
        restrictionStartTime = pickedTime;
      });
    }
  }


  // Opens a time picker for the restriction end time
  Future<void> pickRestrictionEndTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: restrictionEndTime,
    );

    if (pickedTime != null) {
      setState(() {
        restrictionEndTime = pickedTime;
      });
    }
  }
  // Checks if the current time is inside the restriction period
  bool isRestrictionTime() {

    // Gets the current time
    TimeOfDay currentTime = TimeOfDay.now();

    // Converts each time into minutes
    int currentMinutes =
        currentTime.hour * 60 + currentTime.minute;

    int startMinutes =
        restrictionStartTime.hour * 60 + restrictionStartTime.minute;

    int endMinutes =
        restrictionEndTime.hour * 60 + restrictionEndTime.minute;


    // Restriction starts and ends on the same day
    if (startMinutes < endMinutes) {

      if (currentMinutes >= startMinutes &&
          currentMinutes < endMinutes) {
        return true;
      }
    }


    // Restriction goes overnight
    else {

      if (currentMinutes >= startMinutes ||
          currentMinutes < endMinutes) {
        return true;
      }
    }


    return false;
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
      HomeSection(
      todayObjectives: todayObjectives,
      onAddObjective: addObjective,
      onToggleObjectiveCompleted: toggleObjectiveCompleted,
      isRestrictionTime: isRestrictionTime()
      ), // Pass data and functions to HomeSection
      ObjectivesSection(objectives: objectives, addObjective: addObjective, toggleObjectiveCompleted: toggleObjectiveCompleted, deleteObjective: deleteobjective),
      const AnalyticsSection(),
      SettingsSection(
      restrictionStartTime: restrictionStartTime,
      restrictionEndTime: restrictionEndTime,
      pickStartTime: pickRestrictionStartTime,
      pickEndTime: pickRestrictionEndTime,
    ),
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
class HomeSection extends StatefulWidget {

  // List of objectives for the current day
  final List<Map<String, dynamic>> todayObjectives;

  // Functions to add and toggle objectives
  final Function(String, String) onAddObjective;
  final Function(String) onToggleObjectiveCompleted;

  // Checks if the current time is within the restriction period
  final bool isRestrictionTime;

  const HomeSection({
    super.key,
    required this.todayObjectives,
    required this.onAddObjective,
    required this.onToggleObjectiveCompleted,
    required this.isRestrictionTime,
  });

  @override
  State<HomeSection> createState() {
    return _HomeSectionState();
  }
}


class _HomeSectionState extends State<HomeSection> {

  // Controller for the quick add objective text field
  final TextEditingController _objectiveController =
      TextEditingController();


  // Gives the current date in proper format
  String get todayDate {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }


  // Adds a new objective for the current day
  void quickAddObjective() {

    // Gets the text from the text field
    String title = _objectiveController.text.trim();

    // Does not add an objective if the title is empty
    if (title.isEmpty) {
      return;
    }

    // Adds the objective using today's date
    widget.onAddObjective(title, todayDate);

    // Clears the text field after adding the objective
    _objectiveController.clear();
  }


  // Counts how many of today's objectives are completed
  int getCompletedCount() {

    int completedCount = 0;

    // Goes through each objective for today
    for (var objective in widget.todayObjectives) {

      // Adds one to the count if the objective is completed
      if (objective['completed'] == true) {
        completedCount = completedCount + 1;
      }
    }

    return completedCount;
  }


  // Checks if every objective for today has been completed
  bool checkAllCompleted() {

    // Returns false if there are no objectives today
    if (widget.todayObjectives.isEmpty) {
      return false;
    }

    // Goes through each objective for today
    for (var objective in widget.todayObjectives) {

      // Returns false if an objective has not been completed
      if (objective['completed'] == false) {
        return false;
      }
    }

    // Returns true if all objectives have been completed
    return true;
  }


  @override
  Widget build(BuildContext context) {

    // Stores how many objectives are completed
    int completedCount = getCompletedCount();

    // Stores whether all today's objectives are completed
    bool allCompleted = checkAllCompleted();

    // Determines whether social media should be locked or unlocked
    bool shouldLock = false;

    // Lock if objectives are incomplete or it is restriction time
    if (allCompleted == false || widget.isRestrictionTime == true) {
      shouldLock = true;
    }

    String lockMessage = '';

    // Message if social media is unlocked
    if (shouldLock == false) {
      lockMessage = 'Social media is currently unlocked.';
    }

    // Message if locked because of objectives and restricted time
    else if (allCompleted == false &&
        widget.isRestrictionTime == true) {
      lockMessage =
          'Complete your objectives and wait until the restricted time is over to unlock social media.';
    }

    // Message if locked because objectives are incomplete
    else if (allCompleted == false) {
      lockMessage =
          'Complete your objectives for today to unlock social media access.';
    }

    // Message if locked only because of restricted time
    else if (widget.isRestrictionTime == true) {
      lockMessage =
          'Social media is locked because it is currently within your restricted time.';
    }

    return ListView(
      padding: const EdgeInsets.all(16),

      children: [

        // Card showing whether social media is locked or unlocked
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                // Lock or unlock icon
                Icon(
                  shouldLock ? Icons.lock : Icons.lock_open,
                  size: 70,
                  color: shouldLock ? Colors.red : Colors.green,
                ),

                const SizedBox(height: 12),

                // Lock status text
                Text(
                  shouldLock
                      ? 'Social Media Locked'
                      : 'Social Media Unlocked',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Message explaining the current lock status
                Text(
                  lockMessage,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),


        const SizedBox(height: 12),


        // Card showing today's objective progress
        Card(
          child: ListTile(
            leading: const Icon(Icons.task_alt),
            title: const Text('Todays Progress'),
            subtitle: Text(
              '$completedCount of ${widget.todayObjectives.length} objectives completed',
            ),
          ),
        ),


        const SizedBox(height: 12),


        // Card containing quick add and today's objectives
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                // Text field for quickly adding an objective for today
                TextField(
                  controller: _objectiveController,
                  decoration: const InputDecoration(
                    labelText: 'Quick add objective for today',
                    hintText: 'Example: Finish homework',
                    border: OutlineInputBorder(),
                  ),
                ),


                const SizedBox(height: 8),


                // Button to add the objective
                FilledButton(
                  onPressed: quickAddObjective,
                  child: const Text('Add Objective'),
                ),


                const SizedBox(height: 16),


                // Heading for today's objectives
                const Text(
                  'Todays Objectives',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),


                const SizedBox(height: 8),


                // Shows a message if there are no objectives today
                if (widget.todayObjectives.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No objectives for today. Add some to get started!',
                    ),
                  ),


                // Creates the list of today's objectives
                if (widget.todayObjectives.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    // Number of objectives for today
                    itemCount: widget.todayObjectives.length,

                    itemBuilder: (context, index) {

                      // Gets the objective at the current position
                      final objective =
                          widget.todayObjectives[index];

                      return Card(
                        child: CheckboxListTile(

                          // Shows whether the objective is completed
                          value: objective['completed'],

                          // Shows the objective title
                          title: Text(objective['title']),

                          // Changes the completed status when checkbox is pressed
                          onChanged: (value) {
                            widget.onToggleObjectiveCompleted(
                              objective['title'],
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
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
  final TextEditingController _objectiveController =
    TextEditingController();

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

  final TimeOfDay restrictionStartTime;
  final TimeOfDay restrictionEndTime;

  final Function(BuildContext) pickStartTime;
  final Function(BuildContext) pickEndTime;


  const SettingsSection({
    super.key,
    required this.restrictionStartTime,
    required this.restrictionEndTime,
    required this.pickStartTime,
    required this.pickEndTime,
  });


  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [

          const Text(
            'Restriction Period',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),


          // Restriction start time
          Card(
            child: ListTile(
              title: const Text('Start Time'),

              subtitle: Text(
                restrictionStartTime.format(context),
              ),

              trailing: const Icon(Icons.access_time),

              onTap: () {
                pickStartTime(context);
              },
            ),
          ),


          const SizedBox(height: 10),


          // Restriction end time
          Card(
            child: ListTile(
              title: const Text('End Time'),

              subtitle: Text(
                restrictionEndTime.format(context),
              ),

              trailing: const Icon(Icons.access_time),

              onTap: () {
                pickEndTime(context);
              },
            ),
          ),

        ],
      ),
    );
  }
}
