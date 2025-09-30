EngagePoint App - SME Engagement Application

---

Table of Contents
1. Overview
2. Features
3. Architecture & Tech Stack
4. Project Structure
5. Installation & Setup
6. Usage
7. Contributors
8. License
9. Future Improvements

---

Overview

Small and medium-sized enterprises (SMEs) often struggle to maintain consistent customer engagement in a mobile-
first digital world. While large companies rely on expensive apps and marketing platforms, SMEs usually lack the
budget and technical expertise.  

EngagePoint bridges this gap by providing an affordable, customizable mobile platform that enables businesses to:
- Build direct connections with subscribers
- Showcase promotions and catalogues
- Send notifications that respect customer preferences and encourages engagement

---

Features

- User Roles
  - Subscribers: follow businesses, view feeds, browse catalogues
  - Businesses: create posts, manage catalogues, view analytics
  - Admins: verify businesses, moderate posts, maintain platform integrity
- Personalized business feed
- Product catalogues (manual upload or import)
- Customizable push notifications (quiet hours, mute businesses, adjust frequency, interactive)
- Review system with sentiment analysis
- Business analytics dashboard
- Admin moderation & verification tools

---

Architecture & Tech Stack

Frontend:
- Flutter (Dart) – Cross-platform mobile app (Android + iOS)  

Backend (Core):
- Firebase Auth – User authentication & role management  
- Firestore – NoSQL database for users, businesses, posts, products, reviews  
- Firebase Cloud Messaging – Push notifications  
- Firebase Cloud Functions – Event-driven logic  
- Firebase Analytics + BigQuery – Engagement tracking  

Backend (Microservices):
- Java – Recommendation engine  
- C# (ASP.NET Core) – Engagement analytics & business verification  
- Python – Sentiment analysis & content moderation  

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

Installation & Setup

Prerequisites
- Flutter SDK (https://docs.flutter.dev/get-started/install)
- Firebase CLI (https://firebase.google.com/docs/cli)
- Docker (https://www.docker.com/) (for microservices)
- .NET 8 SDK (https://dotnet.microsoft.com/download) (for C# services)
- Java 17+ (https://adoptium.net/) (for recommendation engine)
- Python 3.10+ (https://www.python.org/) (for sentiment/moderation services)

See SETUP.md for further detail.

---

Usage

* Subscribers: Follow businesses, browse feeds, engages with notifications
* Businesses: Post promotions, manage catalogues, view analytics
* Admins: Verify businesses, moderate flagged posts

---

Contributors

EngagePoint App Group S11 – Eduvos

* Benjamin Dähn ()
* Kieran Horsford ()
* Nicolaas Huisman (https://github.com/ChristiaanHuisman)
* Luca Karsten ()
* Hayden Muller ()
* Durotimi Samuel ()
* Supervisor: Ntombesisa Mateyisi (ntombesisa.mateyisi@eduvos.com)

---

License

This project is licensed under the Apache License 2.0 – see the LICENSE file for details.

---

Future Improvements

* Web dashboard for businesses
* AI-driven personalized recommendations
* Advanced AI-driven detection for prohibited content
* Advanced fraud detection for fake businesses

---