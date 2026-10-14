import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'models/result_item.dart';
import 'services/formatter_service.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FormatAnythingApp());

const brand = Color(0xFF1769FF);
const ink = Color(0xFF0A1D49);
const muted = Color(0xFF71809B);
const pale = Color(0xFFF3F7FF);

class FormatAnythingApp extends StatelessWidget {
  const FormatAnythingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Format Anything', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF8FAFF),
      colorScheme: ColorScheme.fromSeed(seedColor: brand, primary: brand, surface: Colors.white),
      textTheme: const TextTheme(titleLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: ink), bodyMedium: TextStyle(color: ink)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF8FAFF), foregroundColor: ink, elevation: 0, centerTitle: false),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE8EEF9)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFFF7F9FD), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16))),
    home: const AppShell(),
  );
}

class AppShell extends StatefulWidget { const AppShell({super.key}); @override State<AppShell> createState() => _AppShellState(); }
class _AppShellState extends State<AppShell> {
  int tab = 0; String input = ''; String output = ''; String selectedType = 'Plain Text'; bool busy = false;
  final List<ResultItem> history = []; final picker = ImagePicker();
  @override void initState() { super.initState(); _loadHistory(); }
  Future<void> _loadHistory() async { final p = await SharedPreferences.getInstance(); final rows = p.getStringList('history') ?? []; if (!mounted) return; setState(() { history.addAll(rows.map((e) => ResultItem.fromJson(jsonDecode(e)))); }); }
  Future<void> _saveHistory(ResultItem item) async { history.insert(0, item); if (history.length > 100) history.removeLast(); final p = await SharedPreferences.getInstance(); await p.setStringList('history', history.map((e) => jsonEncode(e.toJson())).toList()); if (mounted) setState(() {}); }
  Future<void> _openEditor({String? text, String? type}) async { final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => EditorPage(initial: text ?? input))); if (result != null) { setState(() { input = result; selectedType = type ?? selectedType; }); _process(); } }
  Future<void> _process() async { if (input.trim().isEmpty) { _openEditor(); return; } setState(() => busy = true); await Future<void>.delayed(const Duration(milliseconds: 180)); final formatted = Formatter.format(input, selectedType); setState(() { output = formatted; busy = false; }); await _saveHistory(ResultItem(title: _titleFor(input), kind: selectedType, content: formatted)); if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(title: _titleFor(input), kind: selectedType, content: formatted, onEdit: () => _openEditor(text: input, type: selectedType)))); }
  String _titleFor(String s) { final line = s.trim().split('\n').first.trim(); return line.length > 28 ? '${line.substring(0, 28)}…' : line.isEmpty ? 'Formatted result' : line; }
  Future<void> _pickImage() async { final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92); if (x == null) return; await _ocr(File(x.path)); }
  Future<void> _scanReceipt() async { final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 92); if (x == null) return; await _ocr(File(x.path)); }
  Future<void> _ocr(File file) async { setState(() => busy = true); try { final recognizer = TextRecognizer(script: TextRecognitionScript.latin); final result = await recognizer.processImage(InputImage.fromFile(file)); await recognizer.close(); setState(() { input = result.text; selectedType = 'Receipt JSON'; busy = false; }); if (input.trim().isEmpty) throw Exception('No readable text was detected. Try a clearer photo.'); _process(); } catch (e) { setState(() => busy = false); if (mounted) _message('Could not read this image: $e'); } }
  Future<void> _pickFile() async { final f = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['txt','json','csv','md','html','log']); if (f == null || f.files.single.path == null) return; try { input = await File(f.files.single.path!).readAsString(); selectedType = 'Plain Text'; _process(); } catch (_) { _message('This file could not be opened as text.'); } }
  void _message(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override Widget build(BuildContext context) { final pages = [HomePage(onFormat: (t) { setState(() => selectedType = t); _openEditor(type: t); }, onScan: _scanReceipt, onImage: _pickImage, onFile: _pickFile, onHistory: () => setState(() => tab = 1), busy: busy, history: history), HistoryPage(items: history, onOpen: (r) => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(title: r.title, kind: r.kind, content: r.content, onEdit: () => _openEditor(text: r.content, type: r.kind)))), onDelete: (r) async { history.remove(r); final p = await SharedPreferences.getInstance(); await p.setStringList('history', history.map((e) => jsonEncode(e.toJson())).toList()); setState(() {}); }), const SettingsPage()]; return Scaffold(body: SafeArea(child: IndexedStack(index: tab, children: pages)), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'), NavigationDestination(icon: Icon(Icons.history_rounded), label: 'History'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings')])); }
}

class HomePage extends StatelessWidget {
 const HomePage({super.key, required this.onFormat, required this.onScan, required this.onImage, required this.onFile, required this.onHistory, required this.busy, required this.history});
 final ValueChanged<String> onFormat; final VoidCallback onScan, onImage, onFile, onHistory; final bool busy; final List<ResultItem> history;
 @override Widget build(BuildContext context) => CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), sliver: SliverList(delegate: SliverChildListDelegate([
  Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF348BFF), brand]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.article_rounded, color: Colors.white, size: 28)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Format Anything', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: ink)), Text('Clean input. Perfect output.', style: TextStyle(color: muted, fontSize: 12))])), IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: const Icon(Icons.tune_rounded, color: ink))]), const SizedBox(height: 20),
  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1769FF), Color(0xFF0746C8)]), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Share from any app', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 6), const Text('Text, links, code, tables or receipts — formatted in seconds.', style: TextStyle(color: Color(0xFFDCE8FF), height: 1.4)), const SizedBox(height: 18), Wrap(spacing: 8, runSpacing: 8, children: [ _heroAction(Icons.edit_note, 'Paste text', () => onFormat('Plain Text'), light: true), _heroAction(Icons.document_scanner_outlined, 'Scan receipt', onScan, light: true), _heroAction(Icons.photo_outlined, 'From photo', onImage, light: true)])])), const SizedBox(height: 24),
  const SectionTitle('Quick Actions', trailing: 'Choose a format'), const SizedBox(height: 12), GridView.count(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.72, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [ActionTile(icon: Icons.text_fields_rounded, color: const Color(0xFFFFA54C), title: 'Format Text', subtitle: 'Clean and polish', onTap: () => onFormat('Plain Text')), ActionTile(icon: Icons.data_object_rounded, color: const Color(0xFF9B7BFF), title: 'Format Code', subtitle: 'JSON & snippets', onTap: () => onFormat('JSON')), ActionTile(icon: Icons.table_chart_rounded, color: const Color(0xFF39B98A), title: 'Text to CSV', subtitle: 'Rows and columns', onTap: () => onFormat('CSV')), ActionTile(icon: Icons.link_rounded, color: const Color(0xFF3E8BFF), title: 'Clean Link', subtitle: 'Remove tracking', onTap: () => onFormat('Clean URL'))]), const SizedBox(height: 24),
  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const SectionTitle('Works with everything'), TextButton(onPressed: onFile, child: const Text('Open file'))]), const SizedBox(height: 10), const FeatureRow(icon: Icons.chat_bubble_outline, color: Color(0xFF65B8FF), title: 'Text & Messages', subtitle: 'Clean and format text.'), const FeatureRow(icon: Icons.code_rounded, color: Color(0xFF9B8AFF), title: 'Code & Data', subtitle: 'Format JSON, SQL, HTML and more.'), const FeatureRow(icon: Icons.table_chart_outlined, color: Color(0xFF55C89D), title: 'Tables & CSV', subtitle: 'Convert unstructured data.'), const FeatureRow(icon: Icons.receipt_long_outlined, color: Color(0xFFFFB36A), title: 'Receipts & Screenshots', subtitle: 'Extract data with on-device OCR.'), const FeatureRow(icon: Icons.link_rounded, color: Color(0xFF5F9FFF), title: 'Links & URLs', subtitle: 'Clean and validate links.'), const SizedBox(height: 22), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const SectionTitle('Recent Results'), TextButton(onPressed: onHistory, child: const Text('See all'))]), const SizedBox(height: 8), if (history.isEmpty) const EmptyState(icon: Icons.history, title: 'Your results will appear here', subtitle: 'Format something to start your history.') else ...history.take(3).map((r) => RecentRow(item: r, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(title: r.title, kind: r.kind, content: r.content, onEdit: () {}))))), const SizedBox(height: 12), if (busy) const LinearProgressIndicator(),
 ])))]);
 Widget _heroAction(IconData icon, String text, VoidCallback onTap, {bool light = false}) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10), decoration: BoxDecoration(color: light ? Colors.white.withValues(alpha: .16) : pale, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: .24))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 17, color: Colors.white), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))])));
}

class EditorPage extends StatefulWidget { const EditorPage({super.key, required this.initial}); final String initial; @override State<EditorPage> createState() => _EditorPageState(); }
class _EditorPageState extends State<EditorPage> { late final TextEditingController c = TextEditingController(text: widget.initial); @override void dispose() { c.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Preview Input'), leading: const BackButton()), body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(Icons.info_outline, color: brand), SizedBox(width: 10), Expanded(child: Text('Paste or edit your content. Processing runs locally when possible.', style: TextStyle(fontSize: 12)))])), const SizedBox(height: 16), Expanded(child: TextField(controller: c, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top, decoration: const InputDecoration(hintText: 'Paste text, JSON, a URL or tabular data…'))), const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(context, c.text), icon: const Icon(Icons.auto_awesome), label: const Padding(padding: EdgeInsets.all(13), child: Text('Continue'))))]))); }

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.title,
    required this.kind,
    required this.content,
    required this.onEdit,
  });

  final String title;
  final String kind;
  final String content;
  final VoidCallback onEdit;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formatted Result'),
        actions: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(kind),
                  avatar: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 17,
                  ),
                ),
                const Chip(
                  label: Text('Processed locally'),
                  avatar: Icon(Icons.phone_android, size: 17),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6ECF7)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: TextStyle(
                      fontFamily: kind.contains('JSON') ? 'monospace' : null,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Share.share(content, subject: title),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.save_alt),
                label: const Text('Copy result for saving'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget { const HistoryPage({super.key, required this.items, required this.onOpen, required this.onDelete}); final List<ResultItem> items; final ValueChanged<ResultItem> onOpen; final ValueChanged<ResultItem> onDelete; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 6), const Text('Your recent formatted results', style: TextStyle(color: muted)), const SizedBox(height: 18), Expanded(child: items.isEmpty ? const EmptyState(icon: Icons.history, title: 'No saved results yet', subtitle: 'Your formatted content will show up here.') : ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 9), itemBuilder: (_, i) => Card(child: ListTile(onTap: () => onOpen(items[i]), leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)), child: Icon(items[i].kind.contains('JSON') ? Icons.data_object : items[i].kind == 'CSV' ? Icons.table_chart : Icons.description, color: brand)), title: Text(items[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${items[i].kind} • ${items[i].date.toLocal().toString().substring(0,16)}'), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'delete') onDelete(items[i]); if (v == 'share') Share.share(items[i].content); }, itemBuilder: (_) => const [PopupMenuItem(value: 'share', child: Text('Share')), PopupMenuItem(value: 'delete', child: Text('Delete'))])))))])); }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool localOnly = true;
  bool saveHistory = true;
  String format = 'Plain Text';
  String language = 'English';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      localOnly = preferences.getBool('localOnly') ?? true;
      saveHistory = preferences.getBool('saveHistory') ?? true;
      format = preferences.getString('defaultFormat') ?? 'Plain Text';
      language = preferences.getString('ocrLanguage') ?? 'English';
    });
  }

  Future<void> _set(String key, Object value) async {
    final preferences = await SharedPreferences.getInstance();
    if (value is bool) {
      await preferences.setBool(key, value);
    } else if (value is String) {
      await preferences.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Make Format Anything work your way.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Preferences'),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.palette_outlined, color: brand),
                title: Text('Appearance'),
                subtitle: Text('System theme'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.output_rounded, color: brand),
                title: const Text('Default output format'),
                subtitle: Text(format),
                trailing: DropdownButton<String>(
                  value: format,
                  underline: const SizedBox(),
                  items: const [
                    'Plain Text',
                    'JSON',
                    'CSV',
                    'Markdown',
                  ].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => format = value);
                    _set('defaultFormat', value);
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.translate, color: brand),
                title: const Text('OCR language'),
                subtitle: Text(language),
                trailing: DropdownButton<String>(
                  value: language,
                  underline: const SizedBox(),
                  items: const ['English'].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => language = value);
                    _set('ocrLanguage', value);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Privacy & Processing'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: localOnly,
                onChanged: (value) {
                  setState(() => localOnly = value);
                  _set('localOnly', value);
                },
                secondary: const Icon(Icons.shield_outlined, color: brand),
                title: const Text('Prefer on-device processing'),
                subtitle: const Text(
                  'Keep routine processing on this device.',
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: saveHistory,
                onChanged: (value) {
                  setState(() => saveHistory = value);
                  _set('saveHistory', value);
                },
                secondary: const Icon(Icons.history, color: brand),
                title: const Text('Save history locally'),
                subtitle: const Text('Store results on this device.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('About'),
        const SizedBox(height: 10),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline, color: brand),
            title: Text('Format Anything'),
            subtitle: Text('Version 1.0.0 • Local-first starter'),
          ),
        ),
      ],
    );
  }
}

class ActionTile extends StatelessWidget { const ActionTile({super.key, required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap}); final IconData icon; final Color color; final String title, subtitle; final VoidCallback onTap; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Card(child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: color, size: 20)), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text(subtitle, style: const TextStyle(color: muted, fontSize: 11))])))); } 
class FeatureRow extends StatelessWidget { const FeatureRow({super.key, required this.icon, required this.color, required this.title, required this.subtitle}); final IconData icon; final Color color; final String title, subtitle; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: muted, fontSize: 12))]))])); }
class SectionTitle extends StatelessWidget { const SectionTitle(this.text, {super.key, this.trailing}); final String text; final String? trailing; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink))), if (trailing != null) Text(trailing!, style: const TextStyle(color: muted, fontSize: 11))]); }
class RecentRow extends StatelessWidget { const RecentRow({super.key, required this.item, required this.onTap}); final ResultItem item; final VoidCallback onTap; @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: const Icon(Icons.description_outlined, color: brand), title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${item.kind} • ${item.date.hour}:${item.date.minute.toString().padLeft(2,'0')}'), trailing: const Icon(Icons.more_vert))); }
class EmptyState extends StatelessWidget { const EmptyState({super.key, required this.icon, required this.title, required this.subtitle}); final IconData icon; final String title, subtitle; @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: brand, size: 30)), const SizedBox(height: 14), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12))]))); }
