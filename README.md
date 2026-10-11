# Cosmeros

Films, séries et musique dans ton propre univers. Flutter (iOS + Android) avec Supabase en backend.

## Ce qui est dedans

- Inscription / connexion par mail, profil créé automatiquement
- Accueil avec l'orbite animée (tes 6 dernières œuvres) et le fil « Transmissions » des gens que tu suis
- Explorer : recherche de films et séries (TMDB), d'albums (Deezer) et de membres
- Fiche œuvre : note en étoiles, Vu / À voir, critique, favori, et la « Fréquence » (bande originale côté musique)
- Profil : planète avatar, stats, constellation de favoris, 4 thèmes (Nébuleuse, Aurore, Solaire, Void), suivre un membre
- Comptes reliés : Spotify et X via Supabase, Instagram en simple pseudo
- Modération : signaler une critique, bloquer un membre (exigé par Apple)

## 1. Supabase

1. Crée un projet sur supabase.com.
2. SQL Editor : colle `supabase/schema.sql` et exécute.
3. Récupère l'URL du projet et la clé `anon` dans Project Settings > API.

## 2. TMDB

Crée un compte sur themoviedb.org, puis une clé API (v3) dans les paramètres. Deezer ne demande pas de clé.

## 3. Générer les dossiers iOS / Android

Dans ce dossier :

```
flutter create --org com.lamlam --project-name cosmeros .
flutter pub get
```

## 4. Lancer

```
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=ta_cle_anon \
  --dart-define=TMDB_API_KEY=ta_cle_tmdb
```

## 5. Relier Spotify et X (optionnel)

1. Supabase > Authentication > Providers : active Spotify et Twitter avec les identifiants de tes apps développeur (developer.spotify.com, developer.x.com).
2. Authentication > Settings : active « Allow manual linking ».
3. Authentication > URL Configuration : ajoute `io.supabase.cosmeros://login-callback/` dans les Redirect URLs.
4. Android, dans `android/app/src/main/AndroidManifest.xml`, à l'intérieur de l'activity principale :

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.cosmeros" android:host="login-callback" />
</intent-filter>
```

5. iOS, dans `ios/Runner/Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>io.supabase.cosmeros</string></array>
  </dict>
</array>
```

## Pas encore fait

- Suppression de compte depuis l'app (obligatoire sur l'App Store, à faire avec une Edge Function Supabase)
- Commentaires sous les critiques, notifications push, photo de profil
- Page d'admin pour traiter les signalements (pour l'instant : table `reports` dans Supabase)
- Clé TMDB côté serveur : elle est dans l'app pour l'instant, à déplacer dans une Edge Function avant la mise en ligne
