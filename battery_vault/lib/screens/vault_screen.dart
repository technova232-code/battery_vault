import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/vault_service.dart';

class VaultScreen extends StatefulWidget {
  final VoidCallback onLock;
  const VaultScreen({super.key, required this.onLock});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VaultItem> _items = [];
  bool _loading = true;

  final tabs = ['photo', 'video', 'file', 'note'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadItems();
    });
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final type = tabs[_tabController.index];
    final items = await VaultService.getAllItems(type: type);
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _addItem() async {
    final l10n = AppLocalizations.of(context)!;
    final type = tabs[_tabController.index];
    switch (type) {
      case 'photo':
        await _pickMedia(ImageSource.gallery, 'photo');
        break;
      case 'video':
        await _pickVideo();
        break;
      case 'file':
        await _pickFile();
        break;
      case 'note':
        await _addNote();
        break;
    }
  }

  Future<void> _pickMedia(ImageSource source, String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    await VaultService.addFile(File(picked.path), type);
    _loadItems();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await VaultService.addFile(File(picked.path), 'video');
    _loadItems();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    await VaultService.addFile(File(path), 'file');
    _loadItems();
  }

  Future<void> _addNote() async {
    final l10n = AppLocalizations.of(context)!;
    String title = '';
    String content = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.addNote,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: l10n.noteTitle,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.note_hint,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => content = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(
                    color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (content.isNotEmpty) {
                await VaultService.addNote(title, content);
                _loadItems();
              }
            },
            child:
                Text(l10n.save, style: const TextStyle()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(VaultItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.delete,
            style: const TextStyle(color: Colors.white)),
        content: Text(l10n.deleteConfirm,
            style: const TextStyle(
                color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(
                    color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4444)),
            child: Text(l10n.delete,
                style: const TextStyle(
                    color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await VaultService.deleteItem(item);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, color: Color(0xFF39FF14), size: 20),
            const SizedBox(width: 8),
            Text(l10n.vault),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Color(0xFFFF4444)),
            onPressed: widget.onLock,
            tooltip: l10n.locked,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF39FF14),
          labelColor: const Color(0xFF39FF14),
          unselectedLabelColor: Colors.white38,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: l10n.photos),
            Tab(text: l10n.videos),
            Tab(text: l10n.files),
            Tab(text: l10n.notes),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF39FF14)))
          : _items.isEmpty
              ? _buildEmpty(l10n)
              : _buildGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add, size: 28),
      ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    final icons = [
      Icons.photo_outlined,
      Icons.videocam_outlined,
      Icons.folder_outlined,
      Icons.note_outlined,
    ];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icons[_tabController.index],
              color: const Color(0xFF39FF14).withOpacity(0.4), size: 72),
          const SizedBox(height: 16),
          Text(l10n.emptyVault,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  )),
          const SizedBox(height: 8),
          Text(l10n.addToVault,
              style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 13,
                  )),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildGrid() {
    final type = tabs[_tabController.index];
    if (type == 'note') return _buildNotesList();
    if (type == 'file') return _buildFilesList();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildMediaTile(item, index);
      },
    );
  }

  Widget _buildMediaTile(VaultItem item, int index) {
    return GestureDetector(
      onLongPress: () => _deleteItem(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<Uint8List?>(
              future: VaultService.getFileBytes(item.path),
              builder: (context, snap) {
                if (snap.data != null) {
                  return Image.memory(snap.data!, fit: BoxFit.cover);
                }
                return Container(
                  color: const Color(0xFF1A1A2E),
                  child: const Icon(Icons.image, color: Colors.white38),
                );
              },
            ),
            if (item.type == 'video')
              const Center(
                child: Icon(Icons.play_circle_fill,
                    color: Colors.white70, size: 32),
              ),
          ],
        ),
      ).animate(delay: (50 * index).ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF39FF14).withOpacity(0.1)),
          ),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file,
                color: Color(0xFF39FF14)),
            title: Text(item.name,
                style: const TextStyle(
                    color: Colors.white)),
            subtitle: Text(
              _formatSize(item.size),
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4444)),
              onPressed: () => _deleteItem(item),
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.2);
      },
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF39FF14).withOpacity(0.1)),
          ),
          child: ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined,
                color: Color(0xFFFFD700)),
            title: Text(item.name,
                style: const TextStyle(
                    color: Colors.white,
                    ,
                    fontWeight: FontWeight.bold)),
            subtitle: FutureBuilder<String>(
              future: VaultService.readNote(item.path),
              builder: (context, snap) => Text(
                snap.data ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white38,
                    ,
                    fontSize: 12),
              ),
            ),
            onTap: () => _viewNote(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4444)),
              onPressed: () => _deleteItem(item),
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.2);
      },
    );
  }

  Future<void> _viewNote(VaultItem item) async {
    final content = await VaultService.readNote(item.path);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sticky_note_2, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          color: Colors.white,
                          ,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(_),
                ),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(content,
                    style: const TextStyle(
                        color: Colors.white70,
                        ,
                        fontSize: 15,
                        height: 1.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
