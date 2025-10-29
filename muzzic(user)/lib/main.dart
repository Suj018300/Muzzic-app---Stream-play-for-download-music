import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/theme.dart';
import 'package:client/features/auth/repositories/auth_local_repository.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:client/features/home/view/pages/splash_screen.dart';
import 'package:client/features/offline/offline_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'core/providers/current_song_notifier.dart';
import 'features/auth/view/pages/signup_page.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/offline/connection_checker.dart';
import 'features/home/view/pages/home_page.dart';
import 'features/offline/offline_page.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(SongModelAdapter());
  await Hive.openBox('recentlyPlayed');
  await Hive.openBox<SongModel>('offlineSongs');
  await Hive.openBox('songs');

  final container = ProviderContainer();
  await container.read(authLocalRepositoryProvider).init();
  await container.read(authViewmodelProvider.notifier).initSharedPreferences();
  await container.read(authViewmodelProvider.notifier).getDate();
  container.read(currentUserNotifierProvider.notifier);

  runApp(
    UncontrolledProviderScope(
      container: container,
        child: const MyApp()
    )
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final currentUser = ref.watch(currentUserNotifierProvider);

    return MaterialApp(
        title: 'Muzzic',
        theme: AppTheme.darkThemeMode,
        debugShowCheckedModeBanner: false,
      initialRoute: '/offline',
      routes: {
        '/': (context) => const SplashScreen(),
        '/check': (context) => const ConnectionChecker(),
        '/offline': (context) => const OfflineHomePage(),
        '/online': (context) => currentUser == null ? const SignupPage() : const HomePage(),
      },
    );
  }
}
