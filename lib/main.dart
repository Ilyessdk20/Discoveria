import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

import 'providers/ville_provider.dart';
import 'providers/lieu_provider.dart';
import 'providers/commentaire_provider.dart';
import 'providers/preferences_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lieu_detail_screen.dart';
import 'screens/lieu_form_screen.dart';
import 'screens/map_screen.dart';

void main() {
  debugPrint('🔵 Démarrage de l\'application ExplorezVotreVille...');
  
  // Initialiser SQLite UNIQUEMENT pour Desktop (pas Web)
  if (!kIsWeb) {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        debugPrint('🔵 Plateforme Desktop détectée : ${Platform.operatingSystem}');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        debugPrint('✅ SQLite FFI initialisé avec succès');
      } else {
        debugPrint('📱 Plateforme Mobile détectée');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur initialisation SQLite : $e');
    }
  } else {
    debugPrint('🌐 Plateforme WEB détectée - SQLite non disponible');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Construction de MyApp');
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🔵 Création VilleProvider');
            return VilleProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🔵 Création LieuProvider');
            return LieuProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🔵 Création CommentaireProvider');
            return CommentaireProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('🔵 Création PreferencesProvider');
            return PreferencesProvider()..chargerPreferences();
          },
        ),
      ],
      child: const MyAppContent(),
    );
  }
}

class MyAppContent extends StatelessWidget {
  const MyAppContent({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Construction de MyAppContent');
    
    final prefsProvider = Provider.of<PreferencesProvider>(context);

    return MaterialApp(
      title: 'ExplorezVotreVille',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: prefsProvider.modeSombre ? ThemeMode.dark : ThemeMode.light,
      
      initialRoute: '/',
      routes: {
        '/': (context) {
          debugPrint('🔵 Navigation vers WelcomeScreen');
          return const WelcomeScreen();
        },
        '/home': (context) {
          debugPrint('🔵 Navigation vers HomeScreen');
          return const HomeScreen();
        },
      },
      
      onGenerateRoute: (settings) {
        debugPrint('🔵 Génération de route : ${settings.name}');
        
        if (settings.name == '/lieu-detail') {
          final lieu = settings.arguments;
          if (lieu == null) {
            debugPrint('❌ Erreur : pas d\'argument pour lieu-detail');
            return null;
          }
          return MaterialPageRoute(
            builder: (context) => LieuDetailScreen(lieu: lieu as dynamic),
          );
        }
        
        if (settings.name == '/lieu-form') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args == null || !args.containsKey('villeId')) {
            debugPrint('❌ Erreur : villeId manquant pour lieu-form');
            return null;
          }
          return MaterialPageRoute(
            builder: (context) => LieuFormScreen(
              villeId: args['villeId'] as int,
              lieu: args['lieu'],
            ),
          );
        }
        
        if (settings.name == '/map') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            debugPrint('❌ Erreur : pas d\'arguments pour map');
            return null;
          }
          return MaterialPageRoute(
            builder: (context) => MapScreen(
              ville: args['ville'],
              lieux: args['lieux'],
            ),
          );
        }
        
        debugPrint('❌ Route inconnue : ${settings.name}');
        return null;
      },
      
      onUnknownRoute: (settings) {
        debugPrint('❌ Route inconnue : ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: const Center(
              child: Text('Page introuvable'),
            ),
          ),
        );
      },
    );
  }
}