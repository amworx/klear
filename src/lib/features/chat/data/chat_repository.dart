import '../domain/klear_message.dart';
import 'chat_remote_datasource.dart';

/// Thin wrapper over [ChatRemoteDataSource] so the UI never talks to Supabase
/// directly (repository pattern — mirrors `BookingsRepository`).
class ChatRepository {
  ChatRepository([ChatRemoteDataSource? dataSource])
      : _dataSource = dataSource ?? const ChatRemoteDataSource();

  final ChatRemoteDataSource _dataSource;

  Future<List<KlearMessage>> messages(String bookingId) =>
      _dataSource.fetchMessages(bookingId);

  Stream<List<KlearMessage>> streamMessages(String bookingId) =>
      _dataSource.streamMessages(bookingId);

  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String body,
  }) =>
      _dataSource.sendMessage(
        bookingId: bookingId,
        senderId: senderId,
        body: body,
      );
}
