import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';
import 'title_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<TitleInfo>? _results;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Tmdb.search(q);
      if (!mounted) return;
      setState(() => _results = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Remove the whole text at once.
  void _clear() {
    _controller.clear();
    setState(() {
      _results = null;
      _error = null;
    });
  }

  Widget _body(BuildContext context) {
    if (_loading) return const SearchSkeleton();
    final results = _results;
    if (results == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined, size: 56, color: brand),
            const SizedBox(height: 12),
            Text(t(context, 'search_start'), style: TextStyle(color: context.muted)),
          ],
        ),
      );
    }
    if (results.isEmpty) {
      return Center(child: Text(t(context, 'no_results')));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final info = results[i];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TitleScreen(info: info))),
            child: Glass(
              padding: const EdgeInsets.all(10),
              radius: 20,
              child: Row(
                children: [
                  PosterImage(path: info.posterPath, width: 52, height: 78),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${info.year} · ${t(context, info.mediaType)}',
                            style: TextStyle(color: context.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: Text(t(context, 'search'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _run,
                decoration: fieldDec(
                  context,
                  hint: t(context, 'search_hint'),
                  prefix: const Icon(Icons.search),
                  suffix: value.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clear,
                        ),
                ),
              ),
            ),
          ),
          if (!Tmdb.hasKey)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t(context, 'missing_key')),
            ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }
}
