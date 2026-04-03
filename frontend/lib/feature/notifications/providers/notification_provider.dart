import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watt_sense/core/network/api_client.dart';
import 'package:watt_sense/feature/notifications/models/notification_model.dart';

final _storageKey = 'cached_notifications';

final notificationListProvider =
    StateNotifierProvider<
      NotificationListNotifier,
      AsyncValue<List<AppNotification>>
    >((ref) => NotificationListNotifier());

class NotificationListNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationListNotifier() : super(const AsyncValue.loading()) {
    _loadCached();
    refresh();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      final list = decoded
          .whereType<Map>()
          .map((e) => AppNotification.fromMap(e.cast<String, dynamic>()))
          .toList();
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient.instance.get('/notifications');
      final data = response.data['data'] as List<dynamic>? ?? [];
      final list = data
          .whereType<Map>()
          .map((e) => AppNotification.fromMap(e.cast<String, dynamic>()))
          .toList();

      state = AsyncValue.data(list);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    final current = state.value ?? const <AppNotification>[];
    state = AsyncValue.data(
      current
          .map(
            (n) => n.id == id
                ? AppNotification(
                    id: n.id,
                    title: n.title,
                    body: n.body,
                    type: n.type,
                    data: n.data,
                    read: true,
                    sentAt: n.sentAt,
                  )
                : n,
          )
          .toList(),
    );

    try {
      await ApiClient.instance.patch('/notifications/$id/read');
    } catch (_) {
      // Best-effort; UI stays optimistic.
    }
  }
}
