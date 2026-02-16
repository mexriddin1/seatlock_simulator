import 'package:flutter/material.dart';
import 'package:seatlock_simulator/core/extension/request_state.dart';

Widget requestStateWidget<T>(
  RequestState<T> state,
  Widget Function(T data) onSuccess,
) {
  return switch (state) {
    RequestStateLoading() => const Center(child: Padding(
      padding: EdgeInsets.all(16.0),
      child: CircularProgressIndicator(),
    )),
    RequestStateFailed(errorMessage: var msg) => Center(
      child: Text(msg, style: const TextStyle(color: Colors.red)),
    ),
    RequestStateSuccessWithData<T>(data: var d) => onSuccess(d),
    _ => const SizedBox.shrink(),
  };
}
