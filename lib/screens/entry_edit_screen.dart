import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

/// "Add to list" page: list, ratings, review, suggest toggle.
class EntryEditScreen extends StatefulWidget {
  final TitleInfo info;
  final Entry? existing;
  const EntryEditScreen({super.key, required this.info, this.existing});

  @override
  State<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends State<EntryEditScreen> {
  late String _list = widget.existing?.list ?? 'watching';
  late int _overall = widget.existing?.overall ?? 0;
  late int _plot = widget.existing?.plot ?? 0;
  late int _acting = widget.existing?.acting ?? 0;
  late int _pacing = widget.existing?.sound ?? 0; // stored in the 'sound' field
  late int _aesthetic = widget.existing?.aesthetic ?? 0;
  late bool _suggest = widget.existing?.suggest ?? true;
  final _review = TextEditingController();
  bool _pin = false;
  bool _wasPinned = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _review.text = widget.existing?.review ?? '';
    Db.profile(Db.uid).first.then((p) {
      if (!mounted) return;
      setState(() {
        _wasPinned = p?.lastWatched?.key == widget.info.key;
        _pin = _wasPinned;
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final e = Entry(
      uid: Db.uid,
      info: widget.info,
      list: _list,
      overall: _overall,
      plot: _plot,
      acting: _acting,
      sound: _pacing,
      aesthetic: _aesthetic,
      review: _review.text.trim(),
      suggest: _suggest,
    );
    try {
      await Db.saveEntry(e, pin: _pin, wasPinned: _wasPinned);
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t(ctx, 'confirm_delete')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t(ctx, 'cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t(ctx, 'delete'))),
        ],
      ),
    );
    if (ok != true) return;
    await Db.deleteEntry(widget.existing!, wasPinned: _wasPinned);
    if (mounted) Navigator.pop(context);
  }

  Widget _row(String key, int value, ValueChanged<int> onChanged, {double size = 30}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(t(context, key))),
          StarRating(value: value, onChanged: onChanged, size: size),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return GlassScaffold(
      appBar: AppBar(title: Text(info.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          Row(
            children: [
              PosterImage(path: info.posterPath, width: 70, height: 105),
              const SizedBox(width: 14),
              Expanded(
                child: Text('${info.title}\n${info.year} · ${info.genres.join(', ')}'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t(context, 'list'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final k in ['watching', 'watched', 'dropped'])
                      ChoiceChip(
                        label: Text(t(context, k)),
                        selected: _list == k,
                        onSelected: (_) => setState(() => _list = k),
                      ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t(context, 'set_last_watched')),
                  value: _pin,
                  onChanged: (v) => setState(() => _pin = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Glass(
            child: Column(
              children: [
                _row('overall', _overall, (v) => setState(() => _overall = v), size: 38),
                const Divider(height: 24),
                _row('plot', _plot, (v) => setState(() => _plot = v)),
                _row('acting', _acting, (v) => setState(() => _acting = v)),
                _row('sound', _pacing, (v) => setState(() => _pacing = v)),
                _row('aesthetic', _aesthetic, (v) => setState(() => _aesthetic = v)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _review,
            minLines: 3,
            maxLines: 6,
            decoration: fieldDec(context, label: t(context, 'review')),
          ),
          const SizedBox(height: 14),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t(context, _suggest ? 'suggest' : 'do_not_suggest')),
              value: _suggest,
              onChanged: (v) => setState(() => _suggest = v),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(t(context, 'save')),
          ),
          if (widget.existing != null)
            TextButton(
              onPressed: _saving ? null : _delete,
              child: Text(t(context, 'delete')),
            ),
        ],
      ),
    );
  }
}
