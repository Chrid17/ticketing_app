import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ticketing_app/controllers/settings_controller.dart';
import 'package:ticketing_app/controllers/ticket_controller.dart';
import 'package:ticketing_app/utils/notify.dart';
import 'package:ticketing_app/widgets/badges.dart';
import 'package:ticketing_app/widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final settings = Get.find<SettingsController>();
  final tickets = Get.find<TicketController>();
  late final _name = TextEditingController(text: settings.agentName.value);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _saveName() {
    final v = _name.text.trim();
    if (v.isEmpty) {
      notify('Name cannot be empty', error: true);
      return;
    }
    settings.setAgentName(v);
    FocusScope.of(context).unfocus();
    notify('Profile updated');
  }

  Future<void> _export() async {
    if (tickets.tickets.isEmpty) {
      notify('There are no tickets to export', error: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: tickets.exportJson()));
    notify('${tickets.tickets.length} tickets copied to clipboard as JSON');
  }

  Future<void> _import() async {
    final input = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import tickets'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste a TicketDesk JSON export below. Tickets with the same id will be replaced.'),
              const SizedBox(height: 12),
              TextField(
                controller: input,
                minLines: 6,
                maxLines: 10,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(hintText: '{ "tickets": [ … ] }'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) input.text = data!.text!;
                },
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: const Text('Paste from clipboard'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(input.text), child: const Text('Import')),
        ],
      ),
    );
    input.dispose();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final count = tickets.importJson(raw.trim());
      notify('Imported $count ticket${count == 1 ? '' : 's'}');
    } catch (_) {
      notify('That doesn\'t look like a valid TicketDesk export', error: true);
    }
  }

  Future<void> _clearAll() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete all tickets?',
      message: 'This permanently removes every ticket, conversation and history entry stored on this device. '
          'Export first if you want a backup.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (ok) await tickets.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            PageBody(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Settings', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Personalise TicketDesk and manage your data.', style: muted),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Your profile',
                    subtitle: 'Your name appears on replies, assignments and the activity log',
                    child: Row(
                      children: [
                        Obx(() => PersonAvatar(settings.agentName.value, size: 44)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Display name'),
                            onSubmitted: (_) => _saveName(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(onPressed: _saveName, child: const Text('Save')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Appearance',
                    subtitle: 'Choose how TicketDesk looks on this device',
                    child: Obx(() => SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
                            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                          ],
                          selected: {settings.themeMode.value},
                          onSelectionChanged: (s) => settings.setThemeMode(s.first),
                        )),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Data',
                    subtitle: 'Tickets are saved locally on this device and work offline',
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Obx(() => Column(
                          children: [
                            _ActionTile(
                              icon: Icons.inventory_2_outlined,
                              title: 'Stored tickets',
                              subtitle: '${tickets.tickets.length} ticket${tickets.tickets.length == 1 ? '' : 's'} · '
                                  '${tickets.activeCount} active',
                            ),
                            const Divider(),
                            _ActionTile(
                              icon: Icons.auto_awesome_outlined,
                              title: 'Load demo tickets',
                              subtitle: 'Add 10 sample tickets to explore the app',
                              onTap: tickets.loadDemoData,
                            ),
                            const Divider(),
                            _ActionTile(
                              icon: Icons.upload_outlined,
                              title: 'Export tickets',
                              subtitle: 'Copy all tickets to the clipboard as JSON (backup)',
                              onTap: _export,
                            ),
                            const Divider(),
                            _ActionTile(
                              icon: Icons.download_outlined,
                              title: 'Import tickets',
                              subtitle: 'Restore from a TicketDesk JSON export',
                              onTap: _import,
                            ),
                            const Divider(),
                            _ActionTile(
                              icon: Icons.delete_forever_outlined,
                              title: 'Delete all tickets',
                              subtitle: 'Permanently remove everything stored on this device',
                              destructive: true,
                              onTap: tickets.tickets.isEmpty ? null : _clearAll,
                            ),
                          ],
                        )),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'About',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TicketDesk 2.0.0', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'A client support ticketing app built with Flutter and GetX. Works offline on Android, iOS, web and desktop.',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, this.onTap, this.destructive = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: destructive ? scheme.error : scheme.onSurfaceVariant),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
