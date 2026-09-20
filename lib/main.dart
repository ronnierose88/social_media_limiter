import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:app_blocker/app_blocker.dart';
import 'package:app_usage/app_usage.dart';

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

  // Timer that updates the restriction status continuously
  Timer? restrictionTimer;

  // Stores the start and end time for social media restrictions
  TimeOfDay restrictionStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay restrictionEndTime = const TimeOfDay(hour: 7, minute: 0);

  // Stores the next objective ID to be assigned
  int nextObjectiveId = 0;

  // Stores today's total social media usage in minutes
  int todayUsage = 0;


  // Stores this week's total social media usage in minutes
  int thisWeekUsage = 0;


  // Stores last week's total social media usage in minutes
  int lastWeekUsage = 0;

  // Stores all objectives, each containing title, date, and completed
  List<Map<String, dynamic>> objectives = [];

  // Titles for each page, used in AppBar
  final List<String> pageTitles = [
    'Home',
    'Objectives',
    'Analytics',
    'Settings',
  ];

  // App blocker used to block social media apps
  final AppBlocker appBlocker = AppBlocker.instance;

  // Stores the apps installed on the device
  List<AppInfo> installedApps = [];

  // Stores the social media apps to be blocked
  List<String> selectedApps = [];

  // Gives the current date in proper format
  String get todayDate {
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  // Calculates total social media usage between two dates
  Future<int> calculateUsage(
      DateTime startDate,
      DateTime endDate) async {

    // Gets the app usage between the selected dates
    List<AppUsageInfo> usageInfo =
        await AppUsage().getAppUsage(startDate, endDate);

    int totalMinutes = 0;

    // Goes through each app returned
    for (final app in usageInfo) {

      // Only counts the usage of the apps that are selected to be blocked
      if (selectedApps.contains(app.packageName)) {

        // Adds the app usage to the total
        totalMinutes =
            totalMinutes + app.usage.inMinutes;
      }
    }

    // Returns the total usage
    return totalMinutes;
  }

  // Saves the app data
  Future<void> saveData() async {

    // Gets access to shared preferences
    final prefs =
        await SharedPreferences.getInstance();


    // Converts the objectives list into text
    String objectivesText =
        jsonEncode(objectives);


    // Saves the objectives
    await prefs.setString(
      'objectives',
      objectivesText,
    );


    // Saves the next objective ID
    await prefs.setInt(
      'nextObjectiveId',
      nextObjectiveId,
    );


    // Saves the restriction start time
    await prefs.setInt(
      'restrictionStartHour',
      restrictionStartTime.hour,
    );

    await prefs.setInt(
      'restrictionStartMinute',
      restrictionStartTime.minute,
    );


    // Saves the restriction end time
    await prefs.setInt(
      'restrictionEndHour',
      restrictionEndTime.hour,
    );

    await prefs.setInt(
      'restrictionEndMinute',
      restrictionEndTime.minute,
    );


    // Saves the apps selected to be blocked
    await prefs.setStringList(
      'selectedApps',
      selectedApps,
    );
  }

// Loads the saved app data
Future<void> loadData() async {

  // Gets access to shared preferences
  final prefs =
      await SharedPreferences.getInstance();


  // Gets the saved objectives
  String? objectivesText =
      prefs.getString('objectives');


  // Loads the objectives if they have been saved before
  if (objectivesText != null) {

    // Converts the saved text back into a list
    List<dynamic> savedObjectives =
        jsonDecode(objectivesText);


    objectives =
        savedObjectives
            .map((objective) =>
                Map<String, dynamic>.from(objective))
            .toList();
  }


  // Gets the saved next objective ID
  int? savedNextObjectiveId =
      prefs.getInt('nextObjectiveId');


  // Loads the next objective ID if it exists
  if (savedNextObjectiveId != null) {
    nextObjectiveId =
        savedNextObjectiveId;
  }


  // Gets the saved restriction start time
  int? startHour =
      prefs.getInt('restrictionStartHour');

  int? startMinute =
      prefs.getInt('restrictionStartMinute');


  // Gets the saved restriction end time
  int? endHour =
      prefs.getInt('restrictionEndHour');

  int? endMinute =
      prefs.getInt('restrictionEndMinute');


  // Loads the start time if it exists
  if (startHour != null &&
      startMinute != null) {

    restrictionStartTime =
        TimeOfDay(
          hour: startHour,
          minute: startMinute,
        );
  }


  // Loads the end time if it exists
  if (endHour != null &&
      endMinute != null) {

    restrictionEndTime =
        TimeOfDay(
          hour: endHour,
          minute: endMinute,
        );
  }


  // Gets the saved selected apps
  List<String>? savedSelectedApps =
      prefs.getStringList('selectedApps');


  // Loads the selected apps if they exist
  if (savedSelectedApps != null) {
    selectedApps =
        savedSelectedApps;
  }


  // Updates the app with all the loaded data
  setState(() {});
}

  // Calculates today's, this week's and last week's usage
  Future<void> updateAnalytics() async {

    // Gets the current date and time
    DateTime now = DateTime.now();


    // Gets the start of today
    DateTime todayStart =
        DateTime(now.year, now.month, now.day);


    // Finds the start of the current week
    DateTime thisWeekStart =
        todayStart.subtract(
          Duration(days: now.weekday - 1),
        );


    // Finds the start of last week
    DateTime lastWeekStart =
        thisWeekStart.subtract(
          const Duration(days: 7),
        );


    // Calculates today's usage
    int newTodayUsage =
        await calculateUsage(
          todayStart,
          now,
        );


    // Calculates this week's usage
    int newThisWeekUsage =
        await calculateUsage(
          thisWeekStart,
          now,
        );


    // Calculates last week's usage
    int newLastWeekUsage =
        await calculateUsage(
          lastWeekStart,
          thisWeekStart,
        );


    // Updates the displayed usage values
    setState(() {
      todayUsage = newTodayUsage;
      thisWeekUsage = newThisWeekUsage;
      lastWeekUsage = newLastWeekUsage;
    });
  }

  // Loads the apps installed on the device
  Future<void> loadInstalledApps() async {

    // Gets the installed apps using app_blocker
    installedApps = await appBlocker.getApps();

    // Updates the app so the installed apps are shown
    setState(() {});
  }

  // Checks if app blocking permission has already been enabled
  Future<void> checkBlockerPermission() async {

    final status = await appBlocker.checkPermission();

    // Shows instructions only if permission has not been enabled
    if (status != BlockerPermissionStatus.granted) {
      showPermissionInstructions();
    }
  }

  // Changes whether an app is selected to be blocked
  void selectApp(String packageName, bool selected) {

    setState(() {

      // Adds the app if it was selected
      if (selected == true) {
        selectedApps.add(packageName);
      }

      // Removes the app if it was unselected
      else {
        selectedApps.remove(packageName);
      }
    });

    // Saves the updated selected apps
    saveData();

    // Updates the apps being blocked
    updateAppBlocking();
  }

  // Shows instructions before opening Android permission settings
  void showPermissionInstructions() {

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text('Enable App Blocking'),
          content: const Text(
            'To enable app blocking, turn on the permissions in the Android settings that open. You will be prompted to enable both the App Blocker Accessibility and Alarms & reminders. Return to the app after enabling each permission.',
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {

                Navigator.pop(context);

                // Opens Android settings for the required permission
                await appBlocker.requestPermission();

                // Checks for permissions again after returning from settings
                checkBlockerPermission();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Runs when MainPage first starts
  @override
  void initState() {
    super.initState();

    // Loads the saved data when the app starts
    loadData();

    // Delays the permission instructions to allow the app to fully load before showing the dialog
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        checkBlockerPermission();
      },
    );

    // Updates the app blocking status when the app first starts
    updateAppBlocking();

    // Runs every minute so the current time is checked again
    restrictionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {

        // Updates the state of the app to check if it is restriction time again
        setState(() {});

        // Updates the app blocking status after checking the time
        updateAppBlocking();
      },
    );
  }

  // Cancels the timer when MainPage is closed
  @override
  void dispose() {
    restrictionTimer?.cancel();
    super.dispose();
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

    // Saves new restriction time
    saveData();

      // Updates the app blocking status after changing the restriction start time
      updateAppBlocking();
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

      // Saves new restriction time
      saveData();

      // Updates the app blocking status after changing the restriction end time
      updateAppBlocking();
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

  // Checks if social media should currently be locked
  bool shouldLockSocialMedia() {

    // Locks social media if today's objectives are not completed
    if (allTodayObjectivesCompleted == false) {
      return true;
    }


    // Locks social media if it is currently restriction time
    if (isRestrictionTime() == true) {
      return true;
    }


    // Unlocks social media if all objectives are completed and it is not restriction time
    return false;
  }

  // Updates whether the social media apps are blocked or unblocked
  Future<void> updateAppBlocking() async {

    // Blocks the social media apps if they should be locked
    if (shouldLockSocialMedia() == true) {
      await appBlocker.blockApps(selectedApps);
    }


    // Unblocks the social media apps if they should be unlocked
    else {
      await appBlocker.unblockApps(selectedApps);
    }
  }

  // Adds a new objective to list with title, current date, and completed as false
  void addObjective(String title, String date) {
    final newObjective = {'id': nextObjectiveId, 'title': title, 'date': date, 'completed': false};

    // Updates the state of the app to include the new objective
    setState(() {
      objectives.add(newObjective);

      // Increases the next objective ID for the next objective to be added
      nextObjectiveId = nextObjectiveId + 1;
    });

    // Saves the updated data after adding a new objective
    saveData();

    // Updates the app blocking status after adding a new objective
    updateAppBlocking();
  }

  // Changes objective between completed and incompleted
  void toggleObjectiveCompleted(int id) {
    setState(() {

      // Searches through all objectives and toggles the completed status of the one with the matching title
      for (final objective in objectives) {
        if (objective['id'] == id) {
          objective['completed'] = !objective['completed'];
        }
      }
    });

    // Saves the updated data after toggling an objective's completed status
    saveData();

    // Updates the app blocking status after toggling an objective's completed status
    updateAppBlocking();
  }

  // Deletes an objective with the matching title from the list of objectives
  void deleteobjective(int id) {
    setState(() {
      objectives.removeWhere((objective) {
        return objective['id'] == id;
      });
    });

    // Saves the updated data after deleting an objective
    saveData();

    // Updates the app blocking status after deleting an objective
    updateAppBlocking();
  }

  @override
  Widget build(BuildContext context) {

    // List of pages in the app
    final List<Widget> pages = [
      HomeSection(  
      todayObjectives: todayObjectives,
      onAddObjective: addObjective,
      onToggleObjectiveCompleted: toggleObjectiveCompleted,
      isRestrictionTime: isRestrictionTime(),
      // Pass lock status to HomeSection
      shouldLock: shouldLockSocialMedia()
      ), // Pass data and functions to HomeSection
      ObjectivesSection(objectives: objectives, addObjective: addObjective, toggleObjectiveCompleted: toggleObjectiveCompleted, deleteObjective: deleteobjective),
      AnalyticsSection(
        // Pass usage data and function to AnalyticsSection
        todayUsage: todayUsage,
        thisWeekUsage: thisWeekUsage,
        lastWeekUsage: lastWeekUsage,
        updateAnalytics: updateAnalytics,
      ),
      SettingsSection(
      // Pass restriction times and functions to SettingsSection
      restrictionStartTime: restrictionStartTime,
      restrictionEndTime: restrictionEndTime,
      pickStartTime: pickRestrictionStartTime,
      pickEndTime: pickRestrictionEndTime,
      // Pass app selection data and functions to SettingsSection
      installedApps: installedApps,
      selectedApps: selectedApps,
      loadInstalledApps: loadInstalledApps,
      selectApp: selectApp,
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

  // Stores if social media should be locked or unlocked
  final bool shouldLock;

  // List of objectives for the current day
  final List<Map<String, dynamic>> todayObjectives;

  // Functions to add and toggle objectives
  final Function(String, String) onAddObjective;
  final Function(int) onToggleObjectiveCompleted;

  // Checks if the current time is within the restriction period
  final bool isRestrictionTime;


  const HomeSection({
    super.key,
    required this.todayObjectives,
    required this.onAddObjective,
    required this.onToggleObjectiveCompleted,
    required this.isRestrictionTime,
    required this.shouldLock,
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

    String lockMessage = '';

    // Message if social media is unlocked
    if (widget.shouldLock == false) {
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
                  widget.shouldLock ? Icons.lock : Icons.lock_open,
                  size: 70,
                  color: widget.shouldLock ? Colors.red : Colors.green,
                ),

                const SizedBox(height: 12),

                // Lock status text
                Text(
                  widget.shouldLock
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
                              objective['id'],
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
  final Function(int) toggleObjectiveCompleted;
  final Function(int) deleteObjective;

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
                      widget.toggleObjectiveCompleted(objective['id']);
                    },
                  ),

                    
                  // Delete button to remove the objective
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      widget.deleteObjective(objective['id']);
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
  final int todayUsage;
  final int thisWeekUsage;
  final int lastWeekUsage;

  final Function() updateAnalytics;

  const AnalyticsSection({
    super.key,
    required this.todayUsage,
    required this.thisWeekUsage,
    required this.lastWeekUsage,
    required this.updateAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Card showing today's social media usage
          Card(
            child: ListTile(
              title: const Text('Today\'s Usage'),
              subtitle: Text('$todayUsage minutes'),
            ),
          ),
          const SizedBox(height: 8.0),

          // Card showing this week's social media usage
          Card(
            child: ListTile(
              title: const Text('This Week\'s Usage'),
              subtitle: Text('$thisWeekUsage minutes'),
            ),
          ),
          const SizedBox(height: 8.0),

          // Card showing last week's social media usage
          Card(
            child: ListTile(
              title: const Text('Last Week\'s Usage'),
              subtitle: Text('$lastWeekUsage minutes'),
            ),
          ),
          const SizedBox(height: 16.0),
          // Button to refresh the analytics data
          FilledButton(
            onPressed: updateAnalytics,
            child: const Text('Refresh Analytics'),
          ),
          const Text(
            'Note: You may be prompted to grant permission to access app usage data when refreshing analytics.',
            style: TextStyle(fontSize: 12, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Widget for settings section
class SettingsSection extends StatelessWidget {

  final TimeOfDay restrictionStartTime;
  final TimeOfDay restrictionEndTime;

  final Function(BuildContext) pickStartTime;
  final Function(BuildContext) pickEndTime;

    // Stores the installed apps
  final List<AppInfo> installedApps;

  // Stores the apps selected to be blocked
  final List<String> selectedApps;

  // Functions used to load and select apps
  final Function() loadInstalledApps;
  final Function(String, bool) selectApp;


  const SettingsSection({
    super.key,
    required this.restrictionStartTime,
    required this.restrictionEndTime,
    required this.pickStartTime,
    required this.pickEndTime,
    required this.installedApps,
    required this.selectedApps,
    required this.loadInstalledApps,
    required this.selectApp,
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
          const SizedBox(height: 20),


// Heading for selecting apps to block
const Text(
  'Apps to Block',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
),

  const SizedBox(height: 10),

  // Button used to load the apps installed on the device
  FilledButton(
    onPressed: () {
      loadInstalledApps();
    },
    child: const Text('Choose Apps'),
  ),

  const SizedBox(height: 10),


  // Displays the installed apps
  Expanded(
    child: ListView.builder(

      // Number of installed apps
      itemCount: installedApps.length,

      itemBuilder: (context, index) {

        // Gets the app at the current position
        final app = installedApps[index];

        return CheckboxListTile(

          // Shows the app name
          title: Text(app.appName),

          // Shows whether the app is selected
          value: selectedApps.contains(app.packageName),

          // Changes the selected status when checkbox is pressed
          onChanged: (value) {

            if (value != null) {
              selectApp(app.packageName, value);
            }
          },
        );
      },
    ),
  ),

        ],
      ),
    );
  }
}
