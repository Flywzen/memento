import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class JournalEntry {
  final String text;
  final DateTime date;
  final String ageTag;

  JournalEntry({required this.text, required this.date, required this.ageTag});

  Map<String, dynamic> toJson() =>
      {'text': text, 'date': date.toIso8601String(), 'ageTag': ageTag};

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        text: json['text'],
        date: DateTime.parse(json['date']),
        ageTag: json['ageTag'],
      );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const DateTime _birth = DateTime(2004, 10, 27);

const List<String> _quotes = [
  'waktu yang terbuang tidak pernah kembali —\ntapi hari ini masih milik lo.',
  'setiap hari yang berlalu adalah halaman baru —\nlo yang menentukan isinya.',
  'umur bukan angka — ia adalah jumlah hari\nyang lo pilih untuk digunakan.',
  'prokrastinator terbaik adalah\nyang sadar dan mulai bergerak hari ini.',
  'bukan soal kemarin yang terbuang,\ntapi soal apa yang lo lakukan sekarang.',
  'hidup tidak menunggu — ia terus berjalan\ndengan atau tanpa persetujuan lo.',
];

Map<String, int> _getAge(DateTime now) {
  int years = now.year - _birth.year;
  int months = now.month - _birth.month;
  int days = now.day - _birth.day;
  if (days < 0) {
    months--;
    final prev = DateTime(now.year, now.month, 0);
    days += prev.day;
  }
  if (months < 0) {
    years--;
    months += 12;
  }
  return {'years': years, 'months': months, 'days': days};
}

int _getDaysLived(DateTime now) =>
    now.difference(_birth).inDays;

double _getYearProgress(DateTime now) {
  DateTime prev = DateTime(now.year, _birth.month, _birth.day);
  if (prev.isAfter(now)) prev = DateTime(now.year - 1, _birth.month, _birth.day);
  final next = DateTime(prev.year + 1, _birth.month, _birth.day);
  final total = next.difference(prev).inDays;
  final passed = now.difference(prev).inDays;
  return (passed / total).clamp(0.0, 1.0);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _now = DateTime.now();
  Timer? _timer;
  List<JournalEntry> _entries = [];
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _saving = false;

  static const _monoStyle = TextStyle(
    fontFamily: 'monospace',
    letterSpacing: 0.5,
  );

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('journal_entries') ?? '[]';
    final list = jsonDecode(raw) as List;
    setState(() {
      _entries = list.map((e) => JournalEntry.fromJson(e)).toList();
    });
  }

  Future<void> _saveEntry() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final age = _getAge(_now);
    final entry = JournalEntry(
      text: text,
      date: _now,
      ageTag: '${age['years']}y ${age['months']}m ${age['days']}d',
    );
    _entries.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'journal_entries', jsonEncode(_entries.map((e) => e.toJson()).toList()));
    _ctrl.clear();
    _focus.unfocus();
    setState(() => _saving = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final age = _getAge(_now);
    final days = _getDaysLived(_now);
    final progress = _getYearProgress(_now);
    final quote = _quotes[days % _quotes.length];
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_now);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Age Hero ────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${age['years']}',
                        style: GoogleFonts.syne(
                          fontSize: 96,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE8E4DC),
                          height: 1,
                          letterSpacing: -4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TAHUN LO BERJALAN',
                        style: _monoStyle.copyWith(
                          fontSize: 10,
                          color: const Color(0xFF555555),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${age['months']} bulan ${age['days']} hari berjalan  •  hari ke-${_fmt(days)} kehidupan lo',
                        style: _monoStyle.copyWith(
                          fontSize: 12,
                          color: const Color(0xFF888888),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Live Ticker ─────────────────────────────────────────────
                Center(
                  child: Text(
                    '— $timeStr —',
                    style: _monoStyle.copyWith(
                      fontSize: 13,
                      color: const Color(0xFFC8B89A),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Stats Row ───────────────────────────────────────────────
                Row(
                  children: [
                    _statCard(_fmt(days), 'hari hidup'),
                    const SizedBox(width: 8),
                    _statCard(_fmt(days ~/ 7), 'minggu'),
                    const SizedBox(width: 8),
                    _statCard('${_entries.length}', 'catatan'),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Year Progress ───────────────────────────────────────────
                _label('perjalanan tahun ini'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF1A1A1A),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFC8B89A)),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('d MMM').format(
                          DateTime(_now.year, _birth.month, _birth.day)
                              .isBefore(_now)
                              ? DateTime(_now.year, _birth.month, _birth.day)
                              : DateTime(_now.year - 1, _birth.month, _birth.day)),
                      style: _monoStyle.copyWith(
                          fontSize: 10, color: const Color(0xFF555555)),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: _monoStyle.copyWith(
                          fontSize: 10, color: const Color(0xFF555555)),
                    ),
                    Text(
                      DateFormat('d MMM').format(
                          DateTime(_now.year, _birth.month, _birth.day)
                              .isAfter(_now)
                              ? DateTime(_now.year, _birth.month, _birth.day)
                              : DateTime(_now.year + 1, _birth.month, _birth.day)),
                      style: _monoStyle.copyWith(
                          fontSize: 10, color: const Color(0xFF555555)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Quote ───────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFC8B89A), width: 2),
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    '"$quote"',
                    style: _monoStyle.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                      fontStyle: FontStyle.italic,
                      height: 1.7,
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                _divider(),
                const SizedBox(height: 20),

                // ── Entry Input ─────────────────────────────────────────────
                _label('perubahan hari ini — $dateStr'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    maxLines: 4,
                    style: _monoStyle.copyWith(
                      fontSize: 13,
                      color: const Color(0xFFE8E4DC),
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'apa yang berubah hari ini?\nskill baru, kebiasaan baru, pola pikir baru...',
                      hintStyle: _monoStyle.copyWith(
                          fontSize: 12, color: const Color(0xFF3A3A3A)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8B89A),
                      foregroundColor: const Color(0xFF0A0A0A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3)),
                      elevation: 0,
                    ),
                    child: Text(
                      _saving ? 'MENYIMPAN...' : 'SIMPAN CATATAN',
                      style: GoogleFonts.syne(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                _divider(),
                const SizedBox(height: 20),

                // ── Log ─────────────────────────────────────────────────────
                _label('log perubahan lo'),
                const SizedBox(height: 12),

                if (_entries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'belum ada catatan — mulai hari ini.',
                        style: _monoStyle.copyWith(
                            fontSize: 12, color: const Color(0xFF333333)),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _entryCard(_entries[i]),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _statCard(String num, String lbl) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Text(num,
                  style: _monoStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFC8B89A))),
              const SizedBox(height: 4),
              Text(lbl,
                  style: _monoStyle.copyWith(
                      fontSize: 9,
                      color: const Color(0xFF444444),
                      letterSpacing: 1)),
            ],
          ),
        ),
      );

  Widget _entryCard(JournalEntry e) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: const Color(0xFF1E1E1E), width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(e.date),
                  style: _monoStyle.copyWith(
                      fontSize: 10, color: const Color(0xFF555555)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1A14),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    e.ageTag,
                    style: _monoStyle.copyWith(
                        fontSize: 9, color: const Color(0xFFC8B89A)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                e.text,
                style: _monoStyle.copyWith(
                    fontSize: 13,
                    color: const Color(0xFFAAAAAA),
                    height: 1.6),
              ),
            ),
          ],
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: _monoStyle.copyWith(
          fontSize: 10,
          color: const Color(0xFF555555),
          letterSpacing: 2,
        ),
      );

  Widget _divider() => Container(
        height: 0.5,
        color: const Color(0xFF1A1A1A),
      );

  String _fmt(int n) => NumberFormat('#,###').format(n);
}
