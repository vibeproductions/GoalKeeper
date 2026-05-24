// lib/views/add_goal_view.dart
// New goal dialog — form + Claude AI analysis

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/services/anthropic_service.dart';
import 'package:goalkeeper/theme/app_theme.dart';

class AddGoalView extends StatefulWidget {
  const AddGoalView({super.key});
  @override
  State<AddGoalView> createState() => _AddGoalViewState();
}

class _AddGoalViewState extends State<AddGoalView> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _rubricCtrl = TextEditingController();

  GoalType     _type     = GoalType.assignment;
  GoalPriority _priority = GoalPriority.medium;
  bool         _hasDue   = false;
  DateTime     _dueDate  = DateTime.now().add(const Duration(days: 7));
  bool         _showRubric = false;
  File?        _image;
  bool         _analyzing = false;
  String?      _error;
  GoalAnalysis? _result;

  bool get _valid => _titleCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.sidebarBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SizedBox(
        width: 560,
        height: 680,
        child: Column(
          children: [
            _header,
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _typePicker,
                  const SizedBox(height: 14),
                  _formCard,
                  const SizedBox(height: 14),
                  _analyzeBtn,
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: AppText.body(12, color: AppColors.danger)),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: 14),
                    _previewCard(_result!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _header => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
        child: Row(
          children: [
            Text('New Goal', style: AppText.display(18, weight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget get _typePicker => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: GoalType.values.map((t) {
            final selected = _type == t;
            return GestureDetector(
              onTap: () => setState(() => _type = t),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? t.color : t.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(t.icon, size: 13,
                        color: selected ? Colors.black : t.color.withOpacity(0.8)),
                    const SizedBox(width: 5),
                    Text(t.label,
                        style: AppText.body(12,
                            weight: FontWeight.w500,
                            color: selected ? Colors.black : t.color.withOpacity(0.8))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget get _formCard => Container(
        decoration: cardDecoration(),
        child: Column(
          children: [
            _field('Title', child: TextField(
              controller: _titleCtrl,
              style: AppText.body(14),
              decoration: const InputDecoration(
                hintText: 'e.g. Research Paper on Climate Change',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            )),
            const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
            _field('Description', child: TextField(
              controller: _descCtrl,
              style: AppText.body(13),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the goal or what success looks like…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            )),
            const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
            _field('Priority', child: Row(
              children: GoalPriority.values.map((p) {
                final sel = _priority == p;
                return GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? p.color : p.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(p.label,
                        style: AppText.body(11,
                            weight: FontWeight.w600,
                            color: sel ? Colors.black : p.color)),
                  ),
                );
              }).toList(),
            )),
            const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
            _field('Due Date', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Switch(value: _hasDue, onChanged: (v) => setState(() => _hasDue = v)),
                    const SizedBox(width: 8),
                    Text('Set a due date', style: AppText.body(13, color: AppColors.textSecondary)),
                  ],
                ),
                if (_hasDue)
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 1000)),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: Text(
                      '${_dueDate.month}/${_dueDate.day}/${_dueDate.year}',
                      style: AppText.body(13, color: AppColors.accent),
                    ),
                  ),
              ],
            )),
            const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
            _field('Rubric / Requirements', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showRubric = !_showRubric),
                  child: Row(
                    children: [
                      Text(_showRubric ? 'Hide rubric' : 'Add rubric or grading criteria',
                          style: AppText.body(13, color: AppColors.accent)),
                      const Spacer(),
                      Icon(_showRubric ? Icons.expand_less : Icons.expand_more,
                          size: 16, color: AppColors.accent),
                    ],
                  ),
                ),
                if (_showRubric)
                  TextField(
                    controller: _rubricCtrl,
                    style: AppText.body(12),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Paste rubric, criteria, or requirements…',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(top: 8),
                    ),
                  ),
              ],
            )),
            const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
            _field('Attach Image', child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                    foregroundColor: AppColors.accent,
                    elevation: 0,
                  ),
                  icon: Icon(_image == null ? Icons.add_photo_alternate : Icons.photo,
                      size: 14),
                  label: Text(_image == null ? 'Choose Image…' : 'Change Image…'),
                  onPressed: _pickImage,
                ),
                if (_image != null) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_image!, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, color: AppColors.textTertiary),
                    onPressed: () => setState(() => _image = null),
                  ),
                ],
              ],
            )),
          ],
        ),
      );

  Widget _field(String label, {required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppText.label(9)),
            const SizedBox(height: 5),
            child,
          ],
        ),
      );

  Widget get _analyzeBtn {
    return GestureDetector(
      onTap: _valid && !_analyzing ? _analyze : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: _valid
              ? const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentGreen])
              : null,
          color: _valid ? null : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_analyzing) ...[
              const SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Colors.black)),
              const SizedBox(width: 8),
              Text('Claude is analyzing…',
                  style: AppText.body(14, weight: FontWeight.w600, color: Colors.black)),
            ] else ...[
              const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.black),
              const SizedBox(width: 8),
              Text('Analyze with Claude AI',
                  style: AppText.body(14, weight: FontWeight.w600, color: Colors.black)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewCard(GoalAnalysis result) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('AI Plan Preview',
                    style: AppText.body(13,
                        weight: FontWeight.w700, color: AppColors.accent)),
                const Spacer(),
                Text('${result.steps.length} steps',
                    style: AppText.body(11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.summary,
                style: AppText.body(12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            ...result.steps.asMap().entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _type.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: AppText.body(10,
                                  weight: FontWeight.w700, color: _type.color)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(e.value.title,
                                      style: AppText.body(12,
                                          weight: FontWeight.w600)),
                                ),
                                Text(e.value.estimatedTime,
                                    style: AppText.body(10,
                                        color: AppColors.textTertiary)),
                              ],
                            ),
                            Text(e.value.detail,
                                style: AppText.body(11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: Colors.black),
                    const SizedBox(width: 6),
                    Text('Save Goal & Start Tracking',
                        style: AppText.body(14,
                            weight: FontWeight.w600, color: Colors.black)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _image = File(result.files.single.path!));
    }
  }

  Future<void> _analyze() async {
    setState(() { _analyzing = true; _error = null; _result = null; });
    try {
      final r = await AnthropicService.analyzeGoal(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        type: _type,
        dueDate: _hasDue ? _dueDate : null,
        rubric: _rubricCtrl.text,
        image: _image,
      );
      setState(() => _result = r);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _analyzing = false);
  }

  void _save() {
    if (_result == null) return;
    final store = context.read<GoalStore>();
    final goal = Goal(
      title: _titleCtrl.text,
      description: _descCtrl.text,
      type: _type,
      priority: _priority,
      dueDate: _hasDue ? _dueDate : null,
      rubricText: _rubricCtrl.text,
      isAnalyzed: true,
      aiSummary: _result!.summary,
      steps: _result!.steps.map((s) => GoalStep(
        title: s.title, detail: s.detail,
        estimatedTime: s.estimatedTime, tips: s.tips,
      )).toList(),
    );
    store.addGoal(goal);
    Navigator.pop(context);
  }
}
