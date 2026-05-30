import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VaultItem> _items = [];
  bool _loading = true;
  final tabs = ['photo', 'video', 'file', 'note'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) _loadItems(); });
    _loadItems();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await VaultService.getAllItems(type: tabs[_tabController.index]);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _addItem() async {
    switch (tabs[_tabController.index]) {
      case 'photo':
        final p = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (p != null) { await VaultService.addFile(File(p.path), 'photo'); _loadItems(); }
        break;
      case 'video':
        final p = await ImagePicker().pickVideo(source: ImageSource.gallery);
        if (p != null) { await VaultService.addFile(File(p.path), 'video'); _loadItems(); }
        break;
      case 'file':
        final r = await FilePicker.platform.pickFiles();
        if (r != null && r.files.first.path != null) { await VaultService.addFile(File(r.files.first.path!), 'file'); _loadItems(); }
        break;
      case 'note':
        await _addNote();
        break;
    }
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
        title: Text(l10n.addNote, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            decoration: InputDecoration(hintText: l10n.noteTitle, hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            onChanged: (v) => title = v,
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(hintText: l10n.note_hint, hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
            onChanged: (v) => content = v,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54, fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () async { Navigator.pop(ctx); if (content.isNotEmpty) { await VaultService.addNote(title, content); _loadItems(); } },
            child: Text(l10n.save, style: const TextStyle(fontFamily: 'Cairo')),
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
        title: Text(l10n.delete, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white)),
        content: Text(l10n.deleteConfirm, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: const TextStyle(color: Colors.white54, fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4444)),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (confirm == true) { await VaultService.deleteItem(item); _loadItems(); }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_open, color: Color(0xFF39FF14), size: 20),
          const SizedBox(width: 8),
          Text(l10n.vault),
        ]),
        actions: [IconButton(icon: const Icon(Icons.lock_outline, color: Color(0xFFFF4444)), onPressed: widget.onLock)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF39FF14),
          labelColor: const Color(0xFF39FF14),
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          tabs: [Tab(text: l10n.photos), Tab(text: l10n.videos), Tab(text: l10n.files), Tab(text: l10n.notes)],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
          : _items.isEmpty ? _buildEmpty() : _buildList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context)!;
    const icons = [Icons.photo_outlined, Icons.videocam_outlined, Icons.folder_outlined, Icons.note_outlined];
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icons[_tabController.index], color: const Color(0xFF39FF14).withOpacity(0.4), size: 72),
        const SizedBox(height: 16),
        Text(l10n.emptyVault, style: const TextStyle(color: Colors.white54, fontSize: 18, fontFamily: 'Cairo')),
        const SizedBox(height: 8),
        Text(l10n.addToVault, style: const TextStyle(color: Colors.white30, fontSize: 13, fontFamily: 'Cairo')),
      ]),
    );
  }

  Widget _buildList() {
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
            border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.1)),
          ),
          child: ListTile(
            leading: item.type == 'photo' || item.type == 'video'
                ? FutureBuilder<Uint8List?>(
                    future: VaultService.getFileBytes(item.path),
                    builder: (context, snap) => snap.data != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(snap.data!, width: 48, height: 48, fit: BoxFit.cover))
                        : const Icon(Icons.image, color: Color(0xFF39FF14)),
                  )
                : Icon(item.type == 'note' ? Icons.sticky_note_2_outlined : Icons.insert_drive_file, color: const Color(0xFF39FF14)),
            title: Text(item.name, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
            subtitle: Text(_formatSize(item.size), style: const TextStyle(color: Colors.white38, fontFamily: 'Cairo', fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFFF4444)),
              onPressed: () => _deleteItem(item),
            ),
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
