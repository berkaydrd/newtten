import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static Future<bool> isUsernameAvailable(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('usernames') 
        .where('username', isEqualTo: username.toLowerCase()) 
        .limit(1)
        .get();
    return result.docs.isEmpty; 
  }
}

Future<String?> getUsername(String uid) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(uid)
        .get(); 

    if (docSnapshot.exists) {
      return docSnapshot.data()?['username'] as String?;
    }
    return null; // Doküman yoksa
  } catch (e) {
    print('Kullanıcı adı çekilirken hata: $e');
    return null;
  }
}