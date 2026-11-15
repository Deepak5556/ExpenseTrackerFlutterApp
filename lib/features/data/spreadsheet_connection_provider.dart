import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/auth_controller.dart';
import '../../repositories/spreadsheet_connection_repository.dart';

final Provider<SpreadsheetConnectionRepository>
spreadsheetConnectionRepositoryProvider = Provider(
  (Ref ref) =>
      SpreadsheetConnectionRepository(ref.read(googleAuthServiceProvider)),
);
final NotifierProvider<
  SpreadsheetConnectionController,
  SpreadsheetConnectionSnapshot
>
spreadsheetConnectionProvider = NotifierProvider(
  SpreadsheetConnectionController.new,
);

class SpreadsheetConnectionController
    extends Notifier<SpreadsheetConnectionSnapshot> {
  late final SpreadsheetConnectionRepository _repository;
  @override
  SpreadsheetConnectionSnapshot build() {
    _repository = ref.read(spreadsheetConnectionRepositoryProvider);
    return const SpreadsheetConnectionSnapshot(
      SpreadsheetConnectionStatus.noSpreadsheet,
    );
  }

  Future<void> connectOrCreate() async {
    state = const SpreadsheetConnectionSnapshot(
      SpreadsheetConnectionStatus.noSpreadsheet,
    );
    state = await _repository.connectOrCreate(
      onStatus: (status) {
        state = SpreadsheetConnectionSnapshot(status);
      },
    );
  }

  Future<void> createNew() async {
    state = const SpreadsheetConnectionSnapshot(
      SpreadsheetConnectionStatus.creating,
    );
    state = await _repository.createNew(
      onStatus: (status) {
        state = SpreadsheetConnectionSnapshot(status);
      },
    );
  }

  Future<void> completeSetup(int salaryMinor) async {
    await _repository.completeSetup(salaryMinor);
    state = SpreadsheetConnectionSnapshot(
      SpreadsheetConnectionStatus.ready,
      id: state.id,
      setupCompleted: true,
    );
  }
}
