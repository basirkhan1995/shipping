part of 'reminder_bloc.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

/// Load only alert reminders
class LoadAlertReminders extends ReminderEvent {
  final int? alert;

  const LoadAlertReminders({this.alert});

  @override
  List<Object?> get props => [alert];
}

/// Add new reminder
class AddReminderEvent extends ReminderEvent {
  final ReminderModel model;

  const AddReminderEvent(this.model);

  @override
  List<Object?> get props => [model];
}

/// Update reminder
class UpdateReminderEvent extends ReminderEvent {
  final ReminderModel model;

  const UpdateReminderEvent(this.model);

  @override
  List<Object?> get props => [model];
}


