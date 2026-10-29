import 'package:flutter_bloc/flutter_bloc.dart';

class PrintLanguageCubit extends Cubit<String?> {
  PrintLanguageCubit() : super(null);

  void setLanguage(String language) {
    emit(language);
  }
}
