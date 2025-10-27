import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get appwriteEndpoint =>
      dotenv.get('APPWRITE_ENDPOINT', fallback: '');

  static String get appwriteProjectId =>
      dotenv.get('APPWRITE_PROJECT_ID', fallback: '');

  static String get appwriteDatabaseId =>
      dotenv.get('APPWRITE_DATABASE_ID', fallback: '');

  static String get appwriteTransactionsCollectionId =>
      dotenv.get('APPWRITE_TRANSACTIONS_COLLECTION_ID', fallback: '');

  static String get androidClientId =>
      dotenv.get('ANDROID_CLIENT_ID', fallback: '');
}
