import 'package:conduit/conduit.dart';
import 'package:dart_application_1/model/financialrecord.dart';
import 'package:dart_application_1/model/getmodel.dart';
import 'package:dart_application_1/model/historyrecord.dart';
import '../model/modelresponse.dart';
import '../utilts/appresponse.dart';

class AppFinancialRecordConroller extends ResourceController {
  AppFinancialRecordConroller(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getFinancialRecords(@Bind.body() GetModel options) async {
    try {
      Query<FinancialRecord> records;
      if (options.type == null || options.option == null) {
        records = Query<FinancialRecord>(managedContext);
      } else {
        switch (options.type) {
          case "category":
            {
              records = Query<FinancialRecord>(managedContext)
                ..where((element) => element.category)
                    .contains(options.option ?? '')
                ..where((element) => element.status).equalTo(options.status)
                ..fetchLimit = options.fetch
                ..offset = options.offset;
              break;
            }
          case "name":
            {
              records = Query<FinancialRecord>(managedContext)
                ..where((element) => element.operationName)
                    .contains(options.option ?? "")
                ..where((element) => element.status).equalTo(options.status)
                ..fetchLimit = options.fetch
                ..offset = options.offset;
              break;
            }
          default:
            {
              records = Query<FinancialRecord>(managedContext)
                ..fetchLimit = options.fetch
                ..offset = options.offset;
              break;
            }
        }
      }
      List<FinancialRecord> response = await records.fetch();

      return Response.ok(response);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка получения данных');
    }
  }

  @Operation.get("getRecord")
  Future<Response> getFinancialRecord(@Bind.query("id") int? id) async {
    try {
      final record = Query<FinancialRecord>(managedContext)
        ..where((x) => x.id).equalTo(id);

      var t = await record.fetchOne();

      return Response.ok(t);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка получения данных');
    }
  }

  @Operation.post()
  Future<Response> addFinancialRecord(
      @Bind.body() FinancialRecord record) async {
    try {
      if (record.category == null ||
          record.operationName == null ||
          record.sum == null) {
        return Response.badRequest(
          body: ModelResponse(message: 'Не заполнены обязательные поля'),
        );
      }
      record.date ??= DateTime.now();
      try {
        int id = -1;
        await managedContext.transaction((transaction) async {
          final qCreateRecord = Query<FinancialRecord>(transaction)
            ..values = record;
          final createdRecord = await qCreateRecord.insert();
          id = createdRecord.id!;
        });
        final data = Query<FinancialRecord>(managedContext)
          ..where((x) => x.id).equalTo(id);
        final value = await data.fetchOne();
        await managedContext.transaction((transaction) async {
          final qCreateHistory = Query<HistoryRecord>(transaction)
            ..values.operation = "Добавление записи"
            ..values.date = DateTime.now()
            ..values.record = value;
          await qCreateHistory.insert();
        });
        return Response.ok(
          value,
        );
      } on QueryException catch (e) {
        return Response.serverError(body: ModelResponse(message: e.message));
      }
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка добавления данных');
    }
  }

  @Operation.put()
  Future<Response> updateRecord(
    @Bind.body() FinancialRecord record,
  ) async {
    try {
      if (record.category == null ||
          record.operationName == null ||
          record.sum == null) {
        return Response.badRequest(
          body: ModelResponse(message: 'Не заполнены обязательные поля'),
        );
      }
      record.date ??= DateTime.now();
      final id = record.id;
      record.id = null;
      final qUpdateRecord = Query<FinancialRecord>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..values.category = record.category
        ..values.description = record.description
        ..values.date = record.date
        ..values.status = record.status
        ..values.operationName = record.operationName
        ..values.sum = record.sum;
      await qUpdateRecord.updateOne();
      final findRecord = Query<FinancialRecord>(managedContext)
        ..where((x) => x.id).equalTo(id);
      final value = await findRecord.fetchOne();
      await managedContext.transaction((transaction) async {
        final qCreateHistory = Query<HistoryRecord>(transaction)
          ..values.operation = "Изменение содержимого записи"
          ..values.date = DateTime.now()
          ..values.record = value;
        await qCreateHistory.insert();
      });
      return Response.ok(value);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка обновления данных');
    }
  }

  @Operation.delete()
  Future<Response> deleteRecord(
      @Bind.query("type") int? type, @Bind.query("id") int? id) async {
    try {
      if (type == 0) {
        final qUpdateRecord = Query<FinancialRecord>(managedContext)
          ..where((element) => element.id).equalTo(id);
        await qUpdateRecord.delete();
        return AppResponse.ok(
          message: 'Успешное физическое удаление данных',
        );
      } else if (type == 1) {
        final qUpdateRecord = Query<FinancialRecord>(managedContext)
          ..where((element) => element.id).equalTo(id)
          ..values.status = false;
        var record = await qUpdateRecord.updateOne();
        await managedContext.transaction((transaction) async {
          final qCreateHistory = Query<HistoryRecord>(transaction)
            ..values.operation = "Логическое удаление записи"
            ..values.date = DateTime.now()
            ..values.record = record;
          await qCreateHistory.insert();
        });
        return AppResponse.ok(
          message: 'Успешное логическое удаление данных',
        );
      } else {
        return AppResponse.ok(
          message: 'Неправильный тип операции!',
        );
      }
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка удаления данных');
    }
  }
}
