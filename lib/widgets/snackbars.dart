import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/models/api_error.dart';
import 'error_view.dart';

void showErrorSnackBar(ScaffoldMessengerState messenger, Object error) {
  if (error is ApiException && error.kind == ApiErrorKind.sessionExpired) {
    return;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(ErrorInfo.from(error).message),
        backgroundColor: AppColors.danger,
      ),
    );
}

void showInfoSnackBar(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
