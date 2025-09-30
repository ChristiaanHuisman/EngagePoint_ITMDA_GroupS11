EngagePoint App – Setup Guide

---

Prerequisites

Make sure these are installed:
- Git
- Flutter SDK (stable) - (https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code (with Flutter/Dart plugins)
- Firebase CLI
- Docker Desktop (for microservices)
- Python 3.10+
- Java 21
- Maven
- .NET 8

---

Clone the Repo

git clone https://github.com/ChristiaanHuisman/EngagePoint_ITMDA_GroupS11.git
cd EngagePoint_ITMDA_GroupS11.git

---

Project Structure

EngagePoint_ITMDA_GroupS11/
├─ Frontend/              # Flutter app
├─ Backend/               # Custom microservices
│   ├─ BusinessAnalytics_Service/     # C#
│   ├─ BusinessVerification_Service/  # C#
│   ├─ Recommendation_Service/        # Java
│   ├─ ReviewSentiment_Service/       # Python
│   └─ PostModeration_Service/        # Python
├─ Firebase/              # Firebase configs & rules
├─ Scripts/               # Setup or automation scripts
├─ ProjectDocuments/      # Project documentation
├─ .gitignore             # Files Git should ignore
├─ .gitattributes         # Keeping Git consistnecy across all platforms
├─ LICENSE                # License detials
├─ NOTICE                 # License notice
├─ README.md              # Information about the project details
└─ SETUP.md               # Setup guide to work on and run the project

---

Firebase Config (Safe Copies)

The following files are not in GitHub (ignored by .gitignore).
Get them from a group member:
* app/android/app/google-services.json
* app/ios/Runner/GoogleService-Info.plist
* .env files for microservices
* Android signing keystore (.jks)
* iOS provisioning profiles (if on macOS)

---

Run the Flutter App

cd app/
flutter pub get
flutter run

---

Run Microservices

Each service lives under /services/.

Option A: Run directly

* Python:

  python -m venv venv
  source venv/bin/activate   # (Linux/Mac)
  venv\Scripts\activate      # (Windows)
  pip install -r requirements.txt
  uvicorn app.main:app --reload

* Java:

  mvn clean install
  mvn spring-boot:run

* C#:

  dotnet run

Option B: Run everything with Docker

docker-compose up --build

---

Common Issues

* Missing Firebase configs - get it from a group member.
* Ports already in use - change ports in docker-compose.override.yml.
* Permission errors in Firestore - check you’re logged into Firebase with the correct account.

---

Contribution Workflow

1. Create a new branch:

   git checkout -b feature/(your name)/(feature)

2. Commit your changes:

   git commit -m "Adding feature X"

3. Push branch:

   git push origin feature/(your name)/(feature)

4. Open a Pull Request - reviewed before merging into the main.

---