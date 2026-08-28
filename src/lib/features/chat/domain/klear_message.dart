/// A single chat line between a customer and the captain assigned to their
/// booking, read from the shared `booking_messages` Supabase table.
class KlearMessage {
  const KlearMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  bool get isMine => false; // resolved against the signed-in user by the UI.

  factory KlearMessage.fromMap(Map<String, dynamic> m) => KlearMessage(
        id: m['id'] as String,
        bookingId: m['booking_id'] as String,
        senderId: m['sender_id'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'booking_id': bookingId,
        'sender_id': senderId,
        'body': body,
        'created_at': createdAt.toIso8601String(),
      };
}
