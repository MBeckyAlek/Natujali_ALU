# Natujali

**Campus incident reporting for African Leadership University (ALU).**

Natujali (Kiswahili word for 'Lets care') lets students report problems on campus, such as a broken tap or a dead projector, and follow each report until it is fixed. Campus staff use the same app to sort, prioritise and resolve reports.

*Our campus, our responsibility.*

---

## Features

### For students
- Report an issue with a category, building (Learning, Enterprise or Social Commons), floor and room, description and optional photo
- Get warned about similar open reports, and tap **"Me too"** instead of reporting the same problem twice
- See staff announcements about known issues before reporting
- Follow each report from **Submitted → Under review → In progress → Resolved**, with staff notes
- Browse and search all campus reports, filtered by category, status, building and month
- Earn **coins** when a report is resolved (10, plus 5 with a photo) and unlock **private badges**

### For staff
- Separate staff sign-in
- Dashboard with workload, overdue reports, trends, and the issues affecting the most students
- Report queue sorted by urgency, with filters for status, priority, overdue, category, team, building, month and dates
- Set a **priority** with a time target (Urgent 4 h, High 1 day, Normal 3 days, Low 1 week)
- Update status, assign a team and leave a note for the student
- Post **announcements** for one building or the whole campus

### Privacy and security
- Only verified ALU email accounts can use the app
- Students never see who filed a report, and badges are private (no leaderboard)
- Firestore security rules enforce every permission on the server
- Sessions end when the app is closed or idle for 15 minutes, unless "Keep me signed in" is ticked

---

## Built with
- [Flutter](https://flutter.dev) (Dart)
- [Riverpod](https://riverpod.dev) for state management
- [Firebase Authentication](https://firebase.google.com/docs/auth) and [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Cloudinary](https://cloudinary.com) for photo storage
- [fl_chart](https://pub.dev/packages/fl_chart) for the staff dashboard chart

---

## Project structure

```
natujali_alu/
├── lib/
│   ├── core/        # Theme, colours, formatters, validators, error messages
│   ├── data/        # Repositories (Firebase versions + fakes for tests)
│   ├── models/      # Report, user, announcement, rewards, badges
│   ├── providers/   # Riverpod providers (auth, session, reports, staff)
│   ├── screens/     # Auth, home, report form, reports, rewards, staff, profile
│   ├── services/    # Cloudinary upload
│   └── widgets/     # Reusable UI pieces
├── assets/images/   # Campus photo
└── test/            # Automated tests
firestore.rules      # Database security rules
```

---

## Getting started

### 1. Requirements
- Flutter SDK (Dart 3.13 or newer)
- Android Studio or Xcode, with an emulator or a device
- A Firebase project and the [Firebase CLI](https://firebase.google.com/docs/cli)
- A Cloudinary account

### 2. Clone and install
```bash
git clone https://github.com/MBeckyAlek/Natujali_ALU.git
cd Natujali_ALU/natujali_alu
flutter pub get
```

### 3. Connect Firebase
The Firebase config files are not in this repo. Create your own:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This creates `lib/firebase_options.dart`, `google-services.json` and `GoogleService-Info.plist`.

In the Firebase console, turn on **Email/Password** sign-in and create a **Firestore** database.

### 4. Deploy the security rules
From the repo root:
```bash
firebase deploy --only firestore:rules
```

### 5. Set up Cloudinary
1. Create an **upload preset** with **Signing mode: Unsigned**.
2. Put your cloud name and preset name in `lib/services/cloudinary_service.dart`.
3. Limit the preset to image files and a sensible maximum size.

### 6. Run the app
```bash
flutter run
```

---

## Staff accounts
Staff can sign in with an **@alueducation.com** email. To make any other ALU account staff:
1. In Firebase Authentication, copy the user's **UID**.
2. In Firestore, create a document `staff/<UID>` with any field (for example `role: staff`).
3. Sign in with **Staff** selected.

---

## Running tests
```bash
cd natujali_alu
flutter test
flutter analyze
```
The tests use fake data, so they don't need Firebase or an internet connection.

---

## Author
**Becky Alek** · African Leadership University
