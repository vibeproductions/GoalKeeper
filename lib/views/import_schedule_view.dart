// lib/views/import_schedule_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/services/anthropic_service.dart';
import 'package:goalkeeper/theme/app_theme.dart';

class ImportScheduleView extends StatefulWidget {
  const ImportScheduleView({super.key});
  @override
  State<ImportScheduleView> createState() => _ImportScheduleViewState();
}

class _ImportScheduleViewState extends State<ImportScheduleView> {
  final _textCtrl = TextEditingController();
  File? _image;
  bool _parsing = false;
  String? _error;
  List<_EditableItem> _parsed = [];

  bool get _canParse => _textCtrl.text.trim().isNotEmpty || _image != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.sidebarBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SizedBox(
        width: 580,
        height: 620,
        child: Column(
          children: [
            _header,
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
                child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (_parsed.isEmpty) ...[
                  _inputSection,
                  const SizedBox(height: 14),
                  _parseBtn,
                ] else ...[
                  _reviewSection,
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: AppText.body(12, color: AppColors.danger)),
                ],
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget get _header => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Import Schedule',
                  style: AppText.display(18, weight: FontWeight.w700)),
              Text(
                  'Paste text or attach a photo — Claude will extract all assignments.',
                  style: AppText.body(12, color: AppColors.textSecondary)),
            ]),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.textTertiary),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget get _inputSection => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PASTE SCHEDULE TEXT', style: AppText.label(10)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: _textCtrl,
              style: AppText.body(12),
              maxLines: 7,
              decoration: const InputDecoration(
                hintText:
                    'e.g.\nMath – Chapter 5 – due Mon 3/3\nHistory – Essay – due Tue 3/4',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or',
                  style: AppText.body(11, color: AppColors.textTertiary)),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ]),
          const SizedBox(height: 16),
          Text('ATTACH PHOTO OF SCHEDULE', style: AppText.label(10)),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.personalGoal.withOpacity(0.1),
                foregroundColor: AppColors.personalGoal,
                elevation: 0,
              ),
              icon: Icon(
                  _image == null ? Icons.add_photo_alternate : Icons.photo,
                  size: 14),
              label: Text(_image == null ? 'Choose Image…' : 'Change Image…'),
              onPressed: _pickImage,
            ),
            if (_image != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_image!,
                    width: 50, height: 50, fit: BoxFit.cover),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 14, color: AppColors.textTertiary),
                onPressed: () => setState(() => _image = null),
              ),
            ],
          ]),
        ],
      );

  Widget get _parseBtn => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canParse && !_parsing ? _parse : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: _canParse
                ? const LinearGradient(
                    colors: [AppColors.personalGoal, AppColors.creative])
                : null,
            color: _canParse ? null : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_parsing) ...[
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Colors.black)),
                const SizedBox(width: 8),
                Text('Claude is reading your schedule…',
                    style: AppText.body(14,
                        weight: FontWeight.w600, color: Colors.black)),
              ] else ...[
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Colors.black),
                const SizedBox(width: 8),
                Text('Extract Assignments with Claude',
                    style: AppText.body(14,
                        weight: FontWeight.w600, color: Colors.black)),
              ],
            ],
          ),
        ),
      );

  Widget get _reviewSection {
    final toAdd = _parsed.where((i) => i.include).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 13, color: AppColors.accent),
          const SizedBox(width: 6),
          Text('Review Extracted Assignments',
              style: AppText.body(14,
                  weight: FontWeight.w700, color: AppColors.accent)),
          const Spacer(),
          Text('${_parsed.length} found',
              style: AppText.body(12, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 8),
        Text(
            'Review and edit before saving. Uncheck any you don\'t want to add.',
            style: AppText.body(12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ..._parsed.map((item) => _reviewRow(item)),
        const SizedBox(height: 14),
        Row(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _parsed = []),
            child: Text('Start Over',
                style: AppText.body(13, color: AppColors.textSecondary)),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: toAdd > 0 ? _save : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color:
                    toAdd > 0 ? AppColors.accent : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: Colors.black),
                const SizedBox(width: 6),
                Text('Add $toAdd Assignment${toAdd == 1 ? "" : "s"}',
                    style: AppText.body(13,
                        weight: FontWeight.w600, color: Colors.black)),
              ]),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _reviewRow(_EditableItem item) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Checkbox(
            value: item.include,
            onChanged: (v) => setState(() => item.include = v ?? true),
          ),
          Icon(item.type.icon, size: 13, color: item.type.color),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title,
                  style: AppText.body(12, weight: FontWeight.w500)),
              Text(
                  '${item.subject} · ${item.type.label} · '
                  '${item.dueDate.month}/${item.dueDate.day}/${item.dueDate.year}',
                  style: AppText.body(10, color: AppColors.textSecondary)),
            ],
          )),
        ]),
      );

  Future<void> _pickImage() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    if (r != null && r.files.single.path != null) {
      setState(() => _image = File(r.files.single.path!));
    }
  }

  Future<void> _parse() async {
    setState(() {
      _parsing = true;
      _error = null;
    });
    try {
      final results = await AnthropicService.parseSchedule(
          text: _textCtrl.text, image: _image);
      setState(() => _parsed = results
          .map((r) => _EditableItem(
                title: r.title,
                subject: r.subject,
                type: r.type,
                dueDate: r.dueDate,
                notes: r.notes,
              ))
          .toList());
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _parsing = false);
  }

  void _save() {
    final store = context.read<GoalStore>();
    final items = _parsed
        .where((i) => i.include)
        .map((i) => ScheduleItem(
            title: i.title,
            subject: i.subject,
            type: i.type,
            dueDate: i.dueDate,
            notes: i.notes))
        .toList();
    store.addScheduleItems(items);
    Navigator.pop(context);
  }
}

class _EditableItem {
  String title, subject, notes;
  ScheduleItemType type;
  DateTime dueDate;
  bool include = true;
  _EditableItem(
      {required this.title,
      required this.subject,
      required this.type,
      required this.dueDate,
      required this.notes});
}
