import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_service.dart';
import '../domain/klear_message.dart';

/// Supabase access for booking chat. Mirrors the live-tracking datasource:
/// fetch history first, then subscribe to realtime inserts for the booking.
class ChatRemoteDataSource {
  const ChatRemoteDataSource();

  /// The booking's message history, oldest first.
  Future<List<KlearMessage>> fetchMessages(String bookingId) async {
    if (!SupabaseClientManager.isReady) return const [];
    final rows = await SupabaseClientManager.instance.client
        .from('booking_messages')
        .select('id, booking_id, sender_id, body, created_at')
        .eq('booking_id', bookingId)
        .order('created_at');
    return [
      for (final r in rows) KlearMessage.fromMap(Map<String, dynamic>.from(r)),
    ];
  }

  /// Live stream of new messages for this booking (INSERTs only).
  Stream<List<KlearMessage>> streamMessages(String bookingId) {
    final controller = StreamController<List<KlearMessage>>.broadcast();
    final client = SupabaseClientManager.instance.client;
    final channel = client
        .channel('chat:$bookingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'booking_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'booking_id',
            value: bookingId,
          ),
          callback: (payload) async {
            // Re-pull the whole history so ordering stays consistent.
            final msgs = await fetchMessages(bookingId);
            if (!controller.isClosed) controller.add(msgs);
          },
        )
        .subscribe();
    controller.onCancel = () async => client.removeChannel(channel);
    return controller.stream;
  }

  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String body,
  }) async {
    await SupabaseClientManager.instance.client
        .from('booking_messages')
        .insert({
          'booking_id': bookingId,
          'sender_id': senderId,
          'body': body,
        });
  }
}
