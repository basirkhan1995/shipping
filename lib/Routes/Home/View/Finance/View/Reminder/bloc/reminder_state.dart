part of 'reminder_bloc.dart';

class ReminderState extends Equatable {
  final List<ReminderModel> reminders;
  final bool loading;
  final String? error;
  final String? successMsg;

  const ReminderState({
    this.reminders = const [],
    this.loading = false,
    this.error,
    this.successMsg,
  });

  ReminderState copyWith({
    List<ReminderModel>? reminders,
    bool? loading,
    String? error,
    String? successMsg,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      loading: loading ?? this.loading,
      error: error,
      successMsg: successMsg,
    );
  }

  @override
  List<Object?> get props => [reminders, loading, error, successMsg];
}

class ReminderInitial extends ReminderState {}
