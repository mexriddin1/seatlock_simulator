// by Mehriddin Odilov

sealed class RequestState<T> {
  const RequestState();
}

class RequestStateInitial<T> extends RequestState<T> {
  const RequestStateInitial();
}

class RequestStateLoading<T> extends RequestState<T> {
  final T? oldData;

  const RequestStateLoading({this.oldData});
}

sealed class RequestStateSuccess<T> extends RequestState<T> {
  const RequestStateSuccess();
}

class RequestStateSuccessWithData<T> extends RequestStateSuccess<T> {
  final T data;

  const RequestStateSuccessWithData(this.data);
}

class RequestStateSuccessWithoutData<T> extends RequestStateSuccess<T> {
  const RequestStateSuccessWithoutData();
}

class RequestStateFailed<T> extends RequestState<T> {
  final String errorMessage;

  const RequestStateFailed(this.errorMessage);
}

// extensions for easier handling of RequestState in UI and logic

extension RequestStateXBool<T> on RequestState<T> {
  bool get isSuccess {
    return this is RequestStateSuccessWithData<T> || this is RequestStateSuccessWithoutData;
  }
}

extension RequestStateX on RequestState {
  String? get errorOrNull => this is RequestStateFailed
      ? (this as RequestStateFailed).errorMessage
      : null;
}

extension RequestStateXData<T> on RequestState<T> {
  T? get dataOrNull => this is RequestStateSuccessWithData<T>
      ? (this as RequestStateSuccessWithData<T>).data
      : null;
}

extension RequestStateXWhen<T> on RequestState<T> {
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    return switch (this) {
      RequestStateInitial() => initial(),
      RequestStateLoading() => loading(),
      RequestStateSuccessWithData<T>(:final data) => success(data),
      RequestStateSuccessWithoutData() => success(null as T),
      RequestStateFailed(:final errorMessage) => failure(errorMessage),
    };
  }
}



