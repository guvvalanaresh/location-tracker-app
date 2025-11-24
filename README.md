# 📍 Flutter Location Tracker App

A Flutter application that:

- Tracks the user’s live location in the background  
- Stores the path in **Cloud Firestore** (per user, per day, per hour)  
- Shows the route on **Google Maps** with:
  - Green marker = starting point
  - Red marker = ending point
  - Polyline = route  
- Lets you pick:
  - A **date** (via date picker)
  - An **hour** (via slider)  
  and replays the route for that time period.

> ⚠️ All API keys and config files are **kept out of GitHub** and stored locally / securely.

---

## 🧰 Tech Stack

- **Flutter**
- **Dart**
- **Google Maps SDK for Android**
- **Geolocator** (location tracking)
- **Firebase**
  - Cloud Firestore
- **flutter_dotenv** (for local env variables)

---

## 📁 Project Structure (Relevant Parts)

```text
lib/
  main.dart
  screens/
    location_history_screen.dart    # UI with map, date picker, hour slider
  services/
    location_service.dart           # Firestore + location logic

android/
  app/
    src/main/AndroidManifest.xml    # Google Maps API key (meta-data)
  app/google-services.json          # 🔒 NOT COMMITTED (Firebase config)

.env                                 # 🔒 NOT COMMITTED (local env vars, if used)
.gitignore                           # ignores secret files
```

✅ 1. Prerequisites
Make sure you have:


Flutter SDK


Android Studio / VS Code with Flutter & Dart plugins


A Google account


A good internet connection (emulator also needs network)



🚀 2. Clone the Repository
git clone https://github.com/<your-username>/<your-repo-name>.git
cd <your-repo-name>


🔒 3. Git Ignore for Secrets
Make sure your .gitignore contains these lines so you never push secrets:
# Firebase configs
android/app/google-services.json
ios/Runner/GoogleService-Info.plist

# Env file
.env

Commit .gitignore but do NOT commit the files above.

🔥 4. Firebase Setup (Android)


Go to Firebase Console
https://console.firebase.google.com/


Click Add project → create a new project
Example name: location-tracker-app


In the Firebase project:


Click Android icon (Add app)


Android package name must match your app, for example:
com.example.location_tracker_app
(or whatever you set in android/app/src/main/AndroidManifest.xml & build.gradle)




Download the generated file:


google-services.json




Place it in your Flutter project at:
android/app/google-services.json



Make sure google-services.json is in .gitignore (as above).


In android/build.gradle, check you have:
dependencies {
    classpath 'com.google.gms:google-services:4.4.2' // or latest
}



In android/app/build.gradle, at the bottom:
apply plugin: 'com.google.gms.google-services'




📦 5. Enable Firestore & Security Rules


In Firebase Console → Firestore Database


Click Create database


Start in Production mode (recommended)




For now, you can use secure rules for user-specific location history:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Only allow a user to read/write their own location history
    match /users/{userId}/location_history/{date}/points/{point} {
      allow read, write: if request.auth != null
                          && request.auth.uid == userId;
    }
  }
}




🔐 Note: For testing without auth, you may temporarily loosen rules,
but for production always restrict access.


🗺️ 6. Google Maps API Key (Android)

This key cannot be fully hidden inside the app,
so we protect it using restrictions instead of trying to hide it.

6.1 Create API Key


Go to Google Cloud Console:
https://console.cloud.google.com/apis/credentials


Create a new API key.


Enable the required APIs:


Maps SDK for Android


(Optional) Routes API / Geocoding API if you add those later





6.2 Restrict the API Key (VERY IMPORTANT)
In the key’s Restrictions:


Application restriction → Android apps


Add:


Your package name
e.g. com.example.location_tracker_app


Your app’s SHA-1 fingerprint
(you can get it via Android Studio or command line)




API restrictions:


Restrict key to:


Maps SDK for Android


(Any other specific Maps APIs you use)






Now, even if someone decompiles your app and sees the key,
they cannot use it from their own app / server.

6.3 Add Key to AndroidManifest
In: android/app/src/main/AndroidManifest.xml, inside <application>:
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_API_KEY" />


This file is not hidden, but the key is safe thanks to restrictions.


🌱 7. Optional: .env Setup with flutter_dotenv
If you use other secret-like values (e.g., custom APIs, server tokens),
you can keep them in a local .env file.
7.1 Install Package
flutter pub add flutter_dotenv

7.2 Create .env File (Do NOT commit)
CUSTOM_API_BASE_URL=https://your-api.com
SOME_PRIVATE_TOKEN=abc123

7.3 Load in main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

7.4 Read Variables in Code
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrl = dotenv.env['CUSTOM_API_BASE_URL'];

.env stays local only and is ignored by Git.

🧠 8. Location + Firestore Logic (High Level)


LocationService.startTracking(userId):


Subscribes to Geolocator.getPositionStream()


Filters tiny movements (distance < 8 m) so it doesn’t spam Firestore


Saves points to:
users/{userId}/location_history/{yyyy-MM-dd}/points/{autoId}

With fields:


lat (double)


long (double)


timestamp (Firestore Timestamp)


hour (int, 0–23)






LocationService.getLocationsFor(date, hour, userId):


Fetches all points for that date and hour


Orders by timestamp


Returns a List<LatLng> for drawing the route





🗺️ 9. UI: LocationHistoryScreen
Main features:


GoogleMap widget (full screen)


Top bar:


Shows selected date


“Change Date” button → opens date picker




Bottom card:


Hour slider (1–24)


“Play Route” button


Fetches data from Firestore


Adds green start marker, red end marker


Draws polyline for the path


Animates camera over the route (step by step)







▶️ 10. Run the App
From the project root:
flutter pub get
flutter run



Choose an Android emulator or physical device


Make sure:


Emulator has internet


Location is enabled


Firebase project & Maps key are configured





📸 11. Screenshots (Optional)
You can add screenshots later, for example:
## 📸 Screenshots

| Home (Live Map) | History View |
|-----------------|-------------|

![Firebase Connection](https://github.com/user-attachments/assets/ae45c230-c9a6-4449-8ded-2055b9052ef6)
![Getting Maps](https://github.com/user-attachments/assets/564ad938-2800-4ac0-8153-7417b26c3ffc)
![Slider](https://github.com/user-attachments/assets/e18581a4-e8c6-47a5-93ae-25ace5f78fb1)
![Location Saving Output](https://github.com/user-attachments/assets/a62252b2-31cf-4366-9822-ffc7c5df87e4)
![Marker location at that hour](https://github.com/user-attachments/assets/b031b16d-fe96-4b54-94d3-872aa87b4adc)


🔐 12. Summary of Security


google-services.json → local only, ignored by Git


.env → local only, ignored by Git


Google Maps key:


Stored in AndroidManifest.xml


Protected by package name + SHA-1 + API restrictions




Firestore secured using security rules (no open reads/writes)



✅ TODO / Future Enhancements


Add Firebase Authentication (real users instead of testUser)


Show list of days that have data (only enable those dates)


Add speed / distance / duration stats for a route


Export route as GPX / JSON



If you fork or reuse this project, remember:

Never commit raw secrets to GitHub.
Restrict your keys. Secure your database with rules.


---

If you tell me your **actual package name** and whether you plan to add **Firebase Auth**, I can customize the README further to match your exact app.
