import 'package:e_ticketing/features/tickets/domain/entities/ticket_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/role_enum.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../widgets/status_badge.dart';
import '../providers/ticket_provider.dart';
import '../widgets/ticket_tracking_stepper.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/attachment_preview.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final TicketEntity ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  CommentEntity? _replyingTo;
  List<CommentEntity> _comments = [];
  bool _loadingComments = true;
  final Set<String> _expandedReplies = {}; // Track which replies are expanded

  // Helper to resolve any stored attachment string to a full URL
  String _resolveAttachmentUrl(String path) {
    if (path.startsWith('http')) return path;
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    final clean = path.startsWith('/') ? path.substring(1) : path;
    if (clean.startsWith('uploads/')) {
      return '$base/$clean';
    }
    return '$base/uploads/attachments/$clean';
  }

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await ref.read(ticketRepositoryProvider).getComments(widget.ticket.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingComments = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    // 1. Pantau perubahan list tiket secara global
    final ticketsAsync = ref.watch(ticketListProvider);

    return ticketsAsync.when(
      data: (tickets) {
        TicketEntity currentTicket;
        try {
          currentTicket = tickets.firstWhere((t) => t.id == widget.ticket.id);
        } catch (_) {
          currentTicket = widget.ticket;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(title: Text(currentTicket.id)),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- INFORMASI TIKET ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: currentTicket.status),
                          _buildPriorityTag(currentTicket.priority),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentTicket.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        // style: Theme.of(context).textTheme.headlineSmall
                        //     ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Created on: ${currentTicket.createdAt.toString().split('.')[0]}",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const Divider(height: 40),
                      // Gunakan operator spread (...) dengan list if untuk menyisipkan widget secara kondisional
                      if (user?.role.name == 'admin') ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Assign Helpdesk",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AdminAssignDropdown(
                          ticketId: currentTicket.id,
                          currentAssignedTo: currentTicket.assignedTo,
                        ),
                        if (currentTicket.status == TicketStatus.resolved ||
                            currentTicket.status == TicketStatus.inProgress) ...[
                          const SizedBox(height: 24),
                          const Text(
                            "Update Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _AdminStatusDropdown(
                            currentStatus: currentTicket.status,
                            onStatusChanged: (status) {
                              if (status == TicketStatus.resolved) {
                                ref
                                    .read(ticketListProvider.notifier)
                                    .resolveTicket(currentTicket.id);
                              } else {
                                ref
                                    .read(ticketListProvider.notifier)
                                    .updateStatus(currentTicket.id, status);
                              }
                            },
                          ),
                        ],
                      ] else if (user?.role.name == 'helpdesk') ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Update Status",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (currentTicket.status != TicketStatus.inProgress)
                              ActionChip(
                                label: const Text('In Progress'),
                                onPressed: () {
                                  ref
                                      .read(ticketListProvider.notifier)
                                      .updateStatus(currentTicket.id, TicketStatus.inProgress);
                                },
                                backgroundColor: currentTicket.status == TicketStatus.inProgress
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                    : null,
                              ),
                            if (currentTicket.status != TicketStatus.pending)
                              ActionChip(
                                label: const Text('Pending'),
                                onPressed: () {
                                  ref
                                      .read(ticketListProvider.notifier)
                                      .updateStatus(currentTicket.id, TicketStatus.pending);
                                },
                                backgroundColor: currentTicket.status == TicketStatus.pending
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                    : null,
                              ),
                          ],
                        ),
                      ],
                      if (user?.role.name == 'admin' || user?.role.name == 'helpdesk')
                        const Divider(height: 50),

                      const Text(
                        "Tracking Status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Masukkan widget Stepper di sini
                      TicketTrackingStepper(
                        currentStatus: currentTicket.status,
                      ),
                      const Divider(height: 50),

                      Text(
                        "Description",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentTicket.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- LAMPIRAN ---
                      if (currentTicket.attachments.isNotEmpty) ...[
                        Text(
                          "Attachments",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAttachmentList(currentTicket.attachments),
                      ],

                      const Divider(height: 50),

                      // --- KOMENTAR (Menggunakan currentTicket) ---
                      const Text(
                        "Comments",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_loadingComments)
                        const Center(child: CircularProgressIndicator())
                      else if (_comments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "Belum ada komentar",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _buildCommentTree(_comments).length,
                          itemBuilder: (context, index) {
                            final comment = _buildCommentTree(_comments)[index];
                            return _buildCommentItem(
                              comment,
                              isDark: Theme.of(context).brightness == Brightness.dark,
                              currentTicketId: currentTicket.id,
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // 3. Bar Input Komentar
              _buildCommentInput(user, currentTicket.id),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  // Helper Widget: List Lampiran
  Widget _buildAttachmentList(List<String> paths) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        itemBuilder: (context, index) {
          final url = _resolveAttachmentUrl(paths[index]);
          return GestureDetector(
            onTap: () {
              AttachmentPreviewDialog.show(
                context,
                url: url,
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(url, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  // Helper untuk ubah flat list ke tree structure
  List<CommentEntity> _buildCommentTree(List<CommentEntity> flatList) {
    final Map<String?, List<CommentEntity>> map = {};
    for (var c in flatList) {
      map[c.parentCommentId] ??= [];
      map[c.parentCommentId]!.add(c);
    }
    List<CommentEntity> roots = [];
    for (var c in flatList) {
      if (c.parentCommentId == null) {
        roots.add(CommentEntity(
          id: c.id,
          senderName: c.senderName,
          senderId: c.senderId,
          message: c.message,
          timestamp: c.timestamp,
          replies: map[c.id] ?? [],
        ));
      }
    }
    return roots;
  }

  // Helper Widget: Item Komentar Rekursif
  Widget _buildCommentItem(
    CommentEntity comment, {
    bool isReply = false,
    bool? isDark,
    String? currentTicketId,
  }) {
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;
    final replyGuideColor = dark ? Colors.grey.shade700 : Colors.grey.shade300;
    final indentPadding = isReply ? 48.0 : 0.0;
    final commentBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                comment.senderName.isNotEmpty ? comment.senderName[0] : '?',
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              comment.senderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            Text(
              "${comment.timestamp.hour}:${comment.timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 11,
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dark ? Colors.grey.shade700 : Colors.grey.shade200),
          ),
          child: Text(
            comment.message,
            style: TextStyle(color: dark ? Colors.white : Colors.black),
          ),
        ),
          if (!isReply)
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _replyingTo = comment),
                  child: Text(
                    "Balas",
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (_canDeleteComment(comment) && currentTicketId != null)
                  TextButton(
                    onPressed: () => _confirmDeleteComment(
                      currentTicketId: currentTicketId,
                      comment: comment,
                    ),
                    child: Text(
                      "Hapus",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          if (comment.replies.isNotEmpty)
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_expandedReplies.contains(comment.id)) {
                      _expandedReplies.remove(comment.id);
                    } else {
                      _expandedReplies.add(comment.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _expandedReplies.contains(comment.id)
                        ? "Hide replies"
                        : "Show ${comment.replies.length} reply(s)",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              if (_expandedReplies.contains(comment.id))
                ...comment.replies.map(
                  (reply) => _buildCommentItem(
                    reply,
                    isDark: dark,
                    isReply: true,
                    currentTicketId: currentTicketId,
                  ),
                ),
            ],
          ),
      ],
    );

    if (!isReply) {
      return Padding(
        padding: EdgeInsets.only(left: indentPadding, bottom: 16.0),
        child: commentBody,
      );
    }

    // Reply: indent + left border guide line to visually indicate it's a reply.
    return Padding(
      padding: EdgeInsets.only(left: indentPadding, bottom: 16.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: replyGuideColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: commentBody),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Input Bar
  Widget _buildCommentInput(dynamic user, String ticketId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Membalas ${_replyingTo!.senderName}...",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Tulis komentar...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                onPressed: () async {
                  if (_commentController.text.trim().isEmpty) return;
                  final newComment = CommentEntity(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    senderName: user?.name ?? "User",
                    senderId: user?.id ?? "unknown",
                    message: _commentController.text,
                    timestamp: DateTime.now(),
                    replies: [],
                  );
                  await ref
                      .read(ticketListProvider.notifier)
                      .sendComment(
                        ticketId: ticketId,
                        comment: newComment,
                        parentCommentId: _replyingTo?.id,
                      );
                  _commentController.clear();
                  setState(() => _replyingTo = null);
                  // Refresh comments
                  await _fetchComments();
                  FocusScope.of(context).unfocus();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Delete Comment ────────────────────────────────────────────────────

  /// Cek apakah user saat ini boleh menghapus komentar.
  /// Boleh jika: user adalah pengirim komentar, atau user adalah admin.
  bool _canDeleteComment(CommentEntity comment) {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    if (user.id == comment.senderId) return true;
    return user.role == UserRole.admin;
  }

  /// Tampilkan dialog konfirmasi, lalu panggil API hapus komentar.
  Future<void> _confirmDeleteComment({
    required String currentTicketId,
    required CommentEntity comment,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Komentar'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus komentar ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Tampilkan loading indicator sederhana
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref
          .read(ticketListProvider.notifier)
          .deleteComment(currentTicketId, comment.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // tutup loading
      await _fetchComments(); // refresh list lokal

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus komentar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPriorityTag(dynamic priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _AdminStatusDropdown extends StatefulWidget {
  final TicketStatus currentStatus;
  final void Function(TicketStatus status) onStatusChanged;

  const _AdminStatusDropdown({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  State<_AdminStatusDropdown> createState() => _AdminStatusDropdownState();
}

class _AdminStatusDropdownState extends State<_AdminStatusDropdown> {
  TicketStatus? _selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Admin options:
    // - Open: only appears when ticket is Resolved (to reopen)
    // - Resolved: only appears when ticket is In Progress
    final options = <TicketStatus>[
      if (widget.currentStatus == TicketStatus.resolved) TicketStatus.open,
      if (widget.currentStatus == TicketStatus.inProgress) TicketStatus.resolved,
    ];

    return Column(
      children: [
        ...options.map((s) {
          return RadioListTile<TicketStatus>(
            title: Row(
              children: [
                Icon(
                  s == TicketStatus.resolved
                      ? Icons.check_circle_outline
                      : Icons.refresh,
                  size: 20,
                  color: s == TicketStatus.resolved ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  s == TicketStatus.resolved ? 'Resolved (tutup tiket)' : 'Open (buka kembali)',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            value: s,
            groupValue: _selected,
            onChanged: (value) {
              setState(() => _selected = value);
            },
            activeColor: s == TicketStatus.resolved ? Colors.green : Theme.of(context).colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          );
        }),
        if (_selected != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onStatusChanged(_selected!),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selected == TicketStatus.resolved
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _selected == TicketStatus.resolved
                    ? 'Konfirmasi Resolve'
                    : 'Buka Kembali Tiket',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AdminAssignDropdown extends ConsumerStatefulWidget {
  final String ticketId;
  final String? currentAssignedTo;

  const _AdminAssignDropdown({
    required this.ticketId,
    this.currentAssignedTo,
  });

  @override
  ConsumerState<_AdminAssignDropdown> createState() => _AdminAssignDropdownState();
}

class _AdminAssignDropdownState extends ConsumerState<_AdminAssignDropdown> {
  String? _selectedHelpdeskId;

  @override
  void initState() {
    super.initState();
    _selectedHelpdeskId = widget.currentAssignedTo;
  }

  @override
  void didUpdateWidget(covariant _AdminAssignDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAssignedTo != widget.currentAssignedTo) {
      setState(() {
        _selectedHelpdeskId = widget.currentAssignedTo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpdesksAsync = ref.watch(helpdeskListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return helpdesksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Text(
        'Gagal memuat daftar helpdesk: $err',
        style: const TextStyle(color: Colors.red),
      ),
      data: (helpdesks) {
        if (helpdesks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Belum ada akun helpdesk yang terdaftar.'),
              ],
            ),
          );
        }

        // Check if current selected ID is in list, if not set to null
        final hasMatch = helpdesks.any((h) => h.id == _selectedHelpdeskId);
        if (!hasMatch) {
          _selectedHelpdeskId = null;
        }

        final bool isChanged = _selectedHelpdeskId != widget.currentAssignedTo;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedHelpdeskId,
                  hint: const Text('Pilih Helpdesk...'),
                  isExpanded: true,
                  dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Belum Ditugaskan (Unassigned)'),
                    ),
                    ...helpdesks.map((h) {
                      return DropdownMenuItem<String>(
                        value: h.id,
                        child: Text(h.name),
                      );
                    }),
                  ],
                  onChanged: (newId) {
                    setState(() {
                      _selectedHelpdeskId = newId;
                    });
                  },
                ),
              ),
            ),
            if (isChanged) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedHelpdesk = helpdesks.firstWhere(
                      (h) => h.id == _selectedHelpdeskId,
                      orElse: () => UserModel(
                        id: '',
                        name: 'Belum Ditugaskan',
                        email: '',
                        role: UserRole.user,
                      ),
                    );

                    await ref.read(ticketListProvider.notifier).assignTicket(
                          widget.ticketId,
                          _selectedHelpdeskId ?? '',
                          selectedHelpdesk.name,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Konfirmasi Penugasan'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
