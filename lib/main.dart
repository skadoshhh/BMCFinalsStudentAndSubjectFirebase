import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Activity 3 App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UserRegistrationScreen(),
    );
  }
}

// Data model para mapasa ang data mula screen to screen
class EnrollmentData {
  String name = '';
  String section = '';
  String course = '';
  List<Map<String, String>> subjects = [];
}

// 1. USER REGISTRATION SCREEN
class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _courseController = TextEditingController();
  final EnrollmentData _data = EnrollmentData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _sectionController,
              decoration: const InputDecoration(labelText: 'Section'),
            ),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Course'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty &&
                    _sectionController.text.isNotEmpty &&
                    _courseController.text.isNotEmpty) {
                  _data.name = _nameController.text;
                  _data.section = _sectionController.text;
                  _data.course = _courseController.text;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectEnrollmentScreen(data: _data),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. SUBJECT ENROLLMENT SCREEN
class SubjectEnrollmentScreen extends StatefulWidget {
  final EnrollmentData data;
  const SubjectEnrollmentScreen({super.key, required this.data});

  @override
  State<SubjectEnrollmentScreen> createState() => _SubjectEnrollmentScreenState();
}

class _SubjectEnrollmentScreenState extends State<SubjectEnrollmentScreen> {
  final _subjectController = TextEditingController();
  final _timeController = TextEditingController();
  final List<Map<String, String>> _tempSubjects = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subject Enrollment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject (e.g. BAC)'),
            ),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'Time (e.g. 7:30 - 10:30)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_subjectController.text.isNotEmpty &&
                    _timeController.text.isNotEmpty) {
                  setState(() {
                    _tempSubjects.add({
                      'subject': _subjectController.text,
                      'time': _timeController.text,
                    });
                    _subjectController.clear();
                    _timeController.clear();
                  });
                }
              },
              child: const Text('Add Subject'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _tempSubjects.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Subject: ${_tempSubjects[index]['subject']}'),
                    subtitle: Text('Time: ${_tempSubjects[index]['time']}'),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_tempSubjects.isNotEmpty) {
                  widget.data.subjects = _tempSubjects;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectVerificationScreen(data: widget.data),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add at least one subject')),
                  );
                }
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. SUBJECT VERIFICATION / DETAILS SCREEN (FIRESTORE SAVE)
class SubjectVerificationScreen extends StatelessWidget {
  final EnrollmentData data;
  const SubjectVerificationScreen({super.key, required this.data});

  Future<void> _saveToFirestore(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('enrollments').add({
        'name': data.name,
        'section': data.section,
        'course': data.course,
        'subjects': data.subjects,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully saved to Firestore!')),
      );

      // Bumalik sa simula pagkatapos ma-save
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subject Verification Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${data.name}', style: const TextStyle(fontSize: 18)),
            Text('Section: ${data.section}', style: const TextStyle(fontSize: 18)),
            Text('Course: ${data.course}', style: const TextStyle(fontSize: 18)),
            const Divider(height: 30),
            const Text('Enrolled Subjects:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: data.subjects.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text('${index + 1}. ${data.subjects[index]['subject']}'),
                      subtitle: Text('Time: ${data.subjects[index]['time']}'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _saveToFirestore(context),
                child: const Text('Save to Firestore', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}