import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/collaboration_provider.dart';

final _demoFiles = [
  _DemoFile('Project_Guidelines.pdf', '2.4 MB', 'Oct 12, 2023', _FType.pdf),
  _DemoFile('Feature_List_V2.docx', '850 KB', 'Oct 10, 2023', _FType.doc),
  _DemoFile('Assets_Bundle_Dark.zip', '45.2 MB', 'Oct 08, 2023', _FType.zip),
  _DemoFile('Q4_Budget_Planning.xlsx', '1.2 MB', 'Oct 05, 2023', _FType.xls),
  _DemoFile('Pitch_Deck_Final.pptx', '8.7 MB', 'Oct 03, 2023', _FType.ppt),
];

const _demoPhotoCount = 6;
const _extraPhotos = 12;

enum _FType { pdf, doc, zip, xls, ppt, img, other }

class _DemoFile {
  final String name, size, date;
  final _FType type;
  _DemoFile(this.name, this.size, this.date, this.type);
}

class FilesTab extends StatelessWidget {
  final ProjectModel project;
  const FilesTab({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsProvider>();
    final collab = context.watch<CollaborationProvider>();
    final realFiles = collab.filesForProject(project.id);

    final imageFiles = realFiles
        .where((f) => _isImage(f.name))
        .toList();
    final otherFiles = realFiles
        .where((f) => !_isImage(f.name))
        .toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // ── PHOTOS ──────────────────────────────────────────────
            _SectionLabel('PHOTOS'),
            const SizedBox(height: 12),
            imageFiles.isEmpty
                ? _DemoPhotoGrid()
                : _RealPhotoGrid(files: imageFiles),
            const SizedBox(height: 24),

            // ── FILES ────────────────────────────────────────────────
            _SectionLabel('FILES'),
            const SizedBox(height: 12),
            if (otherFiles.isEmpty)
              ..._demoFiles.map((f) => _FileRow(
                    name: f.name,
                    meta: '${f.size} • ${f.date}',
                    type: f.type,
                  ))
            else
              ...otherFiles.map((f) => _FileRow(
                    name: f.name,
                    meta: _fmtDate(f.uploadedAt),
                    type: _typeOf(f.name),
                    realPath: f.path,
                  )),
          ],
        ),

        // ── Upload FAB ───────────────────────────────────────────────
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'upload_files',
            onPressed: () => _pickAndUpload(context, project),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              s.t('upload_file'),
              style: GoogleFonts.sora(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  static bool _isImage(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ext == 'jpg' || ext == 'jpeg' || ext == 'png';
  }

  static Future<void> _pickAndUpload(
      BuildContext context, ProjectModel project) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    if (!context.mounted) return;
    context.read<CollaborationProvider>().addFile(FileModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          projectId: project.id,
          name: file.name,
          path: file.path!,
          uploadedAt: DateTime.now(),
        ));
  }

  static String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static _FType _typeOf(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => _FType.pdf,
      'doc' || 'docx' => _FType.doc,
      'zip' || 'rar' => _FType.zip,
      'xls' || 'xlsx' => _FType.xls,
      'ppt' || 'pptx' => _FType.ppt,
      'jpg' || 'jpeg' || 'png' => _FType.img,
      _ => _FType.other,
    };
  }
}

// ── Demo photo grid ───────────────────────────────────────────────────────────
class _DemoPhotoGrid extends StatelessWidget {
  static const _colors = [
    Color(0xFF2A3550), Color(0xFF1E2D40), Color(0xFF0D1117),
    Color(0xFF1A2035), Color(0xFF252D40), Color(0xFF0D1117),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: _demoPhotoCount,
      itemBuilder: (ctx, i) {
        final isLast = i == _demoPhotoCount - 1;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Stack(fit: StackFit.expand, children: [
            Container(color: _colors[i % _colors.length]),
            if (isLast)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Text('+$_extraPhotos',
                      style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ── Real photo grid ───────────────────────────────────────────────────────────
class _RealPhotoGrid extends StatelessWidget {
  final List<FileModel> files;
  const _RealPhotoGrid({required this.files});

  @override
  Widget build(BuildContext context) {
    final show = files.length > 6 ? 6 : files.length;
    final extra = files.length - 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
      ),
      itemCount: show,
      itemBuilder: (ctx, i) {
        final isLast = i == show - 1 && extra > 0;
        return GestureDetector(
          onTap: () => _openFullscreen(context, files[i].path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Stack(fit: StackFit.expand, children: [
              Image.file(File(files[i].path), fit: BoxFit.cover),
              if (isLast)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text('+$extra',
                        style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }

  void _openFullscreen(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── File row ──────────────────────────────────────────────────────────────────
class _FileRow extends StatelessWidget {
  final String name, meta;
  final _FType type;
  final String? realPath;

  const _FileRow({
    required this.name, required this.meta, required this.type, this.realPath,
  });

  ({Color bg, Color fg, IconData icon}) get _props => switch (type) {
    _FType.pdf  => (bg: const Color(0xFFFF4D4D), fg: const Color(0xFFFF4D4D), icon: Icons.picture_as_pdf_rounded),
    _FType.doc  => (bg: AppColors.primary,       fg: AppColors.primary,       icon: Icons.description_rounded),
    _FType.zip  => (bg: AppColors.accent,        fg: AppColors.accent,        icon: Icons.folder_zip_rounded),
    _FType.xls  => (bg: AppColors.inProgressOrange, fg: AppColors.inProgressOrange, icon: Icons.table_chart_rounded),
    _FType.ppt  => (bg: const Color(0xFFFF6B35), fg: const Color(0xFFFF6B35), icon: Icons.slideshow_rounded),
    _FType.img  => (bg: AppColors.success,       fg: AppColors.success,       icon: Icons.image_rounded),
    _FType.other=> (bg: AppColors.textSecondary, fg: AppColors.textSecondary, icon: Icons.insert_drive_file_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final p = _props;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: p.bg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(p.icon, color: p.fg, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.sora(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(meta,
                    style: GoogleFonts.sora(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Download / open
          GestureDetector(
            onTap: () {
              // ⚠️ open_file package needed for real open; showing snackbar in demo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading $name...',
                      style: GoogleFonts.sora(color: Colors.white)),
                  backgroundColor: AppColors.surface,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(Icons.download_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.sora(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      );
}
