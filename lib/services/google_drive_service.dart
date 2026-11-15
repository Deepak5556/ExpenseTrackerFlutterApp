import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/google_retry.dart';

const String expenseSpreadsheetName = 'Expense_Tracker_Data';
const String expenseAppTagKey = 'app';
const String expenseAppTagValue = 'expense_journal_budget';

class GoogleDriveService {
  const GoogleDriveService();

  Future<List<drive.File>> findAppSpreadsheet(
    auth.AuthClient client,
  ) => retryGoogleRequest(() async {
    final result = await drive.DriveApi(client).files.list(
      q: "appProperties has { key='$expenseAppTagKey' and value='$expenseAppTagValue' } and mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
      spaces: 'drive',
      pageSize: 100,
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,mimeType,appProperties,modifiedTime,webViewLink)',
    );
    return result.files ?? <drive.File>[];
  });

  Future<drive.File> createSpreadsheet(auth.AuthClient client) async {
    return await drive.DriveApi(client).files
        .create(
          drive.File(
            name: expenseSpreadsheetName,
            mimeType: 'application/vnd.google-apps.spreadsheet',
            appProperties: const <String, String>{
              expenseAppTagKey: expenseAppTagValue,
            },
          ),
          $fields: 'id,name,mimeType,appProperties,modifiedTime,webViewLink',
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<drive.File> getFileMetadata(auth.AuthClient client, String id) =>
      retryGoogleRequest<drive.File>(() async {
        final Object result = await drive.DriveApi(client).files.get(
          id,
          $fields: 'id,name,trashed,owners,modifiedTime,webViewLink,capabilities(canEdit),mimeType,appProperties',
        );
        if (result is drive.File) return result;
        throw StateError('Drive returned unexpected file metadata.');
      });

  Future<void> openInSheetsUrl(String id) async {
    await launchUrl(
      Uri.parse('https://docs.google.com/spreadsheets/d/$id/edit'),
      mode: LaunchMode.externalApplication,
    );
  }
}
