# 📍 Flutter Location Tracker App

A Flutter application that:

- Tracks the user’s live location in the background  
- Stores the path in **Cloud Firestore** (per user, per day, per hour)  
- Displays the route on **Google Maps** with:
  - 🟢 Green marker → starting point  
  - 🔴 Red marker → ending point  
  - 📍 Polyline → full route  
- Lets you pick a **date** & **hour** to replay the route for that time period  
- Keeps all API keys and config files **private** (not uploaded to GitHub)

---

## 🧰 Tech Stack

- **Flutter**
- **Dart**
- **Google Maps SDK for Android**
- **Geolocator**
- **Firebase Firestore**
- **flutter_dotenv** (for local env variables)

---

## 📁 Project Structure

```
lib/
  main.dart
  screens/
    location_history_screen.dart
  services/
    location_service.dart

android/
  app/
    src/main/AndroidManifest.xml
  app/google-services.json   # ignored

.env                         # ignored
.gitignore
```

---

## ✅ 1. Prerequisites

- Flutter SDK  
- Android Studio / VS Code  
- Google account  
- Emulator with internet enabled  

---

## 🚀 2. Clone Repository

```
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
```

---

## 🔒 3. Protect Secrets

`.gitignore` must contain:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
.env
```

---

## 🔥 4. Firebase Setup (Android)

### Steps:

1. Go to Firebase Console → Create Project  
2. Add Android App  
3. Package name example: `com.example.location_tracker_app`  
4. Download `google-services.json`  
5. Place it here:

```
android/app/google-services.json
```

### Gradle Setup

**android/build.gradle**
```
classpath 'com.google.gms:google-services:4.4.2'
```

**android/app/build.gradle**
```
apply plugin: 'com.google.gms.google-services'
```

---

## 📦 5. Firestore Setup

Enable Firestore → Production Mode

### Recommended Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId}/location_history/{date}/points/{point} {
      allow read, write: if request.auth != null
                          && request.auth.uid == userId;
    }
  }
}
```

---

## 🗺️ 6. Google Maps API Key

### Steps:

1. Go to  
   https://console.cloud.google.com/apis/credentials  
2. Create API Key  
3. Enable:
   - Maps SDK for Android  
4. Restrict Key:
   - Android Apps  
   - Add package name  
   - Add SHA-1 fingerprint  
   - Restrict APIs to: *Maps SDK for Android*

### Add to Manifest

`android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_API_KEY" />
```

---

## 🌱 7. Optional ENV (.env) Setup

Install:

```
flutter pub add flutter_dotenv
```

Create `.env`:

```
SECRET_API_URL=https://example.com
TOKEN=abc123
```

Load in `main.dart`:

```dart
await dotenv.load(fileName: ".env");
```

Use:

```dart
dotenv.env['SECRET_API_URL']
```

---

## 🧠 8. Firestore + Location Logic

Data saved at:

```
users/{userId}/location_history/{yyyy-MM-dd}/points/{autoId}
```

Fields:

- lat  
- long  
- timestamp  
- hour  

`getLocationsFor(..)` returns a `List<LatLng>` for drawing route.

---

## 🗺️ 9. UI: LocationHistoryScreen

Features:

- Full Google Map  
- Date picker  
- Hour slider  
- “Play Route” button  
- Draws:
  - start & end markers  
  - polyline  
  - camera animation  

---

## ▶️ 10. Run App

```
flutter pub get
flutter run
```

Requirements:

- Emulator internet ON  
- Location ON  
- Firebase configured  

---

## 📸 Screenshots

Use HTML to resize:

```html
<img src="IMAGE_URL" width="350" />
```

Examples:

![Database Connection Successful](<img src="https://github.com/user-attachments/assets/ae45c230-c9a6-4449-8ded-2055b9052ef6" width="300" />)
![Google Maps](<img src="https://github.com/user-attachments/assets/564ad938-2800-4ac0-8153-7417b26c3ffc" width="300" />)
![Slider](<img src="https://github.com/user-attachments/assets/e18581a4-e8c6-47a5-93ae-25ace5f78fb1" width="300" />)
![Locations Saving](<img src="https://github.com/user-attachments/assets/a62252b2-31cf-4366-9822-ffc7c5df87e4" width="300" />)
![Marking our location](<img src="https://github.com/user-attachments/assets/b031b16d-fe96-4b54-94d3-872aa87b4adc" width="300" />)

---

## 🔐 12. Security Summary

- `google-services.json` → ignored  
- `.env` → ignored  
- Maps API key → restricted by:
  - package name  
  - SHA-1  
  - API whitelist  
- Firestore → secure rules  

---

## 📝 Future Enhancements

- Firebase Auth (real users)  
- Only enable dates with history  
- Speed, distance & duration stats  
- Export route to GPX/JSON  
- Background service for tracking  

---
