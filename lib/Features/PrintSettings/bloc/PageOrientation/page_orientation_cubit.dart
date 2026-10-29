import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/widgets.dart';

class PageOrientationCubit extends Cubit<PageOrientation> {
  PageOrientationCubit() : super(PageOrientation.portrait);

  void setOrientation(PageOrientation orientation) {
    emit(orientation);
  }
}
