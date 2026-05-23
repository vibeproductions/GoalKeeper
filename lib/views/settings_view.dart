// lib/views/settings_view.dart
// Settings dialog — API key, model picker, display size, updates, release notes

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:goalkeeper_flutter/main.dart';
import 'package:goalkeeper_flutter/services/keychain_service.dart';
import 'package:goalkeeper_flutter/services/update_service.dart';
import 'package:goalkeeper_flutter/theme/app_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _keyCtrl    = TextEditingController();
  bool  _keyVisible = false;
  bool  _keySaved   = false;
  String _model     = 'claude-haiku-4-5';
  double _scale     = 1.0;
  bool  _showNotes  = false;

  final _updater = UpdateService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key   = await KeychainService.loadApiKey();
    final model = await KeychainService.selectedModel;
    final scale = await KeychainService.loadDisplayScale();
    if (mounted) {
      setState(() {
        _keyCtrl.text = key ?? '';
        _model = model;
        _scale = scale;
      });
    }
    await _updater.checkForUpdates();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.sidebarBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SizedBox(
        width: 480,
        height: _showNotes ? 680 : 640,
        child: Column(
          children: [
            _header,
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  _apiKeySection,
                  const _Divider(),
                  _modelSection,
                  const _Divider(),
                  _displaySection,
                  const _Divider(),
                  _updatesSection,
                  if (_showNotes) ...[
                    const _Divider(),
                    _ReleaseNotesSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget get _header => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
        child: Row(children: [
          Text('Settings', style: AppText.display(18, weight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
      );

  // ── API Key ────────────────────────────────────────────────────────────────
  Widget get _apiKeySection => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Anthropic API Key', Icons.key_rounded),
          const SizedBox(height: 12),
          Text(
            'GoalKeeper uses the Anthropic Claude API. Each user needs their own '
            'key from console.anthropic.com. New accounts get \$5 in free credits.',
            style: AppText.body(13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text('API KEY', style: AppText.label(10)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _keyVisible
                      ? TextField(
                          controller: _keyCtrl,
                          style: AppText.body(13),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'sk-ant-…',
                          ),
                        )
                      : TextField(
                          controller: _keyCtrl,
                          style: AppText.body(13),
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'sk-ant-…',
                          ),
                        ),
                ),
              ),
              IconButton(
                icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility,
                    size: 16, color: AppColors.textTertiary),
                onPressed: () => setState(() => _keyVisible = !_keyVisible),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            GestureDetector(
              onTap: () async {
                await KeychainService.saveApiKey(_keyCtrl.text);
                setState(() => _keySaved = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) setState(() => _keySaved = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _keySaved ? AppColors.success : AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(_keySaved ? Icons.check_circle_rounded : Icons.key_rounded,
                      size: 13, color: Colors.black),
                  const SizedBox(width: 6),
                  Text(_keySaved ? 'Saved!' : 'Save Key',
                      style: AppText.body(13, weight: FontWeight.w600, color: Colors.black)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await KeychainService.deleteApiKey();
                _keyCtrl.clear();
              },
              child: Text('Remove Key',
                  style: AppText.body(13, color: AppColors.danger)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://console.anthropic.com')),
              child: Text('Get a free key →',
                  style: AppText.body(12, color: AppColors.accent)),
            ),
          ]),
        ],
      );

  // ── Model picker ───────────────────────────────────────────────────────────
  Widget get _modelSection => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('AI Model', Icons.memory_rounded),
          const SizedBox(height: 12),
          Text('Choose the Claude model for analyzing your goals.',
              style: AppText.body(13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _modelOption('claude-haiku-4-5',  'Haiku',  'Fastest · Cheapest · Great for most goals',  'Recommended', AppColors.accent),
          const SizedBox(height: 6),
          _modelOption('claude-sonnet-4-6', 'Sonnet', 'Balanced speed and quality',                  '~5× more',    AppColors.warning),
          const SizedBox(height: 6),
          _modelOption('claude-opus-4-6',   'Opus',   'Most detailed · Best for complex goals',      '~25× more',   AppColors.danger),
        ],
      );

  Widget _modelOption(String id, String name, String desc, String badge, Color badgeColor) {
    final selected = _model == id;
    return GestureDetector(
      onTap: () async {
        await KeychainService.setSelectedModel(id);
        setState(() => _model = id);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.2),
                width: 2),
            ),
            child: selected
                ? Center(child: Container(width: 10, height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppText.body(13, weight: FontWeight.w600)),
            Text(desc, style: AppText.body(11, color: AppColors.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge,
                style: AppText.body(10, weight: FontWeight.w700, color: badgeColor)),
          ),
        ]),
      ),
    );
  }

  // ── Display Size ───────────────────────────────────────────────────────────
  Widget get _displaySection => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Display Size', Icons.text_fields_rounded),
          const SizedBox(height: 12),
          Text(
            'Adjust the size of all text and UI elements.',
            style: AppText.body(13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.text_fields_rounded, size: 13, color: AppColors.textTertiary),
            Expanded(
              child: Slider(
                value: _scale,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => _scale = v),
                onChangeEnd: (v) async {
                  await KeychainService.setDisplayScale(v);
                  appScale.value = v;
                },
              ),
            ),
            const Icon(Icons.text_fields_rounded, size: 20, color: AppColors.textTertiary),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Smaller', style: AppText.body(10, color: AppColors.textTertiary)),
              Text(
                '${(_scale * 100).toInt()}%',
                style: AppText.body(12, weight: FontWeight.w600, color: AppColors.accent),
              ),
              Text('Larger', style: AppText.body(10, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              await KeychainService.setDisplayScale(1.0);
              appScale.value = 1.0;
              setState(() => _scale = 1.0);
            },
            child: Text('Reset to default',
                style: AppText.body(12, color: AppColors.textSecondary)),
          ),
        ],
      );

  // ── Updates ────────────────────────────────────────────────────────────────
  Widget get _updatesSection => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Updates', Icons.update_rounded),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_rounded, size: 22, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('GoalKeeper', style: AppText.body(14, weight: FontWeight.w600)),
              Text('Version ${_updater.currentVersion}',
                  style: AppText.body(12, color: AppColors.textSecondary)),
            ]),
            const Spacer(),
            _updateBadge,
          ]),
          const SizedBox(height: 10),
          _updateAction,
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showNotes = !_showNotes),
            child: Row(children: [
              const Icon(Icons.description_rounded, size: 13, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                _showNotes ? 'Hide Release Notes' : 'View Release Notes',
                style: AppText.body(12, color: AppColors.accent),
              ),
            ]),
          ),
        ],
      );

  Widget get _updateBadge {
    switch (_updater.state.kind) {
      case UpdateStateKind.checking:
        return const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent));
      case UpdateStateKind.upToDate:
        return Row(children: [
          const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
          const SizedBox(width: 5),
          Text('Up to date', style: AppText.body(12, color: AppColors.success)),
        ]);
      case UpdateStateKind.available:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.personalGoal,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('v${_updater.state.manifest!.version} available',
              style: AppText.body(11, weight: FontWeight.w700, color: Colors.black)),
        );
      case UpdateStateKind.downloading:
        return SizedBox(width: 80,
            child: LinearProgressIndicator(
                value: _updater.state.downloadProgress, color: AppColors.accent));
      case UpdateStateKind.readyToInstall:
        return Row(children: [
          const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
          const SizedBox(width: 5),
          Text('Downloaded', style: AppText.body(12, color: AppColors.success)),
        ]);
      case UpdateStateKind.error:
        return const Icon(Icons.error_rounded, size: 13, color: AppColors.danger);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget get _updateAction {
    final state = _updater.state;
    switch (state.kind) {
      case UpdateStateKind.available:
        return GestureDetector(
          onTap: () async {
            await _updater.downloadUpdate(state.manifest!.url);
            if (mounted) setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.download_rounded, size: 13, color: Colors.black),
              const SizedBox(width: 6),
              Text('Download Update',
                  style: AppText.body(13, weight: FontWeight.w600, color: Colors.black)),
            ]),
          ),
        );
      case UpdateStateKind.readyToInstall:
        return GestureDetector(
          onTap: () => _updater.installUpdate(state.zipPath!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.install_mobile_rounded, size: 13, color: Colors.black),
              const SizedBox(width: 6),
              Text('Install & Quit',
                  style: AppText.body(13, weight: FontWeight.w600, color: Colors.black)),
            ]),
          ),
        );
      case UpdateStateKind.upToDate:
        return GestureDetector(
          onTap: () async {
            await _updater.checkForUpdates();
            if (mounted) setState(() {});
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.refresh_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text('Check Again',
                style: AppText.body(12, color: AppColors.textSecondary)),
          ]),
        );
      case UpdateStateKind.error:
        return Text(state.errorMessage ?? 'Unknown error',
            style: AppText.body(12, color: AppColors.danger));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
        Icon(icon, size: 15, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Text(title, style: AppText.display(15, weight: FontWeight.w700)),
      ]);
}

// ── Release Notes ─────────────────────────────────────────────────────────────

class _ReleaseNotesSection extends StatefulWidget {
  const _ReleaseNotesSection();
  @override
  State<_ReleaseNotesSection> createState() => _ReleaseNotesSectionState();
}

class _ReleaseNotesSectionState extends State<_ReleaseNotesSection> {
  List<dynamic> _releases = [];
  bool _loading = true;
  int? _expandedId;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await http.get(
        Uri.parse('https://api.github.com/repos/TECWiSaRd/GoalKeeper/releases'),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (r.statusCode == 200) {
        final releases = jsonDecode(r.body) as List;
        setState(() {
          _releases = releases;
          if (releases.isNotEmpty) _expandedId = releases.first['id'] as int;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.description_rounded, size: 15),
          const SizedBox(width: 8),
          Text('Release Notes', style: AppText.display(15, weight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.accent))
        else if (_releases.isEmpty)
          Text('Could not load releases.',
              style: AppText.body(12, color: AppColors.textSecondary))
        else
          ..._releases.map((r) {
            final id       = r['id'] as int;
            final tag      = r['tag_name'] as String;
            final name     = (r['name'] as String?) ?? tag;
            final body     = (r['body'] as String?) ?? '';
            final url      = r['html_url'] as String;
            final expanded = _expandedId == id;

            return GestureDetector(
              onTap: () => setState(() => _expandedId = expanded ? null : id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(tag,
                            style: AppText.body(12,
                                weight: FontWeight.w700, color: AppColors.accent)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(name,
                          style: AppText.body(13, weight: FontWeight.w600))),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more,
                          size: 14, color: AppColors.textTertiary),
                    ]),
                  ),
                  if (expanded && body.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...body.split('\n').map((line) {
                            line = line.trim();
                            if (line.isEmpty) return const SizedBox(height: 4);
                            if (line.startsWith('- ') || line.startsWith('* ')) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4, height: 4,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(line.substring(2),
                                        style: AppText.body(12,
                                            color: AppColors.textSecondary))),
                                  ],
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(line,
                                  style: AppText.body(12,
                                      color: AppColors.textSecondary)),
                            );
                          }),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse(url)),
                            child: Text('View on GitHub →',
                                style: AppText.body(11, color: AppColors.accent)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            );
          }),
      ],
    );
  }
}

// ── Divider helper ────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Divider(height: 1, color: AppColors.divider),
      );
}
