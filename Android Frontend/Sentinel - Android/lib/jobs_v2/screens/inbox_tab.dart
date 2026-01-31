import 'package:flutter/material.dart';
import '../api.dart'; // Ensure correct import path relative to your structure
import '../theme.dart';
import 'application_detail_screen.dart';

class InboxTab extends StatefulWidget {
  final JobsApi api;
  final String? accountId;

  const InboxTab({required this.api, this.accountId, super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    setState(() => _loading = true);
    final resp = await widget.api.getInbox();
    if (mounted) {
      setState(() {
        _loading = false;
        if (resp.success && resp.data != null) {
          _conversations = resp.data!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: SentinelJobsTheme.primary));
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: SentinelJobsTheme.textMuted),
            SizedBox(height: 16),
            Text('No messages yet.', style: SentinelJobsTheme.mutedStyle),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInbox,
      color: SentinelJobsTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _buildConversationTile(_conversations[i]),
      ),
    );
  }

  Widget _buildConversationTile(dynamic convo) {
    final peerName = convo['peer_name'] ?? 'Unknown User';
    final jobTitle = convo['job_title'] ?? 'Job';
    final lastMsg = convo['last_message'] ?? '';
    final unreadCount = convo['unread_count'] ?? 0;
    final hasUnread = unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: SentinelJobsTheme.surfaceLight,
            child: Text(peerName[0].toUpperCase(),
                style: const TextStyle(color: SentinelJobsTheme.primary)),
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: SentinelJobsTheme.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(peerName,
          style: hasUnread
              ? SentinelJobsTheme.titleStyle
                  .copyWith(fontWeight: FontWeight.bold)
              : SentinelJobsTheme.titleStyle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(jobTitle.toUpperCase(),
              style: const TextStyle(
                  color: SentinelJobsTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasUnread
                  ? SentinelJobsTheme.bodyStyle
                      .copyWith(fontWeight: FontWeight.w600)
                  : SentinelJobsTheme.bodyStyle),
        ],
      ),
      trailing:
          const Icon(Icons.chevron_right, color: SentinelJobsTheme.textMuted),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobApplicationDetailScreen(
              api: widget.api,
              applicationId: convo['application_id'],
              accountId: widget.accountId,
            ),
          ),
        );
        _loadInbox(); // Refresh on return in case of new messages
      },
    );
  }
}
