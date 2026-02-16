import 'package:get_it/get_it.dart';
import 'package:seatlock_simulator/features/ui/home/domain/home_repository.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());
}
