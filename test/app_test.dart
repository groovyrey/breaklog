import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breaklog/components/brk_sheet.dart';
import 'package:breaklog/constants/battle_stages.dart';
import 'package:breaklog/constants/practice_reminder_messages.dart';
import 'package:breaklog/models/battle.dart';
import 'package:breaklog/models/battle_session.dart';
import 'package:breaklog/models/category.dart';
import 'package:breaklog/models/media.dart';
import 'package:breaklog/models/move.dart';
import 'package:breaklog/models/note.dart';
import 'package:breaklog/models/prep_item.dart';
import 'package:breaklog/models/set.dart';
import 'package:breaklog/services/battle_repository.dart';
import 'package:breaklog/services/battle_session_repository.dart';
import 'package:breaklog/services/simulation_engine.dart';
import 'package:breaklog/services/breaklog_api.dart';
import 'package:breaklog/services/drive_backup.dart';
import 'package:breaklog/services/version_checker.dart';
import 'package:breaklog/state/update_notifier.dart';
import 'package:breaklog/utils/battle_countdown.dart';
import 'package:breaklog/utils/cooldown_notice.dart';
import 'package:breaklog/utils/duration_label.dart';
import 'package:breaklog/utils/reminder_times.dart';
import 'package:breaklog/utils/semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('version checker', () {
    http.Client releasesResponse(List<Map<String, dynamic>> releases) {
      return MockClient((request) async {
        expect(request.url.path, contains('/repos/groovyrey/breaklog/releases'));
        return http.Response(
          '[${releases.map((r) => jsonEncode(r)).join(',')}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
    }

    test('announces the newest stable release', () async {
      final checker = VersionChecker(client: releasesResponse([
        {
          'tag_name': 'v1.0.0',
          'prerelease': false,
          'draft': false,
          'html_url': 'https://example.com/v1.0.0',
          'published_at': '2026-10-04T01:37:04Z',
        },
      ]));
      final latest = await checker.latest(includePrerelease: false);
      expect(latest, isNotNull);
      expect(latest!.version, '1.0.0');
    });

    test('skips the prerelease on the stable channel', () async {
      final checker = VersionChecker(client: releasesResponse([
        {
          'tag_name': 'v2.0.0-beta.1',
          'prerelease': true,
          'draft': false,
          'html_url': 'https://example.com/beta',
          'published_at': '2026-10-05T01:45:00Z',
        },
        {
          'tag_name': 'v1.0.0',
          'prerelease': false,
          'draft': false,
          'html_url': 'https://example.com/stable',
          'published_at': '2026-10-04T01:37:04Z',
        },
      ]));
      expect((await checker.latest())!.version, '1.0.0');
      expect((await checker.latest(includePrerelease: true))!.version,
          '2.0.0-beta.1');
    });

    test('recovers the rolling beta version from its asset name', () async {
      final checker = VersionChecker(client: releasesResponse([
        {
          'tag_name': 'beta',
          'prerelease': true,
          'draft': false,
          'html_url': 'https://example.com/beta',
          'published_at': '2026-10-02T01:45:00Z',
          'assets': [
            {
              'name': 'BreakLog-1.3.0-beta.apk',
              'browser_download_url': 'https://example.com/beta.apk',
              'size': 1,
              'download_count': 0,
              'updated_at': '2026-10-06T03:14:15Z',
            },
          ],
        },
      ]));
      final beta = (await checker.latest(includePrerelease: true))!;
      expect(beta.version, '1.3.0-beta');
    });
  });

  group('update notifier', () {
    UpdateNotifier notifierWith(List<Map<String, dynamic>> releases) =>
        UpdateNotifier(
          checker: VersionChecker(client: MockClient((_) async {
            return http.Response(
              '[${releases.map((r) => jsonEncode(r)).join(',')}]',
              200,
              headers: {'content-type': 'application/json'},
            );
          })),
          installedVersion: '1.0.0',
        );

    test('flags a pending release newer than the installed build', () async {
      final notifier = notifierWith([
        {
          'tag_name': 'v9.0.0',
          'prerelease': false,
          'draft': false,
          'html_url': 'https://example.com/v9.0.0',
          'published_at': '2026-10-05T10:00:00Z',
        },
      ]);
      await notifier.check(includePrerelease: false, enabled: true);
      expect(notifier.hasUpdateOn(false), isTrue);
    });

    test('the installed build itself is not pending', () async {
      final notifier = notifierWith([
        {
          'tag_name': 'v1.0.0',
          'prerelease': false,
          'draft': false,
          'html_url': 'https://example.com/v1.0.0',
          'published_at': '2026-10-04T15:04:14Z',
        },
      ]);
      await notifier.check(includePrerelease: false, enabled: true);
      expect(notifier.hasUpdateOn(false), isFalse);
    });
  });

  group('semver', () {
    test('orders core components numerically', () {
      expect(SemVer('v1.10.0') > SemVer('1.9.9'), isTrue);
      expect(SemVer('1.1.0') < SemVer('1.1.1'), isTrue);
    });

    test('ranks a stable tag above its prereleases', () {
      expect(SemVer('1.1.0') > SemVer('1.1.0-beta.1'), isTrue);
      expect(SemVer('1.3.0-beta') > SemVer('1.2.0'), isTrue);
    });

    test('strips the v prefix and build metadata for display', () {
      expect(SemVer('v1.1.0+17').label, '1.1.0');
      expect(SemVer('1.1.0').isPreRelease, isFalse);
    });
  });

  group('cooldown notice', () {
    test('counts whole calendar days until the window reopens', () {
      final now = DateTime.now();
      final ends = DateTime(now.year, now.month, now.day + 7, 14, 30);
      expect(
        cooldownNotice(ends),
        'Edits open again in 7 days (${DateFormat.yMMMd().format(ends)})',
      );
    });

    test('says one day when it opens tomorrow', () {
      final now = DateTime.now();
      final ends = DateTime(now.year, now.month, now.day + 1, 9);
      expect(cooldownNotice(ends), startsWith('Edits open again in 1 day ('));
    });

    test('says today when the window opens later today', () {
      final now = DateTime.now();
      final ends = DateTime(now.year, now.month, now.day, 23, 59);
      expect(cooldownNotice(ends), contains('today'));
    });
  });

  group('category store', () {
    test('reads back a category written by toJson', () {
      const category = MoveCategory('Airfreeze');
      final restored = MoveCategory.fromJson(
        jsonDecode(jsonEncode(category.toJson())),
      );
      expect(restored.name, 'Airfreeze');
    });

    test('still accepts a bare string from older storage', () {
      expect(MoveCategory.fromJson('Section').name, 'Section');
    });
  });

  group('move model', () {
    test('round-trips through JSON', () {
      final move = BboyMove(
        id: '42',
        name: 'Airflare',
        category: 'Power',
        difficulty: 5,
        depth: MoveDepth.myCreation,
        notes: 'Two revolutions',
        media: const [
          MoveMedia(
            id: '1',
            kind: MediaKind.link,
            value: 'https://example.com/airflare',
          ),
        ],
        learnedAt: DateTime.utc(2026, 10, 1),
        favorite: true,
      );
      final back = BboyMove.fromJson(jsonDecode(jsonEncode(move.toJson())));
      expect(back.id, move.id);
      expect(back.name, move.name);
      expect(back.category, 'Power');
      expect(back.difficulty, 5);
      expect(back.depth, MoveDepth.myCreation);
      expect(back.media.single.kind, MediaKind.link);
      expect(back.media.single.value, 'https://example.com/airflare');
      expect(back.favorite, isTrue);
      expect(back.learnedAt, move.learnedAt);
    });

    test('migrates the pre-media videoUrl field into an attachment', () {
      final move = BboyMove.fromJson({
        'id': '7',
        'name': 'Windmill',
        'category': 'Power',
        'videoUrl': 'https://example.com/windmill',
      });
      expect(move.media.single.kind, MediaKind.video);
      expect(move.media.single.value, 'https://example.com/windmill');
    });

    test('clamps difficulty into the 1 to 5 range', () {
      final move = BboyMove.fromJson({
        'id': '1',
        'name': 'Bad data',
        'category': 'nope',
        'difficulty': 99,
      });
      expect(move.difficulty, 5);
      expect(move.depth, MoveDepth.universal);
    });
  });

  group('set model', () {
    test('keeps its attachments through JSON', () {
      final set = MoveSet(
        id: '9',
        name: 'Round one',
        moveIds: const ['1', '2'],
        createdAt: DateTime.utc(2026, 10, 2),
        media: const [
          MoveMedia(
            id: 'm1',
            kind: MediaKind.video,
            value: '/data/breaklog_media/1.mp4',
          ),
        ],
      );
      final back = MoveSet.fromJson(jsonDecode(jsonEncode(set.toJson())));
      expect(back.media.single.kind, MediaKind.video);
      expect(back.media.single.value, '/data/breaklog_media/1.mp4');
      expect(back.moveIds, ['1', '2']);
    });

    test('keeps the Drive copy id of an attachment', () {
      const media = MoveMedia(
        id: 'm1',
        kind: MediaKind.photo,
        value: '/data/breaklog_media/a.jpg',
        driveFileId: 'drive-1',
      );
      final back = MoveMedia.fromJson(jsonDecode(jsonEncode(media.toJson())));
      expect(back.driveFileId, 'drive-1');
      expect(back.backedUp, isTrue);
    });

    test('an attachment with no Drive copy is not marked backed up', () {
      expect(
        MoveMedia.fromJson({'id': '1', 'kind': 'photo', 'value': '/tmp/a.jpg'})
            .backedUp,
        isFalse,
      );
    });
  });

  group('note model', () {
    test('round-trips its body, date and attachments through JSON', () {
      final note = LogNote(
        id: 'n1',
        body: 'Finally stuck the roundoff.',
        createdAt: DateTime.utc(2026, 10, 20, 4, 30),
        media: const [
          MoveMedia(
            id: 'm1',
            kind: MediaKind.photo,
            value: '/data/breaklog_media/roundoff.jpg',
            driveFileId: 'drive-9',
          ),
        ],
      );

      final back = LogNote.fromJson(jsonDecode(jsonEncode(note.toJson())));

      expect(back.id, 'n1');
      expect(back.body, 'Finally stuck the roundoff.');
      expect(back.createdAt, DateTime.utc(2026, 10, 20, 4, 30));
      expect(back.media.single.kind, MediaKind.photo);
      expect(back.media.single.driveFileId, 'drive-9');
    });

    test('loads with no attachments when storage has no media list', () {
      final back = LogNote.fromJson({
        'id': 'n1',
        'body': 'Legs were heavy today.',
        'createdAt': '2026-10-20T04:30:00.000Z',
      });

      expect(back.media, isEmpty);
      expect(back.body, 'Legs were heavy today.');
    });
  });

  group('battle plan', () {
    test('round-trips its name, date and stages through JSON', () {
      final plan = BattlePlan(
        id: 'p1',
        name: 'Summer Jam',
        eventAt: DateTime.utc(2026, 8, 1, 18),
        updatedAt: DateTime.utc(2026, 6, 1),
        stages: const [
          PlannedStage(stage: BattleStage.prelims, rounds: 1),
          PlannedStage(
            stage: BattleStage.grandFinal,
            rounds: 3,
            planIds: ['m1', 's1'],
          ),
        ],
      );

      final back = BattlePlan.fromJson(jsonDecode(jsonEncode(plan.toJson())));

      expect(back.id, 'p1');
      expect(back.name, 'Summer Jam');
      expect(back.eventAt, DateTime.utc(2026, 8, 1, 18));
      expect(back.stages.length, 2);
      expect(back.stages.first.stage, BattleStage.prelims);
      expect(back.stages.last.rounds, 3);
      expect(back.stages.last.planIds, ['m1', 's1']);
    });

    test('removes a stage and appends one at the end', () {
      final plan = BattlePlan(
        id: 'p2',
        name: 'Local',
        eventAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 6, 1),
        stages: const [],
      );

      final seeded = plan
          .withStage(-1, const PlannedStage(stage: BattleStage.prelims, rounds: 1))
          .withStage(-1, const PlannedStage(stage: BattleStage.top16, rounds: 1))
          .withoutStage(BattleStage.prelims);

      expect(seeded.stages.length, 1);
      expect(seeded.stages.single.stage, BattleStage.top16);
    });

    test('offers Extra without putting it on a new plan', () {
      expect(allBattleStages, contains(BattleStage.extra));
      expect(defaultBattleStages, isNot(contains(BattleStage.extra)));
      expect(battleStageLabel(BattleStage.extra), 'Extra');
      expect(defaultRoundsFor(BattleStage.extra), 1);
    });

    test('caps stored rounds at the simulation limit', () {
      final stage = PlannedStage.fromJson({
        'stage': 'prelims',
        'rounds': 9,
      });

      expect(maxBattleRounds, 5);
      expect(stage.rounds, maxBattleRounds);
    });
  });

  group('battle repository', () {
    test('keeps several plans and updates them by id', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = BattleRepository();
      await repo.load();

      final first =
          await repo.start(name: 'First', eventAt: DateTime(2026, 9, 1));
      final second =
          await repo.start(name: 'Second', eventAt: DateTime(2026, 7, 1));

      expect(repo.plans.length, 2);
      expect(repo.plans.first.id, second.id);

      await repo.save(first.copyWith(name: 'Renamed'));

      expect(repo.byId(first.id)?.name, 'Renamed');
      expect(repo.plans.length, 2);

      await repo.remove(second.id);

      expect(repo.plans.single.id, first.id);
    });

    test('migrates the old single plan into the list', () async {
      final legacy = BattlePlan(
        id: '',
        name: 'Old battle',
        eventAt: DateTime(2026, 8, 1),
        stages: const [],
        updatedAt: DateTime(2026, 6, 1),
      );
      SharedPreferences.setMockInitialValues({
        'breaklog_battle_plan_v1': jsonEncode(legacy.toJson()),
      });

      final repo = BattleRepository();
      await repo.load();

      expect(repo.plans.single.name, 'Old battle');
      expect(repo.plans.single.id, isNotEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('breaklog_battle_plan_v1'), isNull);
      expect(prefs.getString('breaklog_battle_plans_v1'), contains('Old battle'));
    });
  });

  group('battle session', () {
    test('round-trips selected stages and timings through JSON', () {
      final session = BattleSession(
        id: 's1',
        planId: 'p1',
        stages: const [
          SessionStage(stage: BattleStage.prelims, rounds: 2),
          SessionStage(stage: BattleStage.grandFinal, rounds: 3),
        ],
        turnSeconds: 30,
        restSeconds: 15,
        elapsedSeconds: 75,
        recordedAt: DateTime.utc(2026, 8, 2, 10),
        videoPath: '/data/breaklog_media/run.mp4',
      );

      final back = BattleSession.fromJson(jsonDecode(jsonEncode(session.toJson())));

      expect(back.id, 's1');
      expect(back.planId, 'p1');
      expect(back.stages.length, 2);
      expect(back.stages.last.stage, BattleStage.grandFinal);
      expect(back.totalRounds, 5);
      expect(back.turnSeconds, 30);
      expect(back.restSeconds, 15);
      expect(back.elapsedSeconds, 75);
      expect(back.videoPath, '/data/breaklog_media/run.mp4');
    });

    test('keeps sessions per plan and drops them with the plan', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = BattleSessionRepository();
      await repo.load();

      final session = BattleSession(
        id: '',
        planId: 'p1',
        stages: const [SessionStage(stage: BattleStage.prelims, rounds: 1)],
        turnSeconds: 30,
        restSeconds: 15,
        elapsedSeconds: 45,
        recordedAt: DateTime(2026, 9, 1),
        videoPath: '/tmp/run.mp4',
      );

      await repo.save(session);

      final saved = repo.forPlan('p1').single;
      expect(saved.id, startsWith('session-'));
      expect(repo.forPlan('p2'), isEmpty);

      await repo.save(BattleSession(
        id: saved.id,
        planId: 'p1',
        stages: saved.stages,
        turnSeconds: 20,
        restSeconds: 10,
        elapsedSeconds: 30,
        recordedAt: saved.recordedAt,
        videoPath: saved.videoPath,
      ));

      expect(repo.forPlan('p1').single.turnSeconds, 20);

      await repo.removeForPlan('p1');

      expect(repo.forPlan('p1'), isEmpty);
    });
  });

  group('simulation engine', () {
    test('runs each stage turn then rest until the last round', () {
      final engine = SimulationEngine(
        stages: const [
          SessionStage(stage: BattleStage.prelims, rounds: 2),
          SessionStage(stage: BattleStage.grandFinal, rounds: 1),
        ],
        turnSeconds: 10,
        restSeconds: 5,
      );
      expect(engine.totalRounds, 3);
      engine.play();

      for (var i = 0; i < 10; i++) {
        engine.advanceSecond();
      }
      expect(engine.phase, SimulationPhase.rest);
      expect(engine.round, 1);
      expect(engine.remainingSeconds, 5);

      for (var i = 0; i < 5; i++) {
        engine.advanceSecond();
      }
      expect(engine.phase, SimulationPhase.turn);
      expect(engine.round, 2);

      for (var i = 0; i < 15; i++) {
        engine.advanceSecond();
      }
      expect(engine.stageIndex, 1);
      expect(engine.currentStage.stage, BattleStage.grandFinal);
      expect(engine.round, 1);

      for (var i = 0; i < 15; i++) {
        engine.advanceSecond();
      }
      expect(engine.finished, isTrue);
      expect(engine.running, isFalse);
      expect(engine.elapsedSeconds, 45);
      expect(engine.progress, 1);

      engine.dispose();
    });

    test('stops the clock while paused', () {
      final engine = SimulationEngine(
        stages: const [SessionStage(stage: BattleStage.prelims, rounds: 1)],
        turnSeconds: 10,
        restSeconds: 5,
      );
      engine.play();
      engine.pause();

      final before = engine.remainingSeconds;
      engine.advanceSecond();

      expect(engine.running, isFalse);
      expect(engine.remainingSeconds, before);

      engine.dispose();
    });
  });

  group('duration label', () {
    test('formats clock and session lengths plainly', () {
      expect(clockLabel(30), '0:30');
      expect(clockLabel(65), '1:05');
      expect(sessionLengthLabel(45), '45s');
      expect(sessionLengthLabel(510), '8m 30s');
      expect(sessionLengthLabel(600), '10m');
    });
  });

  group('battle countdown', () {
    test('names today, tomorrow and the week ahead', () {
      final now = DateTime(2026, 7, 1, 9);
      expect(battleCountdown(now, now: now), 'Today');
      expect(battleCountdown(DateTime(2026, 7, 2), now: now), 'Tomorrow');
      expect(battleCountdown(DateTime(2026, 7, 5), now: now), 'In 4 days');
    });

    test('falls back to the date further out', () {
      final label =
          battleCountdown(DateTime(2026, 8, 20), now: DateTime(2026, 7, 1));
      expect(label, contains('2026'));
    });
  });

  group('prep item', () {
    test('round-trips its text and done flag through JSON', () {
      final item = PrepItem(
        id: 'p1',
        text: 'Practice roundoff to freeze',
        done: true,
        createdAt: DateTime.utc(2026, 6, 20),
      );

      final back = PrepItem.fromJson(jsonDecode(jsonEncode(item.toJson())));

      expect(back.id, 'p1');
      expect(back.text, 'Practice roundoff to freeze');
      expect(back.done, isTrue);
    });
  });

  group('practice reminders', () {
    test('every line is filled in and unique, so a day never repeats a blank',
        () {
      expect(practiceReminderMessages, isNotEmpty);
      expect(practiceReminderMessages.toSet().length,
          practiceReminderMessages.length);
      for (final line in practiceReminderMessages) {
        expect(line.trim(), isNotEmpty);
      }
    });

    test('formats reminder minutes as 12 hour clock times', () {
      final morning = reminderTimeLabel(6 * 60 + 5);
      expect(morning, contains('6:05'));
      expect(morning, contains('AM'));

      final evening = reminderTimeLabel(18 * 60 + 30);
      expect(evening, contains('6:30'));
      expect(evening, contains('PM'));

      expect(reminderTimeLabel(0), contains('12:00'));
    });
  });

  group('accounts api', () {
    const okHeaders = {'content-type': 'application/json'};

    BreaklogApi apiWith(
      http.Response Function(http.Request request) reply, {
      void Function(http.Request request)? onRequest,
    }) {
      return BreaklogApi(
        baseUrl: 'https://api.test',
        client: MockClient((request) async {
          onRequest?.call(request);
          return reply(request);
        }),
      );
    }

    test('sign in sends the token and the alias this device has', () async {
      late http.Request seen;
      final api = apiWith(
        (_) => http.Response(
          jsonEncode({'user': 'u1', 'alias': 'Rey'}),
          200,
          headers: okHeaders,
        ),
        onRequest: (request) => seen = request,
      );
      final row = await api.session('id-token', alias: 'Rey');
      expect(seen.url.toString(), 'https://api.test/auth/session');
      expect(seen.headers['authorization'], 'Bearer id-token');
      expect(jsonDecode(seen.body), {'alias': 'Rey'});
      expect(row['alias'], 'Rey');
    });

    test('sign in sends the start date and the reason when set', () async {
      late http.Request seen;
      final api = apiWith(
        (_) => http.Response('{"user":"u1"}', 200, headers: okHeaders),
        onRequest: (request) => seen = request,
      );
      await api.session(
        'id-token',
        startedAt: '2019-03-01',
        why: 'It keeps me moving',
      );
      expect(jsonDecode(seen.body), {
        'startedAt': '2019-03-01',
        'why': 'It keeps me moving',
      });
    });

    test('a first sign in sends no alias so the account keeps its own', () async {
      late http.Request seen;
      final api = apiWith(
        (_) => http.Response('{"user":"u1"}', 200, headers: okHeaders),
        onRequest: (request) => seen = request,
      );
      await api.session('id-token');
      expect(jsonDecode(seen.body), isEmpty);
    });

    test('saving the profile posts every field to the profile route', () async {
      late http.Request seen;
      final api = apiWith(
        (_) => http.Response('{"alias":"Bboy Rey"}', 200, headers: okHeaders),
        onRequest: (request) => seen = request,
      );
      final row = await api.saveProfile(
        'id-token',
        alias: 'Bboy Rey',
        startedAt: '2019-03-01',
        why: 'It keeps me moving',
      );
      expect(seen.url.path, '/profile');
      expect(jsonDecode(seen.body), {
        'alias': 'Bboy Rey',
        'startedAt': '2019-03-01',
        'why': 'It keeps me moving',
      });
      expect(row['alias'], 'Bboy Rey');
    });

    test('a save inside the weekly window is refused with the next opening',
        () async {
      final nextAt = DateTime.now()
          .add(const Duration(days: 7))
          .millisecondsSinceEpoch;
      final api = apiWith(
        (_) => http.Response(
          '{"error":"Profile can only be updated once a week",'
          '"retryAfter":604800,"nextAt":$nextAt}',
          429,
          headers: okHeaders,
        ),
      );
      await expectLater(
        api.saveProfile('id-token', alias: 'Bboy Rey'),
        throwsA(isA<ProfileCooldownException>().having(
          (error) => error.nextAt,
          'nextAt',
          DateTime.fromMillisecondsSinceEpoch(nextAt),
        )),
      );
    });

    test('a rejected token surfaces the worker message', () async {
      final api = apiWith(
        (_) => http.Response(
          '{"error":"token rejected: malformed token"}',
          401,
          headers: okHeaders,
        ),
      );
      await expectLater(
        api.session('junk'),
        throwsA(isA<ApiException>().having(
          (error) => error.message,
          'message',
          'token rejected: malformed token',
        )),
      );
    });
  });

  group('drive backup', () {
    const okHeaders = {'content-type': 'application/json'};

    test('creates the folder once and reuses it after', () async {
      final requests = <String>[];
      final drive = DriveBackup(
        apiUrl: 'https://drive.test/v3',
        uploadUrl: 'https://drive.test/upload/v3',
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          if (request.method == 'GET') {
            return http.Response('{"files":[]}', 200, headers: okHeaders);
          }
          return http.Response('{"id":"folder-1"}', 200, headers: okHeaders);
        }),
      );

      expect(await drive.ensureFolder('access-token'), 'folder-1');
      expect(await drive.ensureFolder('access-token'), 'folder-1');
      expect(requests, ['GET /v3/files', 'POST /v3/files']);
    });

    test('reuses the folder that already exists', () async {
      final requests = <String>[];
      final drive = DriveBackup(
        apiUrl: 'https://drive.test/v3',
        uploadUrl: 'https://drive.test/upload/v3',
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          return http.Response('{"files":[{"id":"existing"}]}', 200,
              headers: okHeaders);
        }),
      );
      expect(await drive.ensureFolder('token'), 'existing');
      expect(requests, ['GET /v3/files']);
    });

    test('carries the Drive message when a call fails', () async {
      final drive = DriveBackup(
        apiUrl: 'https://drive.test/v3',
        uploadUrl: 'https://drive.test/upload/v3',
        client: MockClient((_) async => http.Response(
              '{"error":{"message":"Insufficient permission"}}',
              403,
              headers: okHeaders,
            )),
      );
      await expectLater(
        drive.ensureFolder('token'),
        throwsA(isA<DriveException>().having(
          (error) => error.message,
          'message',
          'Insufficient permission',
        )),
      );
    });
  });

  group('voice note', () {
    test('keeps the voice kind through a note round trip', () {
      final note = LogNote(
        id: 'n1',
        body: 'Recorded the first round.',
        createdAt: DateTime.utc(2026, 10, 20, 4, 30),
        media: const [
          MoveMedia(
            id: 'v1',
            kind: MediaKind.voice,
            value: '/data/breaklog_media/1.m4a',
          ),
        ],
      );

      final back = LogNote.fromJson(jsonDecode(jsonEncode(note.toJson())));

      expect(back.media.single.kind, MediaKind.voice);
      expect(back.media.single.value, '/data/breaklog_media/1.m4a');
      expect(MediaKind.voice.label, 'Voice');
    });
  });

  group('sheet keyboard inset', () {
    testWidgets('keeps the panel above the keyboard', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: BrkSheet(
                  title: 'Test',
                  child: SizedBox(height: 80),
                ),
              ),
            ),
          ),
        ),
      );

      final panel = tester.getRect(
        find
            .descendant(
              of: find.byType(BrkSheet),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(panel.bottom, lessThanOrEqualTo(500.5));
    });
  });
}
