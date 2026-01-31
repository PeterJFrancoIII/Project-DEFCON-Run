// Jobs v2 - Application Details & Messaging
// Worker view of an application with Chat

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../api.dart';
import '../utils/image_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class JobApplicationDetailScreen extends StatefulWidget {
  final JobsApi api;
  final String applicationId;
  final String? accountId; // For isMe check

  const JobApplicationDetailScreen({
    required this.api,
    required this.applicationId,
    this.accountId,
    super.key,
  });

  @override
  State<JobApplicationDetailScreen> createState() =>
      _JobApplicationDetailScreenState();
}

class _JobApplicationDetailScreenState
    extends State<JobApplicationDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _application;
  List<dynamic> _messages = [];
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Poll for messages every 5s if messaging allowed
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_application?['allow_messaging'] == true) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final appResp = await widget.api.getApplication(widget.applicationId);
    if (appResp.success && appResp.data != null) {
      if (mounted) {
        setState(() {
          _application = appResp.data;
        });
        // Check for messaging
        if (_application?['allow_messaging'] == true) {
          await _loadMessages();
        } else {
          setState(() => _loading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${appResp.error}')));
      }
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final msgResp = await widget.api.getMessages(widget.applicationId);
    if (msgResp.success) {
      if (mounted) {
        setState(() {
          _messages = msgResp.data ?? [];
          _loading = false;
        });
        // Mark messages as read
        widget.api.markMessagesRead(widget.applicationId);
        // Scroll to bottom
        if (_messages.isNotEmpty && !silent) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } else {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;

    _msgCtrl.clear();

    // Optimistic UI: Add pending message immediately
    final pendingMsg = {
      'message_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
      'content': txt,
      'sender_id': widget.accountId,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending', // sending | sent | failed
    };

    setState(() {
      _messages.add(pendingMsg);
    });
    _scrollToBottom();

    // Auto-retry up to 3 times
    bool success = false;
    String? error;
    for (int attempt = 1; attempt <= 3 && !success; attempt++) {
      final resp = await widget.api.sendMessage(widget.applicationId, txt);
      if (resp.success) {
        success = true;
        pendingMsg['status'] = 'sent';
      } else {
        error = resp.error;
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    if (!success) {
      pendingMsg['status'] = 'failed';
      pendingMsg['error'] = error;
    }

    if (mounted) {
      if (success) {
        _loadMessages(silent: true);
      } else {
        setState(() {}); // Refresh to show failed state
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send after 3 attempts: $error'),
            action: SnackBarAction(
                label: 'RETRY', onPressed: () => _retrySend(pendingMsg)),
          ),
        );
      }
    }
  }

  void _retrySend(Map<String, dynamic> pendingMsg) {
    pendingMsg['status'] = 'sending';
    setState(() {});

    widget.api
        .sendMessage(widget.applicationId, pendingMsg['content'])
        .then((resp) {
      if (resp.success) {
        _loadMessages(silent: true);
      } else {
        pendingMsg['status'] = 'failed';
        if (mounted) setState(() {});
      }
    });
  }

  // Static variable to track last warning time (session-based)
  static DateTime? _lastUploadWarning;

  Future<void> _attachPhoto() async {
    // Media Retention Policy Check (5 min cooldown)
    final now = DateTime.now();
    if (_lastUploadWarning == null ||
        now.difference(_lastUploadWarning!).inSeconds >= 30) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: SentinelJobsTheme.surface,
          title: const Text('Media Quality & Retention Policy',
              style: TextStyle(color: SentinelJobsTheme.textPrimary)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sentinel Chat uploads are compressed to 1080p JPG.',
                  style: SentinelJobsTheme.bodyStyle),
              SizedBox(height: 12),
              Text('• 30 Days: Archived (Low Quality)',
                  style: TextStyle(
                      color: SentinelJobsTheme.warning,
                      fontWeight: FontWeight.bold)),
              Text('• 2 Years: Permanently Deleted',
                  style: TextStyle(
                      color: SentinelJobsTheme.error,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text(
                  'Please save important photos elsewhere. For full quality/uncompressed, use Direct Text, Dropbox, or Email (10MB max).',
                  style: TextStyle(
                      fontSize: 12, color: SentinelJobsTheme.textMuted)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: SentinelJobsTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: SentinelJobsTheme.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('UNDERSTOOD & UPLOAD',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
      _lastUploadWarning = now;
    } else {
      // User is in cooldown period - Notify them
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Media Policy Cooldown Active: Policy previously accepted.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Use image picker to select multiple images (max 10)
    final images = await pickMultipleImages(maxImages: 10);
    if (images.isEmpty) return;

    if (!mounted) return;

    // Optimistic UI: Add pending messages with local bytes immediately
    final List<Map<String, dynamic>> pendingImageMsgs = [];

    setState(() {
      for (final bytes in images) {
        final pendingMsg = {
          'message_id': 'pending_img_${DateTime.now().microsecondsSinceEpoch}',
          'content': '',
          'image_url': null, // Will be set after upload
          'local_bytes': bytes, // For immediate preview
          'sender_id': widget.accountId,
          'created_at': DateTime.now().toIso8601String(),
          'status': 'sending',
        };
        pendingImageMsgs.add(pendingMsg);
        _messages.add(pendingMsg);
      }
    });
    _scrollToBottom();

    // Upload each image and send as message
    for (int i = 0; i < images.length; i++) {
      final bytes = images[i];
      final pendingMsg = pendingImageMsgs[i];

      try {
        final uploadResp = await widget.api.uploadChatImage(bytes);

        if (uploadResp.success && uploadResp.data != null) {
          final imageUrl = uploadResp.data!['image_url'];

          final sendResp = await widget.api.sendMessageWithImage(
            widget.applicationId,
            '',
            imageUrl,
          );

          if (sendResp.success && mounted) {
            setState(() {
              pendingMsg['status'] = 'sent';
              pendingMsg['image_url'] = imageUrl;
            });
          } else {
            if (mounted) {
              setState(() {
                pendingMsg['status'] = 'failed';
              });
              debugPrint('Send failed: ${sendResp.error}');
            }
          }
        } else {
          if (mounted) {
            setState(() {
              pendingMsg['status'] = 'failed';
            });
            debugPrint('Upload failed: ${uploadResp.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${uploadResp.error}')),
            );
          }
        }
      } catch (e) {
        debugPrint('Exception uploading: $e');
        if (mounted) {
          setState(() {
            pendingMsg['status'] = 'failed';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    // Refresh to get server timestamps/IDs eventually
    // _loadMessages(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _application == null) {
      return const Scaffold(
        backgroundColor: SentinelJobsTheme.background,
        body: Center(
            child: CircularProgressIndicator(color: SentinelJobsTheme.primary)),
      );
    }

    if (_application == null) {
      return Scaffold(
        backgroundColor: SentinelJobsTheme.background,
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Application not found')),
      );
    }

    final job = _application!['job_snapshot'] ?? {};
    final status = _application!['status'] ?? 'unknown';
    final messagingAllowed = _application!['allow_messaging'] == true;

    return Scaffold(
      backgroundColor: SentinelJobsTheme.background,
      appBar: AppBar(
        title: Text((job['title'] ?? 'APPLICATION').toString().toUpperCase(),
            style: SentinelJobsTheme.headerStyle),
        backgroundColor: SentinelJobsTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SentinelJobsTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _getStatusColor(status).withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATUS: ${status.toUpperCase()}',
                        style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    if (!messagingAllowed)
                      const Text('Waiting for Employer...',
                          style: TextStyle(
                              color: SentinelJobsTheme.textMuted, fontSize: 12))
                  ],
                )
              ],
            ),
          ),

          // 2. Job Details Summary
          ExpansionTile(
            title: const Text('MISSION BRIEF',
                style: SentinelJobsTheme.titleStyle),
            backgroundColor: SentinelJobsTheme.surfaceLight,
            collapsedBackgroundColor: SentinelJobsTheme.surfaceLight,
            childrenPadding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(job['description'] ?? 'No Description',
                    style: SentinelJobsTheme.bodyStyle),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Offer: ${job['pay'] != null ? "\$${job['pay']['min']}-${job['pay']['max']}" : "Unpaid"}',
                      style: const TextStyle(
                          color: SentinelJobsTheme.success,
                          fontWeight: FontWeight.bold)),
                  _application!['worker_name'] != null
                      ? Text('Applicant: ${_application!['worker_name']}',
                          style: SentinelJobsTheme.mutedStyle)
                      : const SizedBox()
                ],
              )
            ],
          ),

          // 3. Chat Area
          Expanded(
            child: messagingAllowed ? _buildChatList() : _buildLockedState(),
          ),

          // 4. Input Area (if allowed)
          if (messagingAllowed)
            Container(
              padding: const EdgeInsets.all(8),
              color: SentinelJobsTheme.surface,
              child: Row(
                children: [
                  // Attach photo button
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: SentinelJobsTheme.textMuted),
                    onPressed: _attachPhoto,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: SentinelJobsTheme.bodyStyle,
                      decoration: const InputDecoration(
                          hintText: 'Secure Channel...',
                          hintStyle: SentinelJobsTheme.mutedStyle,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send,
                        color: SentinelJobsTheme.primary),
                    onPressed: _sendMessage,
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline,
              size: 64, color: SentinelJobsTheme.textMuted),
          const SizedBox(height: 16),
          const Text('MESSAGING LOCKED',
              style: TextStyle(
                  color: SentinelJobsTheme.textMuted,
                  fontSize: 18,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Secure channel will open once Employer marks application as PENDING or ACCEPTED.',
              textAlign: TextAlign.center,
              style: SentinelJobsTheme.mutedStyle.copyWith(fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_messages.isEmpty) {
      return const Center(
          child: Text('Send the first message.',
              style: SentinelJobsTheme.mutedStyle));
    }

    // Build list with date headers
    List<Widget> items = [];
    String? lastDateLabel;

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final dateLabel = _getDateLabel(msg['created_at']);

      // Add date header if new day
      if (dateLabel != lastDateLabel) {
        items.add(_buildDateHeader(dateLabel));
        lastDateLabel = dateLabel;
      }

      final isMe =
          widget.accountId != null && msg['sender_id'] == widget.accountId;
      items.add(_buildMessageBubble(msg, isMe));
    }

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  String _getDateLabel(String? iso) {
    if (iso == null) return 'Unknown';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDate = DateTime(dt.year, dt.month, dt.day);

      if (msgDate == today) return 'TODAY';
      if (msgDate == today.subtract(const Duration(days: 1))) {
        return 'YESTERDAY';
      }
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: SentinelJobsTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: SentinelJobsTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final isRead = msg['read_at'] != null;
    final senderName = msg['sender_name'] ?? 'Unknown';
    final senderPhotoUrl = msg['sender_photo_url'] as String?;
    final isEmployer = msg['is_employer'] == true;
    final content = msg['content'] ?? '';
    final messageId = msg['message_id'];

    // Check if deletable: own message, unread, within 2 min
    bool canDelete = false;
    if (isMe && !isRead && msg['created_at'] != null) {
      try {
        final created = DateTime.parse(msg['created_at']);
        final age = DateTime.now().difference(created).inSeconds;
        canDelete = age < 120;
      } catch (_) {}
    }

    return GestureDetector(
      onLongPress: () => _showMessageActions(content, messageId, canDelete),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Avatar for other user (left side)
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: isEmployer
                    ? SentinelJobsTheme.warning.withValues(alpha: 0.2)
                    : SentinelJobsTheme.surfaceLight,
                backgroundImage: senderPhotoUrl != null
                    ? NetworkImage(senderPhotoUrl)
                    : null,
                child: senderPhotoUrl == null
                    ? Icon(
                        isEmployer ? Icons.business : Icons.person,
                        size: 16,
                        color: isEmployer
                            ? SentinelJobsTheme.warning
                            : SentinelJobsTheme.textMuted,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name for other user
                  if (!isMe)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isEmployer
                                ? SentinelJobsTheme.warning
                                : SentinelJobsTheme.textSecondary,
                          ),
                        ),
                        if (isEmployer) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 12, color: SentinelJobsTheme.warning),
                        ],
                      ],
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  // Message bubble
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: isMe
                            ? SentinelJobsTheme.primary.withValues(alpha: 0.15)
                            : SentinelJobsTheme.surfaceLight,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 12),
                        ),
                        border: Border.all(
                            color: isMe
                                ? SentinelJobsTheme.primary
                                    .withValues(alpha: 0.3)
                                : SentinelJobsTheme.textMuted
                                    .withValues(alpha: 0.1))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display image if present
                        if (msg['local_bytes'] != null ||
                            msg['image_url'] != null) ...[
                          Builder(builder: (context) {
                            // Case 1: Local bytes (Optimistic UI)
                            if (msg['local_bytes'] != null) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageProvider:
                                          MemoryImage(msg['local_bytes']),
                                      // No download for local bytes yet
                                    ),
                                  ));
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        msg['local_bytes'],
                                        width: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    if (msg['status'] == 'sending')
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }

                            // Case 2: Network URL
                            String url = msg['image_url'];
                            if (url.startsWith('/')) {
                              url = '${widget.api.baseUrl}$url';
                            }
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    imageProvider: NetworkImage(url),
                                    downloadUrl: url,
                                  ),
                                ));
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: SentinelJobsTheme.textMuted),
                                ),
                              ),
                            );
                          }),
                        ],
                        // Display text content
                        if ((msg['content'] ?? '').isNotEmpty)
                          Padding(
                            padding: (msg['local_bytes'] != null ||
                                    msg['image_url'] != null)
                                ? const EdgeInsets.only(top: 8)
                                : EdgeInsets.zero,
                            child: Text(msg['content'],
                                style: SentinelJobsTheme.bodyStyle),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Timestamp and status indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          msg['created_at'] != null
                              ? _formatTime(msg['created_at'])
                              : '...',
                          style: const TextStyle(
                              fontSize: 10,
                              color: SentinelJobsTheme.textMuted)),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        // Show sending/sent/failed/read status
                        if (msg['status'] == 'sending')
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: SentinelJobsTheme.textMuted,
                            ),
                          )
                        else if (msg['status'] == 'failed')
                          const Icon(Icons.error_outline,
                              size: 14, color: SentinelJobsTheme.error)
                        else
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: isRead
                                ? SentinelJobsTheme.primary
                                : SentinelJobsTheme.textMuted,
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Spacer for own messages (right side)
            if (isMe) const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  void _showMessageActions(String content, String? messageId, bool canDelete) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelJobsTheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: SentinelJobsTheme.primary),
              title: const Text('Copy Message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (canDelete && messageId != null)
              ListTile(
                leading:
                    const Icon(Icons.delete, color: SentinelJobsTheme.error),
                title: const Text('Delete Message'),
                subtitle: const Text('Within 2 min, unread only'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final resp = await widget.api.deleteMessage(messageId);
                  if (resp.success) {
                    _loadMessages(silent: true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message deleted')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(resp.error ?? 'Delete failed')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toUtc();
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final msgDate = DateTime.utc(dt.year, dt.month, dt.day);
      final yesterday = today.subtract(const Duration(days: 1));

      String prefix = "";
      if (msgDate == today) {
        prefix = "(Today) ";
      } else if (msgDate == yesterday) {
        prefix = "(Yesterday) ";
      }

      // Time format: 8:45 PM
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      final timeStr = "$hour:$minute $period";

      // Date format: 1/28
      final dateStr = "${dt.month}/${dt.day}";

      return "$prefix$dateStr $timeStr UTC";
    } catch (e) {
      return "";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return SentinelJobsTheme.success;
      case 'pending':
        return SentinelJobsTheme.warning;
      case 'declined':
        return SentinelJobsTheme.error;
      default:
        return SentinelJobsTheme.textMuted;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_empty;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final ImageProvider imageProvider;
  final String? downloadUrl;

  const FullScreenImageViewer({
    required this.imageProvider,
    this.downloadUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (downloadUrl != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download',
              onPressed: () => _launchDownload(context, downloadUrl!),
            ),
        ],
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image(image: imageProvider),
        ),
      ),
    );
  }

  Future<void> _launchDownload(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete download for $url')),
        );
      }
    }
  }
}
