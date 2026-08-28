import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/presentation/auth_providers.dart';
import '../data/chat_repository.dart';
import '../domain/klear_message.dart';

/// Shared repository for the chat feature.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

/// Live messages for one booking. Loads history, then subscribes to realtime
/// inserts (channel closes on autoDispose).
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<KlearMessage>, String>((ref, bookingId) async* {
  final repo = ref.watch(chatRepositoryProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;

  final current = await repo.messages(bookingId);
  yield current;

  // Keep userId alive while subscribed so a mid-session sign-out stops the
  // stream cleanly.
  if (userId == null) return;
  yield* repo.streamMessages(bookingId);
});

/// Current signed-in user id (null when signed out) — used by the chat screen
/// to align bubbles and to set `sender_id` when posting.
final chatCurrentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});

/// Posts a message for the signed-in user, then refreshes the stream so the
/// echo is consistent with the server order.
Future<bool> sendBookingMessage(
  WidgetRef ref,
  String bookingId,
  String body,
) async {
  final trimmed = body.trim();
  final senderId = ref.read(chatCurrentUserIdProvider);
  if (trimmed.isEmpty || senderId == null) return false;
  await ref
      .read(chatRepositoryProvider)
      .sendMessage(bookingId: bookingId, senderId: senderId, body: trimmed);
  ref.invalidate(chatMessagesProvider(bookingId));
  return true;
}
