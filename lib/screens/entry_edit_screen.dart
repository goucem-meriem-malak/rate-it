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
  late int _acting = widget.existing?.acting ?? 0;
  late int _cine = widget.existing?.cinematography ?? 0;
  late int _plot = widget.existing?.plot ?? 0;
  late int _aesthetic = widget.existing?.aesthetic ?? 0;
  late int _sound = widget.existing?.sound ?? 0;
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
      acting: _acting,
      cinematography: _cine,
      plot: _plot,
      aesthetic: _aesthetic,
      sound: _sound,
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
    return Scaffold(
      appBar: AppBar(title: Text(info.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              PosterImage(path: info.posterPath, width: 70, height: 105),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${info.title}\n${info.year} · ${info.genres.join(', ')}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t(context, 'list'), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
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
          const Divider(),
          _row('overall', _overall, (v) => setState(() => _overall = v), size: 38),
          const Divider(),
          _row('acting', _acting, (v) => setState(() => _acting = v)),
          _row('cinematography', _cine, (v) => setState(() => _cine = v)),
          _row('plot', _plot, (v) => setState(() => _plot = v)),
          _row('aesthetic', _aesthetic, (v) => setState(() => _aesthetic = v)),
          _row('sound', _sound, (v) => setState(() => _sound = v)),
          const SizedBox(height: 12),
          TextField(
            controller: _review,
            minLines: 3,
            maxLines: 6,
            decoration: fieldDec(label: t(context, 'review')),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t(context, _suggest ? 'suggest' : 'do_not_suggest')),
            value: _suggest,
            onChanged: (v) => setState(() => _suggest = v),
          ),
          const SizedBox(height: 12),
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
