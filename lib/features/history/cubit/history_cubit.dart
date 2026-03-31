import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/session_model.dart';
import '../../../data/repositories/wattage_repository.dart';

class HistoryState {
  const HistoryState({this.sessions = const <SessionModel>[]});

  final List<SessionModel> sessions;

  HistoryState copyWith({List<SessionModel>? sessions}) {
    return HistoryState(sessions: sessions ?? this.sessions);
  }
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository) : super(const HistoryState());

  final WattageRepository _repository;

  void loadSessions() {
    final sessions = _repository.getSavedSessions().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(state.copyWith(sessions: sessions));
  }

  Future<void> deleteSession(String sessionId) async {
    await _repository.deleteSession(sessionId);
    loadSessions();
  }
}
