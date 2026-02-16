import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seatlock_simulator/core/servis_locator.dart';
import 'package:seatlock_simulator/features/ui/home/bloc/home_bloc.dart';
import 'package:seatlock_simulator/features/ui/home/domain/home_repository.dart';
import 'features/ui/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Seat Reservation System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocProvider(
        create: (context) => HomePageBloc(getIt<HomeRepository>()),
        child: const HomePage(),
      ),
    );
  }
}

