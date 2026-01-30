import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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
      final portfolioRef = FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .collection('portfolio');

      final String symbol = stockData['symbol'];
      final querySnapshot = await portfolioRef
          .where('symbol', isEqualTo: symbol)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
     
        final doc = querySnapshot.docs.first;
        
        await doc.reference.update({
          'shares': stockData['shares'],
          'current_price': stockData['current_price'],
          'purchase_price': stockData['purchase_price'],
          'color': stockData['color'],
        });

        print("Hisse güncellendi: $symbol -> Yeni Adet: ${stockData['shares']}");

      } else {
        
        await portfolioRef.add(stockData);
        print("Yeni hisse eklendi: $symbol");
      }

    } catch (e) {
      print("Hisse işlemi sırasında hata oluştu: $e");
    }
  }

  static Future<void> deleteStockFromPortfolio(String username, String symbol) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .collection('portfolio')
          .where('symbol', isEqualTo: symbol)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print("Hisse silindi: $symbol");
    } catch (e) {
      print("Hisse silinirken hata oluştu: $e");
    }
  }

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

  static Future<String?> getProfileImagePath(String username) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();
          
      if (doc.exists && doc.data() != null) {
        return doc.data()!['profile_image_path'] as String?; 
      }
      return null;
    } catch (e) {
      print("Resim çekilemedi: $e");
      return null;
    }
  }

  static Future<String?> uploadProfileImage(String username, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${username.toLowerCase()}.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username.toLowerCase())
          .update({
            'profile_image_path': downloadUrl,
          });

      print("Resim yüklendi ve link kaydedildi: $downloadUrl");
      return downloadUrl;

    } catch (e) {
      print("Resim yükleme hatası: $e");
      return null;
    }
  }
}