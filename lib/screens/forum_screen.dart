import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/forum_api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/line_icons.dart';
import '../widgets/sub_page.dart';

String categoryLabel(AppLocalizations t, String c) => switch (c) {
      'surfcasting' => t.catSurfcasting,
      'spinning' => t.catSpinning,
      'pole' => t.catPole,
      'boat' => t.catBoat,
      'qa' => t.catQa,
      'catches' => t.catCatches,
      'videos' => t.catVideos,
      _ => t.catGeneral,
    };

String forumError(AppLocalizations t, Object e) {
  if (e is ForumException) {
    return switch (e.status) {
      401 => t.authFailed,
      403 => t.accountSuspended,
      409 => t.usernameTaken,
      422 => t.invalidForm,
      429 => t.tooManyTries,
      _ => t.forumError,
    };
  }
  return t.serverUnreachable;
}

String _date(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(d);

/// Forum tab: articles of the community, newest first, by category.
class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;
  String _category = '';
  List<Article> _items = [];
  int _total = 0;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _load(more: true);
    });
    if (ForumApi.enabled) _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading || (more && _items.length >= _total)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (total, items) = await ForumApi().articles(
          category: _category, query: _search.text.trim(), offset: more ? _items.length : 0);
      if (!mounted) return;
      setState(() {
        _total = total;
        _items = more ? [..._items, ...items] : items;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setCategory(String c) {
    setState(() => _category = c);
    _load();
  }

  Future<void> _write() async {
    final state = AppScope.of(context);
    if (state.forumUser == null && !await openAccount(context)) return;
    if (!mounted) return;
    final created = await Navigator.of(context)
        .push<Article>(MaterialPageRoute(builder: (_) => ComposeScreen(category: _category)));
    if (created != null) {
      _load();
      if (mounted) _open(created);
    }
  }

  Future<void> _open(Article a) async {
    final changed = await Navigator.of(context)
        .push<Article?>(MaterialPageRoute(builder: (_) => ArticleScreen(article: a)));
    if (!mounted) return;
    if (changed == null) {
      // Deleted by its author.
      setState(() => _items = _items.where((x) => x.id != a.id).toList());
    } else {
      setState(() => _items = [for (final x in _items) x.id == a.id ? changed : x]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final state = AppScope.of(context);
    if (!ForumApi.enabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(t.forumDisabled, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
        ),
      );
    }
    return Stack(children: [
      RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
          children: [
            ScreenHead(
              title: t.tabForum,
              trailing: StatusChip(
                label: state.forumUser?.displayName ?? t.login,
                icon: 'user',
                tone: state.forumUser == null ? ChipTone.neutral : ChipTone.ok,
                onTap: () => openAccount(context),
              ),
            ),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: t.searchForum,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LineIcon('search', size: 20, color: p.muted),
                ),
                isDense: true,
              ),
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), _load);
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final c in ['', ...forumCategories])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 7),
                    child: StatusChip(
                      label: c.isEmpty ? t.all : categoryLabel(t, c),
                      compact: false,
                      tone: c == _category ? ChipTone.solid : ChipTone.neutral,
                      onTap: () => _setCategory(c),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            if (_error != null && _items.isEmpty)
              _Message(text: forumError(t, _error!), onRetry: _load)
            else if (!_loading && _items.isEmpty)
              _Message(text: t.forumEmpty)
            else
              for (final a in _items) ArticleCard(article: a, onTap: () => _open(a)),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      PositionedDirectional(
        end: 16,
        bottom: 16,
        child: FloatingActionButton.extended(
          heroTag: 'forum-write',
          onPressed: _write,
          backgroundColor: p.accent,
          foregroundColor: p.classic ? const Color(0xFFF3E9D2) : const Color(0xFF04222B),
          icon: LineIcon('plus', size: 20,
              color: p.classic ? const Color(0xFFF3E9D2) : const Color(0xFF04222B)),
          label: Text(t.writeArticle, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(children: [
        LineIcon('chat', size: 40, color: p.muted),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).retry)),
      ]),
    );
  }
}

/// One article in the list: cover photo, title, excerpt, author and counts.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final a = article;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (a.images.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(p.radius)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                NetImage(a.images.first),
                if (a.images.length > 1)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: StatusChip(label: '+${a.images.length - 1}', icon: 'camera'),
                  ),
              ]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              StatusChip(label: categoryLabel(t, a.category)),
              if (a.source == 'tifnit') StatusChip(label: t.archive, tone: ChipTone.warn),
            ]),
            const SizedBox(height: 8),
            Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: p.title(16.5)),
            if (a.excerpt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(a.excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              LineIcon('user', size: 16, color: p.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text('\u2068${a.author}\u2069 · ${_date(context, a.time)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: 12.5)),
              ),
              if (a.reactionCount > 0) ...[
                Text(_topEmojis(a.reactions), style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text('${a.reactionCount}', style: TextStyle(color: p.muted, fontSize: 12.5)),
                const SizedBox(width: 10),
              ],
              LineIcon('chat', size: 16, color: p.muted),
              const SizedBox(width: 3),
              Text('${a.commentCount}', style: TextStyle(color: p.muted, fontSize: 12.5)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

String _topEmojis(Map<String, int> r) {
  final sorted = r.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(3).map((e) => reactionEmoji[e.key] ?? '').join();
}

/// Network picture with a neutral placeholder while loading or on error.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final empty = ColoredBox(
      color: p.surface2,
      child: Center(child: LineIcon('camera', size: 28, color: p.muted)),
    );
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => empty,
      loadingBuilder: (_, child, progress) => progress == null ? child : empty,
    );
  }
}

/// Full article with its photos, reactions and comments.
class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.article});

  final Article article;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Article _a = widget.article;
  bool _loading = true;
  bool _sending = false;
  Object? _error;
  final _comment = TextEditingController();

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final a = await AppScope.of(context).forum.article(_a.id);
      if (mounted) setState(() => _a = a);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _needLogin() async =>
      AppScope.of(context).forumUser != null || await openAccount(context);

  Future<void> _react(String type) async {
    if (!await _needLogin() || !mounted) return;
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final (counts, mine) = await AppScope.of(context).forum.react(_a.id, type);
      if (mounted) {
        setState(() => _a = _a.copyWith(reactions: counts, myReaction: mine, clearReaction: mine == null));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(forumError(t, e))));
    }
  }

  Future<void> _sendComment() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    if (!await _needLogin() || !mounted) return;
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      final list = await AppScope.of(context).forum.comment(_a.id, text);
      _comment.clear();
      if (mounted) setState(() => _a = _a.copyWith(comments: list));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(forumError(t, e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(ForumComment c) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).forum.deleteComment(c.id);
      if (mounted) {
        setState(() => _a = _a.copyWith(comments: _a.comments.where((x) => x.id != c.id).toList()));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(forumError(t, e))));
    }
  }

  Future<void> _deleteArticle() async {
    final t = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final forum = AppScope.of(context).forum;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.deleteArticleQ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await forum.deleteArticle(_a.id);
      nav.pop(null);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(forumError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final me = AppScope.of(context).forumUser;
    final mine = me != null && _a.userId == me.id;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_a);
      },
      child: SubPage(
        title: categoryLabel(t, _a.category),
        actions: [
          if (mine)
            IconButton(
              onPressed: _deleteArticle,
              tooltip: t.delete,
              icon: Icon(Icons.delete_outline, color: p.headerInk),
            ),
        ],
        body: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 14), children: [
              if (_a.images.isNotEmpty) _Gallery(images: _a.images),
              Text(_a.title, style: p.title(21)),
              const SizedBox(height: 8),
              Row(children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: p.surface2,
                  child: Text(_a.author.characters.first.toUpperCase(),
                      style: TextStyle(color: p.accentInk, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('\u2068${_a.author}\u2069 · ${_date(context, _a.time)}',
                      style: TextStyle(color: p.muted, fontSize: 13)),
                ),
                if (_a.source == 'tifnit') StatusChip(label: t.archive, tone: ChipTone.warn),
              ]),
              const SizedBox(height: 14),
              if (_a.body != null)
                LinkText(_a.body!, style: TextStyle(fontSize: 15.5, height: 1.55, color: p.text))
              else if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _Message(text: forumError(t, _error!), onRetry: _reload),
              const SizedBox(height: 18),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final r in forumReactions)
                  _ReactionButton(
                    emoji: reactionEmoji[r]!,
                    count: _a.reactions[r] ?? 0,
                    selected: _a.myReaction == r,
                    onTap: () => _react(r),
                  ),
              ]),
              const SizedBox(height: 20),
              CardHead(title: '${t.comments} (${_a.comments.length})'),
              if (_a.comments.isEmpty && !_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(t.noComments, style: TextStyle(color: p.muted)),
                ),
              for (final c in _a.comments)
                _CommentTile(
                  comment: c,
                  canDelete: me != null && c.userId == me.id,
                  onDelete: () => _deleteComment(c),
                ),
            ]),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _comment,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 3000,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: me == null ? t.loginToPost : t.writeComment,
                      counterText: '',
                      isDense: true,
                    ),
                    onTap: me == null ? () => openAccount(context) : null,
                    readOnly: me == null,
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _sendComment,
                  tooltip: t.send,
                  icon: _sending
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : LineIcon('send', size: 24, color: p.classic ? p.primary : p.accentInk),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton(
      {required this.emoji, required this.count, required this.selected, required this.onTap});

  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: selected ? p.accent.withValues(alpha: 0.22) : p.surface2,
      shape: StadiumBorder(side: BorderSide(color: selected ? p.accent : p.border, width: selected ? 1.6 : 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text('$count', style: p.num(14)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.canDelete, required this.onDelete});

  final ForumComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(p.radiusS),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\u2068${comment.author}\u2069 · ${_date(context, comment.time)}',
                style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            LinkText(comment.body, style: TextStyle(color: p.text, fontSize: 14.5, height: 1.4)),
          ]),
        ),
        if (canDelete)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 19, color: p.muted),
          ),
      ]),
    );
  }
}

/// Photos of an article; tap to see one full screen.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(p.radius),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _PhotoView(images: widget.images, initial: i))),
                child: NetImage(widget.images[i]),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < widget.images.length && i < 20; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? p.accent : p.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }
}

class _PhotoView extends StatelessWidget {
  const _PhotoView({required this.images, required this.initial});

  final List<String> images;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: images.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(child: NetImage(images[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

/// Text whose web links can be opened.
class LinkText extends StatefulWidget {
  const LinkText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  static final _url = RegExp(r'https?://[^\s<>"]+');
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final p = Palette.of(context);
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _url.allMatches(widget.text)) {
      if (m.start > last) spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      final link = m.group(0)!;
      final r = TapGestureRecognizer()
        ..onTap = () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      _recognizers.add(r);
      spans.add(TextSpan(
          text: link,
          recognizer: r,
          style: TextStyle(color: p.accentInk, decoration: TextDecoration.underline)));
      last = m.end;
    }
    if (last < widget.text.length) spans.add(TextSpan(text: widget.text.substring(last)));
    return SelectableText.rich(TextSpan(style: widget.style, children: spans));
  }
}

/// Writing a new article, with photos from the gallery or the camera.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.category = ''});

  final String category;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  late String _category = widget.category.isEmpty ? 'general' : widget.category;
  final _photos = <XFile>[];
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final picked = source == ImageSource.gallery
        ? await picker.pickMultiImage(maxWidth: 1600, maxHeight: 1600, imageQuality: 82)
        : [
            ?await picker.pickImage(
                source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 82)
          ];
    if (!mounted) return;
    setState(() => _photos.addAll(picked.take(10 - _photos.length)));
    if (_photos.length >= 10) messenger.showSnackBar(SnackBar(content: Text(t.photoLimit)));
  }

  Future<void> _publish() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final forum = AppScope.of(context).forum;
    if (_title.text.trim().length < 3 || _body.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(t.titleTooShort)));
      return;
    }
    setState(() => _sending = true);
    try {
      final urls = <String>[];
      for (final f in _photos) {
        urls.add(await forum.uploadImage(await f.readAsBytes(), f.name));
      }
      final a = await forum.post(
          title: _title.text.trim(), body: _body.text.trim(), category: _category, images: urls);
      messenger.showSnackBar(SnackBar(content: Text(t.published)));
      nav.pop(a);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(forumError(t, e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    return SubPage(
      title: t.newArticle,
      body: ListView(padding: const EdgeInsets.all(14), children: [
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: InputDecoration(labelText: t.category),
          items: [
            for (final c in forumCategories)
              DropdownMenuItem(value: c, child: Text(categoryLabel(t, c))),
          ],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: t.articleTitle),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _body,
          minLines: 6,
          maxLines: 16,
          maxLength: 20000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: t.articleBody, alignLabelWithHint: true),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (i, f) in _photos.indexed)
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(p.radiusS),
                child: FutureBuilder(
                  future: f.readAsBytes(),
                  builder: (_, s) => s.hasData
                      ? Image.memory(s.data!, width: 86, height: 86, fit: BoxFit.cover)
                      : Container(width: 86, height: 86, color: p.surface2),
                ),
              ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: GestureDetector(
                  onTap: () => setState(() => _photos.removeAt(i)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _sending || _photos.length >= 10 ? null : () => _pick(ImageSource.gallery),
              child: IconLabel(icon: LineIcon('layers', size: 19, color: p.text), label: t.addPhotos),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _sending || _photos.length >= 10 ? null : () => _pick(ImageSource.camera),
            child: LineIcon('camera', size: 20, color: p.text),
          ),
        ]),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _sending ? null : _publish,
          child: _sending
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : IconLabel(
                  icon: LineIcon('send',
                      size: 19,
                      color: p.classic ? const Color(0xFFF3E9D2) : const Color(0xFF04222B)),
                  label: t.publish),
        ),
      ]),
    );
  }
}

/// Shows the account page; returns true when the user is logged in after it.
Future<bool> openAccount(BuildContext context) async {
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
  return context.mounted && AppScope.of(context).forumUser != null;
}

/// Log in, create an account, or log out.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final state = AppScope.of(context);
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final (token, user) = _register
          ? await state.forum.register(_user.text.trim(), _pass.text, _name.text.trim())
          : await state.forum.login(_user.text.trim(), _pass.text);
      await state.setForumSession(token, user);
      nav.pop();
    } catch (e) {
      setState(() => _error = forumError(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final p = Palette.of(context);
    final state = AppScope.of(context);
    final user = state.forumUser;
    return SubPage(
      title: t.account,
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [p.accent, p.primary]),
            ),
            child: Center(child: LineIcon('user', size: 38, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        if (user != null) ...[
          Center(child: Text(user.displayName, style: p.title(20))),
          Center(child: Text('@${user.username}', style: TextStyle(color: p.muted))),
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: () async {
              await state.logoutForum();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(t.logout),
          ),
        ] else ...[
          Text(t.loginToPost, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
          const SizedBox(height: 18),
          TextField(
            controller: _user,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
                labelText: t.username, helperText: _register ? t.usernameHint : null),
          ),
          const SizedBox(height: 12),
          if (_register) ...[
            TextField(
              controller: _name,
              maxLength: 40,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: t.displayName),
            ),
            const SizedBox(height: 4),
          ],
          TextField(
            controller: _pass,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: t.password,
              helperText: _register ? t.passwordHint : null,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: p.dangerInk, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_register ? t.register : t.login),
          ),
          TextButton(
            onPressed: () => setState(() {
              _register = !_register;
              _error = null;
            }),
            child: Text(_register ? t.haveAccount : t.noAccount),
          ),
        ],
      ]),
    );
  }
}
