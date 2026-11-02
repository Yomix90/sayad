import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import 'spots_api.dart';

const forumCategories = [
  'general',
  'surfcasting',
  'spinning',
  'pole',
  'boat',
  'qa',
  'catches',
  'videos',
];
const forumReactions = ['like', 'love', 'fish', 'wow'];
const reactionEmoji = {'like': '👍', 'love': '❤️', 'fish': '🐟', 'wow': '😮'};

class ForumUser {
  ForumUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final int id;
  final String username;
  final String displayName;

  factory ForumUser.fromJson(Map<String, dynamic> j) => ForumUser(
    id: (j['id'] as num).toInt(),
    username: j['username'] as String,
    displayName: j['display_name'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
  };
}

class ForumComment {
  ForumComment({
    required this.id,
    required this.userId,
    required this.author,
    required this.body,
    required this.time,
    this.ai = false,
  });

  final int id;
  final int? userId;
  final String author;
  final String body;
  final DateTime time;

  /// Answer written by the server's AI.
  final bool ai;

  factory ForumComment.fromJson(Map<String, dynamic> j) => ForumComment(
    id: (j['id'] as num).toInt(),
    userId: (j['user_id'] as num?)?.toInt(),
    author: j['author'] as String,
    body: j['body'] as String,
    time: _time(j['created_at']),
    ai: j['ai'] == true || j['ai'] == 1,
  );
}

class Article {
  Article({
    required this.id,
    required this.title,
    required this.category,
    required this.excerpt,
    required this.author,
    required this.userId,
    required this.images,
    required this.time,
    required this.source,
    required this.commentCount,
    required this.reactions,
    this.kind = 'article',
    this.body,
    this.comments = const [],
    this.myReaction,
  });

  final int id;
  final String title;
  final String category;
  final String excerpt;
  final String author;
  final int? userId;
  final List<String> images;
  final DateTime time;
  final String source;

  /// 'article' or 'question'.
  final String kind;
  final int commentCount;
  final Map<String, int> reactions;
  final String? body;
  final List<ForumComment> comments;
  final String? myReaction;

  int get reactionCount => reactions.values.fold(0, (a, b) => a + b);

  Article copyWith({
    Map<String, int>? reactions,
    String? myReaction,
    bool clearReaction = false,
    List<ForumComment>? comments,
  }) => Article(
    id: id,
    title: title,
    category: category,
    excerpt: excerpt,
    author: author,
    userId: userId,
    images: images,
    time: time,
    source: source,
    kind: kind,
    commentCount: comments?.length ?? commentCount,
    reactions: reactions ?? this.reactions,
    body: body,
    comments: comments ?? this.comments,
    myReaction: clearReaction ? null : (myReaction ?? this.myReaction),
  );

  factory Article.fromJson(Map<String, dynamic> j) => Article(
    id: (j['id'] as num).toInt(),
    title: j['title'] as String,
    category: j['category'] as String,
    excerpt: (j['excerpt'] as String?) ?? '',
    author: j['author'] as String,
    userId: (j['user_id'] as num?)?.toInt(),
    images: [
      for (final u in j['images'] as List) ForumApi.imageUrl(u as String),
    ],
    time: _time(j['created_at']),
    source: (j['source'] as String?) ?? 'app',
    kind: (j['kind'] as String?) ?? 'article',
    commentCount: (j['comments'] as num? ?? 0).toInt(),
    reactions: _reactions(j['reactions']),
    body: j['body'] as String?,
    comments: [
      for (final c in (j['comment_list'] as List?) ?? const [])
        ForumComment.fromJson(c as Map<String, dynamic>),
    ],
    myReaction: j['my_reaction'] as String?,
  );
}

DateTime _time(Object? v) =>
    DateTime.fromMillisecondsSinceEpoch(((v as num?) ?? 0).toInt() * 1000);

Map<String, int> _reactions(Object? v) => {
  for (final e in ((v as Map?) ?? const {}).entries)
    e.key as String: (e.value as num).toInt(),
};

class ForumException implements Exception {
  ForumException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => message;
}

/// Client of the forum of the Sayad server (same server as the spots).
class ForumApi {
  ForumApi({this.token, http.Client? client})
    : _client = client ?? testClient ?? http.Client();

  @visibleForTesting
  static http.Client? testClient;

  /// Session token of the logged-in user, if any.
  final String? token;
  final http.Client _client;

  static bool get enabled => SpotsApi.base.isNotEmpty;

  /// Images uploaded to the server are stored as `/media/…`.
  static String imageUrl(String u) =>
      u.startsWith('/') ? '${SpotsApi.base}$u' : u;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${SpotsApi.base}$path').replace(queryParameters: query);

  dynamic _decode(http.Response res, {int ok = 200}) {
    final body = res.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != ok) {
      final detail = body is Map ? body['detail'] : null;
      throw ForumException(
        res.statusCode,
        detail is String ? detail : 'HTTP ${res.statusCode}',
      );
    }
    return body;
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async =>
      _decode(
        await _client
            .get(_uri(path, query), headers: _headers)
            .timeout(_timeout),
      );

  Future<dynamic> _post(String path, Object body, {int ok = 200}) async =>
      _decode(
        await _client
            .post(_uri(path), headers: _headers, body: jsonEncode(body))
            .timeout(_timeout),
        ok: ok,
      );

  static const _timeout = Duration(seconds: 25);

  Future<(String, ForumUser)> register(
    String username,
    String password,
    String displayName,
  ) async {
    final j = await _post('/auth/register', {
      'username': username,
      'password': password,
      'display_name': displayName,
    }, ok: 201) as Map<String, dynamic>;
    return (
      j['token'] as String,
      ForumUser.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  Future<(String, ForumUser)> login(String username, String password) async {
    final j = await _post('/auth/login', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    return (
      j['token'] as String,
      ForumUser.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await _post('/auth/logout', const {});
    } catch (_) {
      // Already logged out on the server.
    }
  }

  Future<(int, List<Article>)> articles({
    String category = '',
    String kind = '',
    String query = '',
    int offset = 0,
    int limit = 20,
  }) async {
    final j = await _get('/forum/articles', {
      'category': category,
      'kind': kind,
      'q': query,
      'offset': '$offset',
      'limit': '$limit',
    }) as Map<String, dynamic>;
    return (
      (j['total'] as num).toInt(),
      [
        for (final a in j['items'] as List)
          Article.fromJson(a as Map<String, dynamic>),
      ],
    );
  }

  Future<Article> article(int id) async => Article.fromJson(
    await _get('/forum/articles/$id') as Map<String, dynamic>,
  );

  Future<Article> post({
    required String title,
    required String body,
    required String category,
    String kind = 'article',
    List<String> images = const [],
  }) async {
    final j = await _post('/forum/articles', {
      'title': title,
      'body': body,
      'category': category,
      'kind': kind,
      'images': images,
    }, ok: 201);
    return Article.fromJson(j as Map<String, dynamic>);
  }

  /// Whether the server can rewrite texts with AI.
  Future<bool> aiEnabled() async {
    try {
      return ((await _get('/forum/ai')) as Map<String, dynamic>)['enabled'] ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// A clearer version of a text being written, from the server's AI.
  Future<(String, String)> improve(
    String title,
    String body,
    String kind,
  ) async {
    // The server may try several AI models in turn: wait longer than usual.
    final res = await _client
        .post(
          _uri('/forum/ai/improve'),
          headers: _headers,
          body: jsonEncode({'title': title, 'body': body, 'kind': kind}),
        )
        .timeout(const Duration(seconds: 100));
    final j = _decode(res) as Map<String, dynamic>;
    return (j['title'] as String, j['body'] as String);
  }

  Future<void> deleteArticle(int id) async => _decode(
    await _client
        .delete(_uri('/forum/articles/$id'), headers: _headers)
        .timeout(_timeout),
  );

  /// Returns the new counts and the user's reaction (null when removed).
  Future<(Map<String, int>, String?)> react(int id, String? type) async {
    final j = await _post('/forum/articles/$id/react', {
      'type': type,
    }) as Map<String, dynamic>;
    return (_reactions(j['reactions']), j['my_reaction'] as String?);
  }

  Future<List<ForumComment>> comment(int id, String body) async {
    final j = await _post('/forum/articles/$id/comments', {
      'body': body,
    }, ok: 201) as List;
    return [
      for (final c in j) ForumComment.fromJson(c as Map<String, dynamic>),
    ];
  }

  Future<void> deleteComment(int id) async => _decode(
    await _client
        .delete(_uri('/forum/comments/$id'), headers: _headers)
        .timeout(_timeout),
  );

  /// Uploads a picture and returns its server path (`/media/…`).
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('POST', _uri('/forum/images'))
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    final res = await http.Response.fromStream(
      await _client.send(req).timeout(const Duration(seconds: 60)),
    );
    return (_decode(res, ok: 201) as Map<String, dynamic>)['url'] as String;
  }
}
