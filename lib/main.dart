import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/firebase_options.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/notes/bloc/notes_bloc.dart';
import 'features/notes/bloc/notes_event.dart';
import 'features/notes/screens/notes_list_screen.dart';
import 'features/notes/services/connectivity_service.dart';
import 'features/notes/services/local_database.dart';
import 'features/notes/services/sync_queue_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalDatabase.init();
  await ConnectivityService.init();
  await SyncQueueManager.init();
  runApp(const OfflineSyncApp());
}

class OfflineSyncApp extends StatelessWidget {
  const OfflineSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotesBloc()..add(const LoadNotes()),
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const NotesListScreen(),
      ),
    );
  }
}
