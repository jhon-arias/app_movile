import 'package:appwrite/appwrite.dart';
import 'package:gastos_app/app/env.dart';
import 'package:gastos_app/models/transaction_model.dart';

class AppWriteService {
  late Client client;
  late Account account;
  late Databases databases;

  AppWriteService() {
    _initialize();
  }

  void _initialize() {
    client = Client()
        .setEndpoint(Env.appwriteEndpoint)
        .setProject(Env.appwriteProjectId);

    account = Account(client);
    databases = Databases(client);
  }

  // Métodos de autenticación (solo email/password)
  Future<dynamic> createEmailPasswordAccount(
    String email,
    String password,
  ) async {
    try {
      return await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createEmailPasswordSession(
    String email,
    String password,
  ) async {
    try {
      return await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ELIMINADO: createOAuth2Session - Ya no se necesita

  Future<dynamic> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkSession() async {
    try {
      final session = await account.getSession(sessionId: 'current');
      return session.$id.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      rethrow;
    }
  }

  // Métodos para transacciones (sin cambios)
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      final result = await databases.createDocument(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.appwriteTransactionsCollectionId,
        documentId: ID.unique(),
        data: transaction.toMap(),
      );

      return Transaction.fromMap(result.data);
    } catch (e) {
      print('Error al agregar transacción: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<String> queries = [Query.equal('userId', userId)];

      if (startDate != null && endDate != null) {
        queries.add(
          Query.greaterThanEqual('date', startDate.toIso8601String()),
        );
        queries.add(Query.lessThanEqual('date', endDate.toIso8601String()));
      }

      // Ordenar por fecha descendente (más reciente primero)
      queries.add(Query.orderDesc('date'));

      final result = await databases.listDocuments(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.appwriteTransactionsCollectionId,
        queries: queries,
      );

      return result.documents
          .map((doc) => Transaction.fromMap(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Ajustar las fechas para incluir todo el día
      final adjustedEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final result = await databases.listDocuments(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.appwriteTransactionsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.greaterThanEqual('date', startDate.toIso8601String()),
          Query.lessThanEqual('date', adjustedEndDate.toIso8601String()),
          Query.orderDesc(
            'date',
          ), // Ordenar por fecha descendente (más reciente primero)
        ],
      );

      return result.documents
          .map((doc) => Transaction.fromMap(doc.data))
          .toList();
    } catch (e) {
      print('Error al obtener transacciones: $e');
      rethrow;
    }
  }

  // Método para eliminar una transacción
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await databases.deleteDocument(
        databaseId: Env.appwriteDatabaseId,
        collectionId: Env.appwriteTransactionsCollectionId,
        documentId: transactionId,
      );
    } catch (e) {
      print('Error al eliminar transacción: $e');
      rethrow;
    }
  }
}
