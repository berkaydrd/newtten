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

  static Future<String?> getUsername(String uid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usernames')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return doc.data()['username'] as String?;
      }
      return null;
    } catch (e) {
      print('Kullanıcı adı çekilirken hata: $e');
      return null;
    }
  }

  static Future<void> addStockToPortfolio(String username, Map<String, dynamic> stockData) async {
    try {
      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .collection('portfolio')
          .add(stockData); 
      print("Hisse başarıyla eklendi.");
    } catch (e) {
      print("Hisse eklenirken hata oluştu: $e");
    }
  }

  static Future<void> deleteStockFromPortfolio(String username, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .collection('portfolio')
          .doc(docId)
          .delete();
      print("Hisse silindi.");
    } catch (e) {
      print("Hisse silinirken hata oluştu: $e");
    }
  }
  // firestore_service.dart içine:

static Stream<List<Map<String, dynamic>>> getPortfolioStream(String username) {
  return FirebaseFirestore.instance
      .collection('usernames')
      .doc(username.toLowerCase())
      .collection('portfolio')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['docId'] = doc.id; 
          return data;
        }).toList();
      });
}
}

