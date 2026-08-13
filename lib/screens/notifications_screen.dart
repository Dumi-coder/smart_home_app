import 'package:flutter/material.dart';
import '../models/notification_alert.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

enum _FilterTab { all, unread, critical }

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _service = FirestoreService();
  _FilterTab _tab = _FilterTab.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StreamBuilder<List<NotificationAlert>>(
          stream: _service.streamNotificationAlerts(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryActiveDark));
            }
            final all = snap.data!;
            final unreadCount = all.where((a) => !a.acknowledged).length;

            List<NotificationAlert> filtered;
            switch (_tab) {
              case _FilterTab.unread:
                filtered = all.where((a) => !a.acknowledged).toList();
                break;
              case _FilterTab.critical:
                filtered = all.where((a) => a.severity == AlertSeverity.critical).toList();
                break;
              case _FilterTab.all:
                filtered = all;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                _buildHeader(unreadCount),
                const SizedBox(height: 16),
                _buildTabs(),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text('Nothing here', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((alert) => NotificationCard(
                    alert: alert,
                    onDismiss: () => _service.dismissAlert(alert.id),
                    onTap: () {
                      if (!alert.acknowledged) _service.markAlertRead(alert.id);
                    },
                  )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Navigator.canPop(context))
              Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 4),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alerts', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Row(
                  children: [
                    Text('Notifications', style: AppFonts.display(fontSize: 23, fontWeight: FontWeight.w600)),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.statusError, borderRadius: BorderRadius.circular(10)),
                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
        if (unreadCount > 0)
          GestureDetector(
            onTap: () => _service.markAllAlertsRead(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Text('Mark all read', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }

  Widget _buildTabs() {
    Widget tabBtn(String label, _FilterTab tab) {
      final isSelected = _tab == tab;
      return GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.chipSelected : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: isSelected ? null : Border.all(color: AppColors.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tabBtn('All', _FilterTab.all),
        const SizedBox(width: 10),
        tabBtn('Unread', _FilterTab.unread),
        const SizedBox(width: 10),
        tabBtn('Critical', _FilterTab.critical),
      ],
    );
  }
}