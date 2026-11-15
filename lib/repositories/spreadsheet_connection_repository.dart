import 'dart:async';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/google_retry.dart';
import '../services/google_auth_service.dart';
import '../services/google_drive_service.dart';
import '../services/google_sheets_service.dart';

enum SpreadsheetConnectionStatus {
  noSpreadsheet,
  creating,
  validating,
  ready,
  needsRepair,
  missing,
  noPermission,
  failed,
}

class SpreadsheetConnectionSnapshot {
  const SpreadsheetConnectionSnapshot(
    this.status, {
    this.id,
    this.warning,
    this.failure,
    this.setupCompleted = false,
  });
  final SpreadsheetConnectionStatus status;
  final String? id;
  final String? warning;
  final AppFailure? failure;
  final bool setupCompleted;
}

class SpreadsheetConnectionRepository {
  SpreadsheetConnectionRepository(
    this.auth, {
    GoogleDriveService driveService = const GoogleDriveService(),
    GoogleSheetsService sheetsService = const GoogleSheetsService(),
  }) : _drive = driveService,
       _sheets = sheetsService;
  final GoogleAuthService auth;
  final GoogleDriveService _drive;
  final GoogleSheetsService _sheets;
  Future<SpreadsheetConnectionSnapshot>? _inFlight;
  static const _idKey = 'connected_spreadsheet_id';
  static const _schemaKey = 'spreadsheet_schema_version';
  static const _validatedKey = 'spreadsheet_last_validated_at';

  Future<SpreadsheetConnectionSnapshot> connectOrCreate({
    void Function(SpreadsheetConnectionStatus)? onStatus,
  }) =>
      _inFlight ??= _run(onStatus: onStatus)
          .whenComplete(() => _inFlight = null);
  Future<SpreadsheetConnectionSnapshot> createNew({
    void Function(SpreadsheetConnectionStatus)? onStatus,
  }) => _inFlight ??= _run(
    forceCreate: true,
    onStatus: onStatus,
  ).whenComplete(() => _inFlight = null);

  Future<SpreadsheetConnectionSnapshot> _run({
    bool forceCreate = false,
    void Function(SpreadsheetConnectionStatus)? onStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_idKey);
    try {
      if (!forceCreate && saved != null && saved.isNotEmpty) {
        onStatus?.call(SpreadsheetConnectionStatus.validating);
        try {
          final client = await auth.authorizedClient();
          final metadata = await _drive.getFileMetadata(client, saved);
          client.close();
          if (metadata.trashed == true) {
            return const SpreadsheetConnectionSnapshot(
              SpreadsheetConnectionStatus.missing,
            );
          }
          final complete = await _validateAndRecord(saved, prefs);
          return SpreadsheetConnectionSnapshot(
            SpreadsheetConnectionStatus.ready,
            id: saved,
            setupCompleted: complete,
          );
        } catch (error) {
          final failure = mapGoogleFailure(error);
          if (failure.kind == AppFailureKind.missing) {
            return const SpreadsheetConnectionSnapshot(
              SpreadsheetConnectionStatus.missing,
            );
          }
          if (failure.kind == AppFailureKind.permission) {
            return const SpreadsheetConnectionSnapshot(
              SpreadsheetConnectionStatus.noPermission,
            );
          }
          rethrow;
        }
      }
      final client = await auth.authorizedClient();
      onStatus?.call(SpreadsheetConnectionStatus.validating);
      final found = await _drive.findAppSpreadsheet(client);
      final drive.File? chosen = forceCreate || found.isEmpty
          ? null
          : _choose(found, saved);
      if (chosen != null && chosen.id != null) {
        client.close();
        final complete = await _validateAndRecord(chosen.id!, prefs);
        return SpreadsheetConnectionSnapshot(
          SpreadsheetConnectionStatus.ready,
          id: chosen.id,
          setupCompleted: complete,
          warning: found.length > 1
              ? 'Multiple app-tagged sheets found; using the most recently updated.'
              : null,
        );
      }
      final created = forceCreate
          ? <drive.File>[]
          : await _drive.findAppSpreadsheet(client);
      if (created.isNotEmpty) {
        final file = _choose(created, saved)!;
        client.close();
        await _validateAndRecord(file.id!, prefs);
        return SpreadsheetConnectionSnapshot(
          SpreadsheetConnectionStatus.ready,
          id: file.id,
        );
      }
      try {
        onStatus?.call(SpreadsheetConnectionStatus.creating);
        final file = await _drive.createSpreadsheet(client);
        final id = file.id!;
        await _save(id, prefs);
        final user = auth.account;
        onStatus?.call(SpreadsheetConnectionStatus.validating);
        await _sheets.initialiseWorkbook(
          id,
          client: client,
          displayName: user?.displayName ?? '',
        );
        return SpreadsheetConnectionSnapshot(
          SpreadsheetConnectionStatus.ready,
          id: id,
          setupCompleted: false,
        );
      } catch (error) {
        final failure = mapGoogleFailure(error);
        if (failure.kind != AppFailureKind.timeout &&
            failure.kind != AppFailureKind.network) {
          rethrow;
        }
        final lookupClient = await auth.authorizedClient();
        try {
          final file = _choose(
            await _drive.findAppSpreadsheet(lookupClient),
            saved,
          );
          if (file?.id == null) rethrow;
          await _save(file!.id!, prefs);
          return SpreadsheetConnectionSnapshot(
            SpreadsheetConnectionStatus.needsRepair,
            id: file.id,
            failure: failure,
          );
        } finally {
          lookupClient.close();
        }
      } finally {
        client.close();
      }
    } catch (error) {
      final failure = mapGoogleFailure(error);
      return SpreadsheetConnectionSnapshot(
        failure.kind == AppFailureKind.missing
            ? SpreadsheetConnectionStatus.missing
            : failure.kind == AppFailureKind.permission
            ? SpreadsheetConnectionStatus.noPermission
            : SpreadsheetConnectionStatus.failed,
        failure: failure,
      );
    }
  }

  drive.File? _choose(List<drive.File> files, String? saved) {
    for (final file in files) {
      if (file.id == saved) return file;
    }
    files.sort(
      (a, b) => (b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return files.firstOrNull;
  }

  Future<bool> _validateAndRecord(String id, SharedPreferences prefs) async {
    final client = await auth.authorizedClient();
    try {
      final bool complete = await retryGoogleRequest(
        () => _sheets.validatePhase3Workbook(id, client: client),
      );
      await _save(id, prefs);
      return complete;
    } finally {
      client.close();
    }
  }

  Future<void> _save(String id, SharedPreferences prefs) async {
    await prefs.setString(_idKey, id);
    await prefs.setInt(_schemaKey, 1);
    await prefs.setString(
      _validatedKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> completeSetup(int salaryRupees) async {
    final prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString(_idKey);
    if (id == null) throw StateError('No spreadsheet is connected.');
    final client = await auth.authorizedClient();
    try {
      await _sheets.updateSetupSettings(
        id,
        client: client,
        salaryRupees: salaryRupees,
        displayName: auth.account?.displayName ?? '',
      );
      await prefs.setString(
        _validatedKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    } finally {
      client.close();
    }
  }
}
