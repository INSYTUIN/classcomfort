# ClassComfort

A Flutter app where students rate classroom conditions and administrators see which rooms need attention. Built with Flutter, Firebase Authentication and Cloud Firestore.

## Features

**Students**
- Create an account, verify their email, log in (the app remembers them) and reset a forgotten password
- Browse classrooms and see each room's comfort score
- Rate a room from 1 to 5 stars on six factors: Temperature, Lighting, Noise, Seating, Ventilation, Internet
- Leave optional feedback (up to 500 characters)
- View the classroom ranking and compare rooms factor by factor

**Admins**
- Dashboard with total classrooms, evaluations and the campus average
- Highest and lowest rated rooms, weakest factors, and rooms that need attention
- Recent student feedback
- Add and remove classrooms

## How scoring works

```
Comfort Score = (Temperature + Lighting + Noise + Seating + Ventilation + Internet) / 6
```

| Score | Rating |
|---|---|
| 4.50 – 5.00 | Excellent |
| 3.50 – 4.49 | Good |
| 2.50 – 3.49 | Fair |
| 1.50 – 2.49 | Poor |
| 1.00 – 1.49 | Very Poor |

A factor averaging below 3.0 is flagged as needing attention.

## Project structure

```
lib/
  main.dart                  App start, Firebase setup, login check
  models/models.dart         AppUser, Classroom, Rating
  utils/score_utils.dart     Score calculation and labels
  services/data_service.dart Firebase Auth + Firestore + all calculations
  widgets/widgets.dart       Shared widgets (stars, bars, tiles)
  screens/                   Login, student home, classroom details,
                             rating, ranking, admin dashboard, manage classrooms
firestore.rules              Firestore security rules
```

## Setup

**You need:** Flutter, Android Studio, Node.js, and a Firebase project.

1. Install the dependencies:
   ```
   flutter pub get
   ```
2. Install the Firebase tools and log in:
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
3. Connect the app to your Firebase project (choose **android** and **web**). This creates `lib/firebase_options.dart`:
   ```
   flutterfire configure
   ```
4. In the Firebase console:
   - **Authentication → Sign-in method:** enable **Email/Password**
   - **Firestore Database:** create the database
   - **Firestore Database → Rules:** paste the contents of `firestore.rules` and click **Publish**
5. Run the app:
   ```
   flutter run
   ```

## Creating the first admin

Admins can't be created from inside the app. This keeps students from promoting themselves.

1. Register in the app, open the verification link in your email, and log in once.
2. In the Firebase console, go to **Authentication → Users** and copy your **User UID**.
3. Go to **Firestore Database → Data → users**, open the document with that UID and change `role` from `student` to `admin`.
4. Log out and log back in.

## Optional: restrict sign-ups to your school's email

In `lib/services/data_service.dart`, set:

```dart
static const String allowedEmailDomain = 'yourschool.edu';
```

Then add this line to the `verified()` function in `firestore.rules` so the server enforces it too:

```
&& request.auth.token.email.matches('.*@yourschool[.]edu')
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `channel-error` when signing up | Stop the app, run `flutter clean` and `flutter pub get`, then run again (not hot reload). |
| `this and base files have different roots` (Windows) | The project and the pub cache are on different drives. Add `kotlin.incremental=false` to `android/gradle.properties`, or move the project to the same drive as `C:\Users\<you>\AppData\Local\Pub\Cache`. |
| Lists are empty / `permission-denied` | Publish `firestore.rules`, and make sure you verified your email before logging in. |
| `operation-not-allowed` | Enable Email/Password in Firebase Authentication. |
| Verification or reset email not arriving | Check the spam folder. |

## Not built yet

- Exporting a support report
- Limiting each student to one rating per room per day
