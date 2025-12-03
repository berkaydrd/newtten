import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_newtten/firebase_options.dart';
import 'package:flutter_application_newtten/utilities/firestore_service.dart' as FirestoreService;
import 'package:flutter_application_newtten/views/login_view.dart';
import 'package:flutter_application_newtten/views/register_view.dart';
import 'package:flutter_application_newtten/views/verify_email_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
      ),
      home: const LoginView(),
      routes: {
        '/login/': (context) => const LoginView(),
        '/register/': (context) => const RegisterView(),
        '/verify_email/': (context) => const VerifyEmailView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ), 
      builder: (context, snapshot){
        switch (snapshot.connectionState){
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              user.reload();
              if(user.emailVerified != false){
                return ProfilPage();
              }
              else {
                return const VerifyEmailView();
              }
            }
            else {
              return const LoginView();
          }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String _username = 'Yükleniyor...';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _username = 'Giriş Yapılmadı';
        });
      }
      return;
    }
    final fetchedUsername = await FirestoreService.getUsername(user.uid);
    if (mounted) {
      setState(() {
        _username = fetchedUsername ?? 'Misafir';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _username, 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
    );
  }
}