import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/ml/text_recognition_service.dart';
import '../../services/ml/barcode_ml_service.dart';
import '../../services/ml_history_service.dart';

class MlHistoryScreen extends StatefulWidget {
  const MlHistoryScreen({super.key});

  @override
  State<MlHistoryScreen> createState() => _MlHistoryScreenState();
}

class _MlHistoryScreenState extends State<MlHistoryScreen> {
  List<MlHistoryEntry> _entries = [];
  bool _loading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await MlHistoryService.load();
    if (mounted) setState(() => _entries = list);
  }

  // ── OCR ────────────────────────────────────────────────────────────────────
  Future<void> _runOcr() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    setState(() => _loading = true);
    try {
      final result = await TextRecognitionService.extractText(xfile.path);
      final text = result.isEmpty ? '(no text found)' : result;
      await MlHistoryService.save(MlHistoryEntry(
        type: 'OCR',
        input: xfile.name,
        result: text,
        timestamp: DateTime.now(),
      ));
      await _loadHistory();
      if (mounted) _showResultSheet('OCR Result', text);
    } catch (e) {
      if (mounted) _showError('OCR failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── QR / Barcode ───────────────────────────────────────────────────────────
  Future<void> _runBarcode() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    setState(() => _loading = true);
    try {
      final results = await BarcodeMlService.scanFromFile(xfile.path);
      final text = results.isEmpty ? '(no barcode found)' : results.join('\n');
      await MlHistoryService.save(MlHistoryEntry(
        type: 'QR/Barcode',
        input: xfile.name,
        result: text,
        timestamp: DateTime.now(),
      ));
      await _loadHistory();
      if (mounted) _showResultSheet('Barcode Result', text);
    } catch (e) {
      if (mounted) _showError('Scan failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Delete one entry ───────────────────────────────────────────────────────
  Future<void> _deleteEntry(MlHistoryEntry entry) async {
    final all = await MlHistoryService.load();
    all.removeWhere(
        (e) => e.timestamp == entry.timestamp && e.type == entry.type);
    // Rewrite: clear key then re-save remaining
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ml_history');
    for (final e in all.reversed) {
      await MlHistoryService.save(e);
    }
    await _loadHistory();
  }

  // ── Clear all ──────────────────────────────────────────────────────────────
  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ml_history');
    setState(() => _entries = []);
  }

  // ── Result bottom sheet ────────────────────────────────────────────────────
  void _showResultSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.sora(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  controller: ctrl,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      content,
                      style: GoogleFonts.sora(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.sora(color: Colors.white)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          s.t('ml_history'),
          style: GoogleFonts.sora(
            color: AppColors.primary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text('Clear all',
                  style: GoogleFonts.sora(
                      color: AppColors.error, fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Action buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.text_fields_rounded,
                    label: 'Scan Text\n(OCR)',
                    color: AppColors.primary,
                    loading: _loading,
                    onTap: _runOcr,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR /\nBarcode',
                    color: AppColors.accent,
                    loading: _loading,
                    onTap: _runBarcode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── History list ─────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded,
                                color: AppColors.textSecondary
                                    .withOpacity(0.4),
                                size: 56),
                            const SizedBox(height: 12),
                            Text('No ML scans yet',
                                style: GoogleFonts.sora(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                            const SizedBox(height: 6),
                            Text('Use the buttons above to scan',
                                style: GoogleFonts.sora(
                                    color: AppColors.textSecondary
                                        .withOpacity(0.6),
                                    fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: _entries.length,
                        itemBuilder: (ctx, i) => _HistoryCard(
                          entry: _entries[i],
                          onTap: () => _showResultSheet(
                            '${_entries[i].type} Result',
                            _entries[i].result,
                          ),
                          onDelete: () => _deleteEntry(_entries[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History card ──────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final MlHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  Color _typeColor(String type) => switch (type) {
        'OCR' => AppColors.primary,
        'QR/Barcode' => AppColors.accent,
        _ => AppColors.textSecondary,
      };

  IconData _typeIcon(String type) => switch (type) {
        'OCR' => Icons.text_fields_rounded,
        'QR/Barcode' => Icons.qr_code_rounded,
        _ => Icons.smart_toy_outlined,
      };

  String _formatDate(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(entry.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(_typeIcon(entry.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(entry.type,
                            style: GoogleFonts.sora(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      const Spacer(),
                      Text(_formatDate(entry.timestamp),
                          style: GoogleFonts.sora(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(entry.input,
                      style: GoogleFonts.sora(
                          color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(entry.result,
                      style: GoogleFonts.sora(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
