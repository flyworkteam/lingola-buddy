import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavState {
  const BottomNavState({this.index = 0});

  final int index;

  BottomNavState copyWith({int? index}) {
    return BottomNavState(index: index ?? this.index);
  }
}

class BottomNavController extends Notifier<BottomNavState> {
  @override
  BottomNavState build() => const BottomNavState();

  void setIndex(int tabIndex) {
    state = state.copyWith(index: tabIndex.clamp(0, 3).toInt());
  }
}

final bottomNavControllerProvider =
    NotifierProvider<BottomNavController, BottomNavState>(
        BottomNavController.new);
