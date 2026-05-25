# AAST Smart Parking System - Flutter + Node.js + MongoDB

Full-stack mobile application for AAST Smart Parking System.

---

Email: admin@aast.edu
Password: Admin@1234

## Quick Start

**Terminal 1 — Backend:**

```powershell
cd "c:\Users\Loay khaled\Desktop\mobile app final\backend"
npm run dev
```

Wait for `✅ Connected to MongoDB Atlas`

**Terminal 2 — Flutter App:**

```powershell
cd "c:\Users\Loay khaled\Desktop\mobile app final\flutter_app"
flutter run -d emulator-5554
```

---

## Project Structure

```
aast_parking/
├── backend/                    ← Node.js + Express + MongoDB API
│   ├── server.js
│   ├── .env
│   ├── models/
│   │   ├── User.js
│   │   ├── ParkingSpot.js
│   │   ├── Booking.js
│   │   ├── Notification.js
│   │   └── WaitingList.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── spots.js
│   │   ├── bookings.js
│   │   ├── notifications.js
│   │   ├── waitinglist.js
│   │   └── profile.js
│   └── middleware/
│       └── auth.js
│
└── flutter_app/                ← Flutter Mobile App
    ├── lib/
    │   ├── main.dart           ← App entry + routing
    │   ├── theme/
    │   │   └── app_theme.dart  ← Colors & theme
    │   ├── models/
    │   │   ├── user.dart
    │   │   ├── parking_spot.dart
    │   │   ├── booking.dart
    │   │   └── notification.dart
    │   ├── services/
    │   │   ├── api_constants.dart  ← API URL config
    │   │   ├── api_service.dart    ← HTTP client
    │   │   └── auth_service.dart   ← Auth + storage
    │   ├── screens/            ← 12 screens
    │   └── widgets/            ← Reusable widgets
    └── pubspec.yaml
```

---

## STEP 1 — Set Up the Backend

### Prerequisites

- Node.js v18+ installed
- Internet connection (MongoDB Atlas is cloud-hosted)

### Install & Run

```bash
cd backend
npm install
npm run dev         # Development with auto-reload
# or
npm start           # Production
```

The server starts on **port 3000**.

### MongoDB Atlas

Your database is already configured in `.env`:

```
MONGODB_URI=mongodb+srv://loay:123456Aa%40@cluster0.d142x1d.mongodb.net/aast_parking?appName=Cluster0
```

Parking spots (18 spots across Zones A, B, C) are auto-seeded on first run.

### API Endpoints

| Method | Endpoint                    | Description           |
| ------ | --------------------------- | --------------------- |
| POST   | /api/auth/register          | Register new user     |
| POST   | /api/auth/login             | Login                 |
| GET    | /api/spots                  | Get all parking spots |
| GET    | /api/spots/:spotId          | Get single spot       |
| POST   | /api/bookings               | Create booking        |
| GET    | /api/bookings/my            | Get my bookings       |
| PATCH  | /api/bookings/:id/cancel    | Cancel booking        |
| GET    | /api/notifications          | Get notifications     |
| PATCH  | /api/notifications/read-all | Mark all read         |
| GET    | /api/waitinglist/my         | Check queue status    |
| POST   | /api/waitinglist/join       | Join queue            |
| DELETE | /api/waitinglist/leave      | Leave queue           |
| GET    | /api/profile                | Get profile           |

---

## STEP 2 — Set Up the Flutter App

### Prerequisites

- Flutter SDK 3.x installed (`flutter doctor` should pass)
- Android Studio / VS Code with Flutter extension
- Android Emulator or physical device

### Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### Configure API URL

Open `lib/services/api_constants.dart` and set the correct base URL:

```dart
// Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000/api';

// iOS Simulator:
static const String baseUrl = 'http://localhost:3000/api';

// Physical Android/iOS device (replace with your PC's local IP):
static const String baseUrl = 'http://192.168.1.XXX:3000/api';
```

To find your PC's local IP:

- Windows: run `ipconfig` in CMD → look for IPv4 Address
- macOS/Linux: run `ifconfig` → look for inet

### Add Assets (Optional)

Create these folders and add a logo PNG if you have one:

```
flutter_app/assets/images/    ← add logo.png here
flutter_app/assets/fonts/     ← add Poppins font files here
```

Or remove the font/asset sections from `pubspec.yaml` if not available.

### Run the App

```bash
flutter run
```

---

## Screens

| Screen        | Route          | Description                          |
| ------------- | -------------- | ------------------------------------ |
| Splash        | /splash        | Animated logo, auto-navigates        |
| Login         | /login         | Email + password auth                |
| Register      | /register      | Name, email, password, car plate     |
| Home          | /home          | Dashboard with available spots count |
| Map           | /map           | Grid view of all spots by zone       |
| Spot Details  | /spot-details  | Spot info + pricing                  |
| Booking       | /booking       | Select duration, see price           |
| Confirmation  | /confirmation  | QR code + booking summary            |
| My Bookings   | /bookings      | Active + past bookings               |
| Waiting List  | /waiting-list  | Join/leave queue                     |
| Notifications | /notifications | All user notifications               |
| Profile       | /profile       | User info + stats + logout           |

---

## Business Logic

- **First hour is FREE**, additional hours = 10 EGP/hour
- **Overstay penalty** = 20 EGP/hour
- Spot auto-changes to `available` after booking duration ends
- Notifications are auto-created on booking confirmation and completion
- Waiting list tracks queue position

---

## Tech Stack

| Layer            | Technology            |
| ---------------- | --------------------- |
| Mobile App       | Flutter 3.x + Dart    |
| HTTP Client      | http package          |
| Local Storage    | shared_preferences    |
| QR Codes         | qr_flutter            |
| Backend          | Node.js + Express.js  |
| Database         | MongoDB Atlas (Cloud) |
| Authentication   | JWT (JSON Web Tokens) |
| Password Hashing | bcryptjs              |

---

## Color Scheme

| Color     | Hex     | Usage                        |
| --------- | ------- | ---------------------------- |
| Primary   | #2563EB | Buttons, headers, active nav |
| Available | #10B981 | Available spots              |
| Reserved  | #F59E0B | Reserved spots               |
| Occupied  | #EF4444 | Occupied spots, errors       |
| Success   | #10B981 | Success states               |
