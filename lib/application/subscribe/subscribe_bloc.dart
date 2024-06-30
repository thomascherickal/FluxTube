import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxtube/domain/subscribes/subscribe_services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../../core/operations/math_operations.dart';
import '../../domain/core/failure/main_failure.dart';
import '../../domain/subscribes/models/subscribe.dart';

part 'subscribe_event.dart';
part 'subscribe_state.dart';
part 'subscribe_bloc.freezed.dart';

@injectable
class SubscribeBloc extends Bloc<SubscribeEvent, SubscribeState> {
  final SubscribeServices _subscribeServices;

  SubscribeBloc(this._subscribeServices) : super(SubscribeState.initialize()) {
    // get all subscribed channel list from local storage
    on<GetAllSubscribeList>((event, emit) async {
      emit(state.copyWith(isLoading: true, isError: false, subscribedChannels: []));

      final _result = await _subscribeServices.getSubscriberInfoList();
      final _state = _result.fold(
          (MainFailure f) => state.copyWith(isError: true, isLoading: false),
          (List<Subscribe> resp) =>
              state.copyWith(isLoading: false, subscribedChannels: resp));

      emit(_state);
    });

    // add subscribed channel data to local storage
    on<AddSubscribe>((event, emit) async {
      emit(state.copyWith(isLoading: true, isError: false));

      final _result = await _subscribeServices.addSubscriberInfo(
          subscribeInfo: event.channelInfo);
      final _state = _result.fold(
          (MainFailure f) => state.copyWith(isError: true, isLoading: false),
          (List<Subscribe> resp) =>
              state.copyWith(isLoading: false, subscribedChannels: resp));

      emit(_state);
      add(CheckSubscribeInfo(id: event.channelInfo.id));
    });

    // delete channel data from local storage
    on<DeleteSubscribeInfo>((event, emit) async {
      emit(state.copyWith(isLoading: true, isError: false));

      final _result =
          await _subscribeServices.deleteSubscriberInfo(id: fastHash(event.id));
      final _state = _result.fold(
          (MainFailure f) => state.copyWith(isError: true, isLoading: false),
          (List<Subscribe> resp) =>
              state.copyWith(isLoading: false, subscribedChannels: resp));

      emit(_state);
      add(const GetAllSubscribeList());
      add(CheckSubscribeInfo(id: event.id));
    });

    // check the playing video's channel present in the subscribed list
    on<CheckSubscribeInfo>((event, emit) async {
      emit(state.copyWith(channelInfo: null));

      final _result =
          await _subscribeServices.checkSubscriberInfo(id: event.id);
      final _state = _result.fold(
          (MainFailure f) => state.copyWith(channelInfo: null),
          (Subscribe resp) => state.copyWith(channelInfo: resp));

      emit(_state);
    });
  }
}
