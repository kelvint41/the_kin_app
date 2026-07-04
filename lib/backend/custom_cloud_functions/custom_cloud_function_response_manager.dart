import '/backend/schema/structs/index.dart';

class CheckAndExpireBeaconsCloudFunctionCallResponse {
  CheckAndExpireBeaconsCloudFunctionCallResponse({
    this.errorCode,
    this.succeeded,
    this.jsonBody,
  });
  String? errorCode;
  bool? succeeded;
  dynamic jsonBody;
}
