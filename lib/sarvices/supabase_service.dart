import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yoga/sarvices/notification_services.dart';


class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient supabase = Supabase.instance.client;
  RealtimeChannel? _notificationChannel;

  // Realtime notifications listen karein
  void listenToNotifications(String userId) {
    // Pehle se channel hai to usse remove karein
    if (_notificationChannel != null) {
      supabase.removeChannel(_notificationChannel!);
    }

    // Naya channel banayein
    _notificationChannel = supabase
        .channel('notifications_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            print('New notification received: ${payload.newRecord}');
            
            // Local notification show karein
            final data = payload.newRecord;
            NotificationService().showNotification(
              id: data['id'].hashCode,
              title: data['title'] ?? 'New Notification',
              body: data['body'] ?? '',
              payload: data['id'].toString(),
            );
          },
        )
        .subscribe();
  }

  // Notifications fetch karein
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Notification ko read mark karein
  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Test notification bhejein
  Future<void> sendTestNotification(String userId) async {
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': 'Test Notification',
      'body': 'Yeh ek test notification hai! 🎉',
    });
  }

  // Cleanup
  void dispose() {
    if (_notificationChannel != null) {
      supabase.removeChannel(_notificationChannel!);
    }
  }
}