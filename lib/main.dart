import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
void main() {
  runApp(const KuchipudiApp());
}

class KuchipudiApp extends StatelessWidget {
  const KuchipudiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kuchipudi Connect',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;

  static const String usersKey = 'kuchipudi_registered_users';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsers = prefs.getString(usersKey);

    if (savedUsers == null || savedUsers.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(savedUsers);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((user) => Map<String, dynamic>.from(user))
            .toList();
      }
    } catch (_) {
      return [];
    }

    return [];
  }

  Future<void> loginUser() async {
    final enteredEmail = emailController.text.trim().toLowerCase();
    final enteredPassword = passwordController.text;

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
        ),
      );
      return;
    }

    final users = await _loadUsers();

    if (!mounted) return;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please register as a new user first.'),
        ),
      );
      return;
    }

    Map<String, dynamic>? user;

    for (final savedUser in users) {
      if (savedUser['email'] == enteredEmail) {
        user = savedUser;
        break;
      }
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect email. Please use your registered email.'),
        ),
      );
      return;
    }

    if (user['password'] != enteredPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password. Please use your registered password.'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuchipudi Connect'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  Icons.music_note,
                  size: 100,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to Kuchipudi Connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Learn, Explore and Connect with the world of Kuchipudi',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: loginUser,
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text('New User? Register Here'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER PAGE
// ============================================================

class RegisterPage extends StatefulWidget {
  static const String usersKey = 'kuchipudi_registered_users';

  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim().toLowerCase();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid Gmail address ending with @gmail.com';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(value)) {
      return 'Password must contain a special character';
    }

    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required';
    }

    if (value.trim().length < 2) {
      return 'Enter a valid name';
    }

    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim())) {
      return 'Name can contain only letters';
    }

    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim();

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit phone number';
    }

    if (!RegExp(r'^[6-9]').hasMatch(phone)) {
      return 'Enter a valid Indian mobile number';
    }

    // Reject obvious repeated-digit/fake patterns such as 9100000000.
    if (RegExp(r'([0-9])\1{6,}').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsers = prefs.getString(RegisterPage.usersKey);

    if (savedUsers == null || savedUsers.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(savedUsers);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((user) => Map<String, dynamic>.from(user))
            .toList();
      }
    } catch (_) {
      return [];
    }

    return [];
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      RegisterPage.usersKey,
      jsonEncode(users),
    );
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final phone = phoneController.text.trim();

    final users = await _loadUsers();

    final emailAlreadyRegistered = users.any(
      (user) => user['email'] == email,
    );

    if (!mounted) return;

    if (emailAlreadyRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This email is already registered. Please login with this email and password.',
          ),
        ),
      );
      return;
    }

    users.add({
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });

    await _saveUsers(users);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration successful! You can now login anytime.'),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registration'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: validateName,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: validatePhone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '10-digit mobile number',
                  prefixIcon: const Icon(Icons.phone),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                validator: validatePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Minimum 8 characters',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Password must contain:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                '• At least 8 characters\n'
                '• One uppercase letter (A-Z)\n'
                '• One lowercase letter (a-z)\n'
                '• One number (0-9)\n'
                '• One special character (!@#\$%)',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: registerUser,
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<Map<String, dynamic>> features = [
    {
      'title': 'Kuchipudi Lessons',
      'icon': Icons.play_circle_fill,
    },
    {
      'title': 'Dance Academies',
      'icon': Icons.school,
    },
    {
      'title': 'Events & Festivals',
      'icon': Icons.event,
    },
    {
      'title': 'Competitions',
      'icon': Icons.emoji_events,
    },
    {
      'title': 'Workshops',
      'icon': Icons.groups,
    },
    {
      'title': 'Teacher Details',
      'icon': Icons.person,
    },
    {
      'title': 'Auditoriums',
      'icon': Icons.location_city,
    },
    {
      'title': 'Feedback',
      'icon': Icons.feedback,
    },
  ];

  void openPage(BuildContext context, String title) {
    Widget page;

    switch (title) {
      case 'Kuchipudi Lessons':
        page = const LessonsPage();
        break;

      case 'Dance Academies':
        page = const AcademyPage();
        break;

      case 'Events & Festivals':
        page = const EventsPage();
        break;

      case 'Competitions':
        page = const CompetitionPage();
        break;

      case 'Workshops':
        page = const WorkshopPage();
        break;

      case 'Teacher Details':
        page = const TeacherPage();
        break;

      case 'Auditoriums':
        page = const AuditoriumPage();
        break;

      case 'Feedback':
        page = const FeedbackPage();
        break;

      default:
        page = const FeedbackPage();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuchipudi Connect'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            color: Colors.deepPurple.shade100,
            child: const Column(
              children: [
                Icon(
                  Icons.self_improvement,
                  size: 70,
                  color: Colors.deepPurple,
                ),

                SizedBox(height: 10),

                Text(
                  'Discover the Beauty of Kuchipudi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Learn • Practice • Perform • Connect',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: features.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    openPage(
                      context,
                      features[index]['title'] as String,
                    );
                  },

                  child: Card(
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          features[index]['icon'] as IconData,
                          size: 50,
                          color: Colors.deepPurple,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          features[index]['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

// ============================================================
// LESSONS PAGE
// ============================================================

class PracticeLessonPage extends StatefulWidget {
  final String lessonTitle;

  const PracticeLessonPage({
    super.key,
    required this.lessonTitle,
  });

  @override
  State<PracticeLessonPage> createState() => _PracticeLessonPageState();
}

class _PracticeLessonPageState extends State<PracticeLessonPage> {
  int seconds = 30;
  Timer? timer;
  bool isRunning = false;

  void startTimer() {
    if (isRunning) return;

    setState(() {
      isRunning = true;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (seconds > 0) {
          setState(() {
            seconds--;
          });
        } else {
          timer.cancel();

          setState(() {
            isRunning = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Practice time completed!',
              ),
            ),
          );
        }
      },
    );
  }

  void pauseTimer() {
    timer?.cancel();

    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    timer?.cancel();

    setState(() {
      seconds = 30;
      isRunning = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.lessonTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Practice Session',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Follow these steps carefully and practice each movement slowly.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Practice Instructions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                '1. Stand in the correct posture.\n\n'
                '2. Keep your body balanced.\n\n'
                '3. Follow the rhythm carefully.\n\n'
                '4. Practice each movement slowly.\n\n'
                '5. Repeat the movements several times.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  'Practice Timer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  '$seconds seconds',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),

                  const SizedBox(width: 10),

                  ElevatedButton.icon(
                    onPressed: pauseTimer,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),

                  const SizedBox(width: 10),

                  ElevatedButton.icon(
                    onPressed: resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Practice completed successfully!',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Practice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key});

  final List<String> lessons = const [
    'Introduction to Kuchipudi',
    'Basic Postures',
    'Hand Gestures - Mudras',
    'Footwork Techniques',
    'Facial Expressions - Abhinaya',
    'Kuchipudi Dance Performance',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuchipudi Lessons'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.play_circle),
              title: Text(
                lessons[index],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonDetailPage(
                      lessonTitle: lessons[index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
class LessonDetailPage extends StatelessWidget {
  final String lessonTitle;

  const LessonDetailPage({
    super.key,
    required this.lessonTitle,
  });

  @override
  Widget build(BuildContext context) {
    String description;

    switch (lessonTitle) {
      case 'Introduction to Kuchipudi':
        description =
            'Learn about the history, origin, and basic introduction of Kuchipudi dance.';
        break;

      case 'Basic Postures':
        description =
            'Learn the basic body positions and postures used in Kuchipudi dance.';
        break;

      case 'Hand Gestures - Mudras':
        description =
            'Learn important hand gestures and mudras used to express stories and emotions.';
        break;

      case 'Footwork Techniques':
        description =
            'Practice the basic footwork techniques and rhythmic movements of Kuchipudi.';
        break;

      case 'Facial Expressions - Abhinaya':
        description =
            'Learn facial expressions and Abhinaya techniques used to communicate emotions.';
        break;

      case 'Kuchipudi Dance Performance':
        description =
            'Learn how to combine movements, expressions, rhythm, and storytelling for a performance.';
        break;

      default:
        description =
            'Learn this Kuchipudi lesson step by step.';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lessonTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lessonTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'About this Lesson',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                description,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Practice Steps',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                '1. Learn the correct posture.\n\n'
                '2. Follow the teacher instructions.\n\n'
                '3. Practice the movements slowly.\n\n'
                '4. Repeat the steps with rhythm.\n\n'
                '5. Practice regularly to improve your performance.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PracticeLessonPage(
                          lessonTitle: lessonTitle,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Practice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACADEMY PAGE
// ============================================================

class AcademyPage extends StatelessWidget {
  const AcademyPage({super.key});

  static const List<String> academies = [
    'Kuchipudi Dance Academy',
    'Classical Dance Academy',
    'Traditional Dance Centre',
    'Kuchipudi Training Institute',
  ];
  static const List<String> academyLocations = [
  'Hyderabad, Telangana',
  'Chennai, Tamil Nadu',
  'Bengaluru, Karnataka',
  'Vijayawada, Andhra Pradesh',
];

static const List<String> academyTimings = [
  'Monday - Saturday, 5:00 PM - 7:00 PM',
  'Monday - Friday, 6:00 PM - 8:00 PM',
  'Tuesday - Saturday, 5:30 PM - 7:30 PM',
  'Monday - Saturday, 4:00 PM - 6:00 PM',
];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dance Academies'),
      ),
      body: ListView.builder(
        itemCount: academies.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(
                Icons.school,
                size: 40,
              ),
              title: Text(
                academies[index],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Kuchipudi dance training and classes',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
             onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AcademyDetailPage(
        academyName: academies[index],
        academyIndex: index,
      ),
    ),
  );
},
            ),
          );
        },
      ),
    );
  }
}
class AcademyDetailPage extends StatelessWidget {
  final String academyName;
  final int academyIndex;
  const AcademyDetailPage({
    super.key,
    required this.academyName,
    required this.academyIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(academyName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              academyName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Kuchipudi dance training and classes',
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Academy Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Learn Kuchipudi dance through structured lessons, '
              'practice sessions, and traditional dance techniques.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 25),

const ListTile(
  leading: Icon(Icons.location_on),
  title: Text('Location'),
  subtitle: Text('Kuchipudi Dance Centre'),
),

const ListTile(
  leading: Icon(Icons.access_time),
  title: Text('Class Timings'),
  subtitle: Text('Monday - Saturday, 5:00 PM - 7:00 PM'),
),

const ListTile(
  leading: Icon(Icons.phone),
  title: Text('Contact'),
  subtitle: Text('+91 98765 43210'),
),

const SizedBox(height: 20),

            const SizedBox(height: 30),

            Column(
  children: [
    Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LessonsPage(),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('View Lessons'),
      ),
    ),

    const SizedBox(height: 15),

    Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to Academies'),
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EVENTS PAGE
// ============================================================

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  static const List<Map<String, String>> events = [
    {
      'name': 'Kuchipudi Dance Festival',
      'date': '15 September 2026',
      'place': 'Mumbai',
    },
    {
      'name': 'Classical Dance Evening',
      'date': '10 October 2026',
      'place': 'Auditorium',
    },
    {
      'name': 'Cultural Dance Festival',
      'date': '25 November 2026',
      'place': 'Mumbai',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Festivals'),
      ),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(
                Icons.event,
                color: Colors.deepPurple,
                size: 40,
              ),
              title: Text(event['name']!),
              subtitle: Text(
                '${event['date']}\n${event['place']}',
              ),
              isThreeLine: true,
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EventDetailsPage(
        eventName: event['name']!,
        eventDate: event['date']!,
        eventPlace: event['place']!,
      ),
    ),
  );
},
            ),
          );
        },
      ),
    );
  }
}
class EventDetailsPage extends StatelessWidget {
  final String eventName;
  final String eventDate;
  final String eventPlace;

  const EventDetailsPage({
    super.key,
    required this.eventName,
    required this.eventDate,
    required this.eventPlace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              eventDate,
              style: const TextStyle(fontSize: 17),
            ),

            const SizedBox(height: 25),

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              eventPlace,
              style: const TextStyle(fontSize: 17),
            ),

            const SizedBox(height: 30),

            const Text(
              'About the Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'This event celebrates Kuchipudi dance, traditional performances, and Indian classical dance culture.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMPETITION PAGE
// ============================================================

class CompetitionPage extends StatelessWidget {
  const CompetitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dance Competitions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.emoji_events),
                title: Text(
                  'National Kuchipudi Competition',
                ),
                subtitle: Text(
                  'Registration is now open',
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
             onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CompetitionRegistrationPage(),
    ),
  );
},
              child: const Text(
                'Register for Competition',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================
// WORKSHOP PAGE
// ============================================================

class WorkshopPage extends StatelessWidget {
  const WorkshopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshops'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const KuchipudiBasicsWorkshopPage(),
                  ),
                );
              },
              leading: const Icon(Icons.groups),
              title: const Text('Kuchipudi Basics Workshop'),
              subtitle: const Text(
                'Learn basic steps and movements',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),

          Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AbhinayaWorkshopPage(),
                  ),
                );
              },
              leading: const Icon(Icons.groups),
              title: const Text('Abhinaya Workshop'),
              subtitle: const Text(
                'Learn facial expressions and emotions',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),

          Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AdvancedPerformanceWorkshopPage(),
                  ),
                );
              },
              leading: const Icon(Icons.groups),
              title: const Text('Advanced Performance Workshop'),
              subtitle: const Text(
                'Improve your stage performance',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KUCHIPUDI BASICS WORKSHOP PAGE
// ============================================================

class KuchipudiBasicsWorkshopPage extends StatelessWidget {
  const KuchipudiBasicsWorkshopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuchipudi Basics Workshop'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Icon(
              Icons.groups,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Kuchipudi Basics Workshop',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Learn basic Kuchipudi steps and movements.',
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kuchipudi Basics Workshop started',
                    ),
                  ),
                );
              },

              child: const Text(
                'Start Workshop',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// ABHINAYA WORKSHOP PAGE
// ============================================================

class AbhinayaWorkshopPage extends StatelessWidget {
  const AbhinayaWorkshopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abhinaya Workshop'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Icon(
              Icons.groups,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Abhinaya Workshop',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Learn facial expressions and emotions through Abhinaya.',
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Abhinaya Workshop started',
                    ),
                  ),
                );
              },

              child: const Text(
                'Start Workshop',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// ADVANCED PERFORMANCE WORKSHOP PAGE
// ============================================================

class AdvancedPerformanceWorkshopPage
    extends StatelessWidget {
  const AdvancedPerformanceWorkshopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advanced Performance Workshop',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Icon(
              Icons.groups,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Advanced Performance Workshop',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Improve your stage performance and advanced Kuchipudi skills.',
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Advanced Performance Workshop started',
                    ),
                  ),
                );
              },

              child: const Text(
                'Start Workshop',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================
// TEACHER PAGE
// ============================================================

class TeacherPage extends StatelessWidget {
  const TeacherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Card(
            child: ListTile(
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const GuruAnjaliPage(),
    ),
  );
},
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('Guru Anjali'),
              subtitle: Text(
                'Kuchipudi Teacher\n10 Years Experience',
              ),
            ),
          ),

          Card(
            child: ListTile(
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const GuruPriyaPage(),
    ),
  );
},
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('Guru Priya'),
              subtitle: Text(
                'Classical Dance Teacher\n8 Years Experience',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// GURU ANJALI PAGE
// ============================================================

class GuruAnjaliPage extends StatelessWidget {
  const GuruAnjaliPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guru Anjali'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person,
                size: 55,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Guru Anjali',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Kuchipudi Teacher',
              style: TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              '10 Years Experience',
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'About the Teacher',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Guru Anjali is a Kuchipudi teacher with '
              '10 years of teaching experience. '
              'She helps students learn traditional '
              'Kuchipudi dance techniques.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

         ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompetitionRegistrationPage(
          selectedTeacher: 'Guru Anjali',
        ),
      ),
    );
  },
  child: const Text('Select Teacher'),
),

          ],
        ),
      ),
    );
  }
}


// ============================================================
// GURU PRIYA PAGE
// ============================================================

class GuruPriyaPage extends StatelessWidget {
  const GuruPriyaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guru Priya'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const CircleAvatar(
              radius: 50,
              child: Icon(
                Icons.person,
                size: 55,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Guru Priya',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Classical Dance Teacher',
              style: TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              '8 Years Experience',
              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'About the Teacher',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Guru Priya is a classical dance teacher '
              'with 8 years of teaching experience. '
              'She guides students in classical dance '
              'and performance techniques.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

           ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompetitionRegistrationPage(
          selectedTeacher: 'Guru Priya',
        ),
      ),
    );
  },
  child: const Text('Select Teacher'),
),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// AUDITORIUM PAGE
// ============================================================

class AuditoriumPage extends StatelessWidget {
  const AuditoriumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoriums'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Card(
            child: ListTile(
              onTap: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nehru Centre Auditorium selected'),
        ),
      );
    },
              leading: Icon(Icons.location_city),
              title: Text(
                'Nehru Centre Auditorium',
              ),
              subtitle: Text('Mumbai'),
            ),
          ),

          Card(
            child: ListTile(
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ravindra Natya Mandir selected'),
      ),
    );
  },
              leading: Icon(Icons.location_city),
              title: Text(
                'Ravindra Natya Mandir',
              ),
              subtitle: Text('Mumbai'),
            ),
          ),

          Card(
            child: ListTile(
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cultural Performance Hall selected'),
      ),
    );
  },
              leading: Icon(Icons.location_city),
              title: Text(
                'Cultural Performance Hall',
              ),
              subtitle: Text('Mumbai'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FEEDBACK PAGE
// ============================================================

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController feedbackController =
      TextEditingController();

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Write your feedback',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Thank you for your feedback!',
                    ),
                  ),
                );
              },
              child: const Text(
                'Submit Feedback',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatelessWidget {
  final String studentName;
  final String selectedTeacher;

  const ProfilePage({
    super.key,
    this.studentName = 'Student',
    this.selectedTeacher = 'Not Selected',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 55,
              child: Icon(
                Icons.person,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Student Name'),
                subtitle: Text(studentName),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ),
            Card(
  child: ListTile(
    leading: const Icon(Icons.person),
    title: const Text('Teacher'),
    subtitle: Text(selectedTeacher),
    trailing: const Icon(Icons.arrow_forward_ios),
  ),
),

            Card(
              child: ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Dance Form'),
                subtitle: const Text('Kuchipudi'),
              ),
            ),

            Card(
  child: ListTile(
    leading: const Icon(Icons.emoji_events),
    title: const Text('Competition'),
    subtitle: const Text('Registered'),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompetitionRegistrationPage(
            selectedTeacher: selectedTeacher,
          ),
        ),
      );
    },
  ),
),
        const SizedBox(height: 25),

OutlinedButton.icon(
  onPressed: () {
    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  },
  icon: const Icon(Icons.logout),
  label: const Text('Back to Home'),
),
          ],
        ),
      ),
    );
  }
}
// ============================================================
// LESSON PLAYER PAGE
// ============================================================

class LessonPlayerPage extends StatefulWidget {
  const LessonPlayerPage({super.key});

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  late VideoPlayerController _controller;

@override
void initState() {
  super.initState();

  _controller = VideoPlayerController.networkUrl(
    Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
  );

  _controller.initialize().then((_) {
    setState(() {});
  });
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuchipudi Lesson'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
  'Lesson Progress',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

LinearProgressIndicator(
  value: 0.25,
),

const SizedBox(height: 10),

const Text(
  'Step 1 of 4',
  style: TextStyle(fontSize: 16),
),

const SizedBox(height: 20),
            _controller.value.isInitialized
    ? AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      )
    : const Center(
        child: CircularProgressIndicator(),
      ),

            const SizedBox(height: 20),

            const Text(
              'Kuchipudi Lesson Player',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Welcome to the Kuchipudi lesson. '
              'Follow the lesson step by step and practice '
              'the dance movements.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                    _controller.pause();
                    } else {
                       _controller.play();
    }
  });
},
                icon: Icon(
    _controller.value.isPlaying
        ? Icons.pause
        : Icons.play_arrow,
  ),
  label: Text(
    _controller.value.isPlaying
        ? 'Pause Lesson'
        : 'Play Lesson',
  ),
              ),
            ),
          const SizedBox(height: 30),
const Text(
  'Lesson Overview',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 15),

const Text(
  'Learn basic Kuchipudi posture, hand movements, footwork, and complete movements.',
  style: TextStyle(
    fontSize: 16,
    height: 1.5,
  ),
),

const SizedBox(height: 30),
const Text(
  'Lesson Steps',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 15),

Card(
  child: ListTile(
    leading: const Icon(Icons.looks_one),
    title: const Text('Learn the basic posture'),
    onTap: () {
       Navigator.push(
         context,
        MaterialPageRoute(
          builder: (context) => const PracticeStepPage(
            stepNumber: 1,
            title: 'Learn the basic posture',
      ),
    ),
  );
},
  ),
),

const SizedBox(height: 10),

Card(
  child: ListTile(
    leading: const Icon(Icons.looks_two),
    title: const Text('Practice hand movements'),
    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const PracticeStepPage(
        stepNumber: 2,
        title: 'Practice hand movements',
      ),
    ),
  );
},
  ),
),
const SizedBox(height: 10),

Card(
  child: ListTile(
    leading: const Icon(Icons.looks_3),
    title: const Text('Practice basic footwork'),
    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const PracticeStepPage(
        stepNumber: 3,
        title: 'Practice basic footwork',
      ),
    ),
  );
},
  ),
),

const SizedBox(height: 10),

Card(
  child: ListTile(
    leading: const Icon(Icons.looks_4),
    title: const Text('Practice the complete movement'),
    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const PracticeStepPage(
        stepNumber: 4,
        title: 'Practice the complete movement',
      ),
    ),
  );
},
  ),
),
          ],
        ),
      ),
    );
  }
}
class PracticeStepPage extends StatefulWidget {
  final int stepNumber;
  final String title;

  const PracticeStepPage({
    super.key,
    required this.stepNumber,
    required this.title,
  });

  @override
  State<PracticeStepPage> createState() => _PracticeStepPageState();
}

class _PracticeStepPageState extends State<PracticeStepPage> {
  String _getNextStepTitle() {
  switch (widget.stepNumber + 1) {
    case 2:
      return 'Practice hand movements';
    case 3:
      return 'Practice basic footwork';
    case 4:
      return 'Practice the complete movement';
    default:
      return '';
  }
}
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${widget.stepNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step ${widget.stepNumber}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 25),
            Text(
  'Progress: Step ${widget.stepNumber} of 4',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 8),

LinearProgressIndicator(
  value: widget.stepNumber / 4,
),

const SizedBox(height: 25),

            const Text(
              'Practice this movement carefully and follow the lesson instructions.',
              style: TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 35),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isCompleted = !isCompleted;
                  });
                },
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  isCompleted
                      ? 'Completed'
                      : 'Mark as Completed',
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isCompleted)
              Center(
                child: Text(
                  '✓ Step completed successfully!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.stepNumber == 4 && isCompleted)
  const Center(
    child: Text(
      '🎉 Lesson Completed!',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
if (widget.stepNumber == 4 && isCompleted)
  Center(
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.arrow_back),
      label: const Text('Back to Lessons'),
    ),
  ),
  if (widget.stepNumber == 4 && isCompleted)
  Center(
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LessonPlayerPage(),
          ),
        );
      },
      icon: const Icon(Icons.replay),
      label: const Text('Restart Lesson'),
    ),
  ),
const SizedBox(height: 25),

if (widget.stepNumber < 4)
  Center(
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PracticeStepPage(
              stepNumber: widget.stepNumber + 1,
              title: _getNextStepTitle(),
            ),
          ),
        );
      },
      icon: const Icon(Icons.arrow_forward),
      label: const Text('Next Step'),
    ),
  ),
          ],
        ),
      ),
    );
  }
}
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kuchipudi Learning Progress',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            LinearProgressIndicator(
              value: 0.75,
              minHeight: 10,
            ),

            const SizedBox(height: 12),

            const Text(
              '75% Completed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Practice Steps Completed'),
                subtitle: const Text('3 out of 4 steps completed'),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Lessons Completed'),
                subtitle: const Text('1 lesson completed'),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('Learning Status'),
                subtitle: const Text('Keep practicing to complete the lesson!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  static const List<String> practiceItems = [
    'Basic Posture Practice',
    'Hand Gestures Practice',
    'Footwork Practice',
    'Facial Expressions Practice',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: practiceItems.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(
                Icons.self_improvement,
                size: 40,
              ),
              title: Text(
                practiceItems[index],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Tap to start practice',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PracticeStepPage(
        stepNumber: index + 1,
        title: practiceItems[index],
      ),
    ),
  );
},
            ),
          );
        },
      ),
    );
  }
}
class CompetitionRegistrationPage extends StatefulWidget {
  final String selectedTeacher;

  const CompetitionRegistrationPage({
    super.key,
    this.selectedTeacher = '',
  });

  @override
  State<CompetitionRegistrationPage> createState() =>
      _CompetitionRegistrationPageState();
}

class _CompetitionRegistrationPageState
    extends State<CompetitionRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final academyController = TextEditingController();

  String level = 'Beginner';

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    emailController.dispose();
    academyController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.deepPurple,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Competition Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // Competition Header
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'National Kuchipudi Competition',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Register yourself and showcase your Kuchipudi talent.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Selected Teacher
              if (widget.selectedTeacher.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),

                    title: const Text(
                      'Selected Teacher',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      widget.selectedTeacher,
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // Student Name
              // Student Name
TextFormField(
  controller: nameController,
  keyboardType: TextInputType.name,
  decoration: const InputDecoration(
    labelText: 'Student Name',
    prefixIcon: Icon(Icons.person),
    border: OutlineInputBorder(),
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    return null;
  },
),

              const SizedBox(height: 15),

              // Age
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,

                decoration: fieldDecoration(
                  label: 'Age',
                  icon: Icons.cake,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your age';
                  }

                  final age = int.tryParse(value);

                  if (age == null || age < 5 || age > 100) {
                    return 'Please enter a valid age';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // Phone
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],

                decoration: fieldDecoration(
                  label: 'Phone Number',
                  icon: Icons.phone,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }

                  final phone = value.trim();

                  if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                    return 'Enter a valid 10-digit phone number';
                  }

                  if (!RegExp(r'^[6-9]').hasMatch(phone)) {
                    return 'Enter a valid Indian mobile number';
                  }

                  // Reject obvious repeated-digit/fake patterns such as 9100000000.
                  if (RegExp(r'([0-9])\1{6,}').hasMatch(phone)) {
                    return 'Enter a valid phone number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,

                decoration: fieldDecoration(
                  label: 'Email',
                  icon: Icons.email,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }

                  final email = value.trim();
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
                  );

                  if (!emailRegex.hasMatch(email)) {
                    return 'Enter a valid Gmail address ending with @gmail.com';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              // Academy
              TextFormField(
                controller: academyController,
                textCapitalization: TextCapitalization.words,

                decoration: fieldDecoration(
                  label: 'Academy Name',
                  icon: Icons.school,
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your academy name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Dance Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // Dance Level
              DropdownButtonFormField<String>(
                initialValue: level,

                decoration: fieldDecoration(
                  label: 'Dance Level',
                  icon: Icons.trending_up,
                ),

                items: const [
                  DropdownMenuItem(
                    value: 'Beginner',
                    child: Text('Beginner'),
                  ),

                  DropdownMenuItem(
                    value: 'Intermediate',
                    child: Text('Intermediate'),
                  ),

                  DropdownMenuItem(
                    value: 'Advanced',
                    child: Text('Advanced'),
                  ),
                ],

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      level = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 25),

              // Information Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Padding(
                  padding: EdgeInsets.all(16),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Icon(
                        Icons.info_outline,
                        color: Colors.deepPurple,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Please make sure all information is correct before submitting your registration.',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),

                  label: const Text(
                    'Submit Registration',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RegistrationSuccessPage(
                            studentName: nameController.text,
                            selectedTeacher: widget.selectedTeacher,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
class RegistrationSuccessPage extends StatelessWidget {
  final String studentName;
  final String selectedTeacher;

  const RegistrationSuccessPage({
    super.key,
    required this.studentName,
    required this.selectedTeacher,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Successful'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),

              const SizedBox(height: 20),

              const Text(
                'Registration Successful!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

              Text(
                'Thank you, $studentName!',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Your competition registration has been submitted successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 15),

              const Text(
                'Registration ID: KUC2026-001',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          studentName: studentName,
          selectedTeacher: selectedTeacher,
        ),
      ),
    );
  },
  child: const Text('View My Profile'),
),

              const SizedBox(height: 15),

              OutlinedButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
