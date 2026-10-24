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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'search'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              decoration: fieldDec(
                  hint: t(context, 'search_hint'), prefix: const Icon(Icons.search)),
            ),
          ),
          if (!Tmdb.hasKey)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t(context, 'missing_key')),
            ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          Expanded(
            child: _results == null
                ? const SizedBox.shrink()
                : _results!.isEmpty
                    ? Center(child: Text(t(context, 'no_results')))
                    : ListView.builder(
                        itemCount: _results!.length,
                        itemBuilder: (context, i) {
                          final info = _results![i];
                          return ListTile(
                            leading: PosterImage(
                                path: info.posterPath, width: 48, height: 72),
                            title: Text(info.title,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${info.year} · ${t(context, info.mediaType)}'),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => TitleScreen(info: info))),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
