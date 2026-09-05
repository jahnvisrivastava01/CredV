# 💳 CredV — Smart Credit Card Management App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Mobile%20App-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/FastAPI-Backend-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
  <img src="https://img.shields.io/badge/Firebase-Google%20Auth-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
  <img src="https://img.shields.io/badge/Render-Deployed-46E3B7?style=for-the-badge&logo=render&logoColor=white"/>
</p>

<p align="center">
  <b>A full-stack fintech application for managing credit cards, transactions, spending insights, and rewards.</b>
</p>

<p align="center">
  Built with Flutter • FastAPI • Supabase • Firebase
</p>

---

## ✨ About CredV

**CredV** is a modern full-stack credit card management application designed to provide users with a centralized platform to manage their credit card information, track transactions, monitor spending, and explore financial insights.

The application supports both traditional authentication and Google Sign-In, providing personalized experiences for new and existing users.

New users can register and set up their credit card details, while existing users can securely log in and access their personalized financial dashboard.

---

# 🚀 Features

## 🔐 Authentication

- User Registration
- Secure Email & Password Login
- Google Sign-In with Firebase Authentication
- Forgot Password / Reset Password
- Password hashing using BCrypt
- Multi-user authentication
- User session management

---

## 💳 Credit Card Management

- Add credit card details
- Bank name management
- Last 4 card digits
- Credit limit tracking
- Outstanding balance tracking
- Available credit calculation
- Credit utilization tracking
- Credit score display
- Edit card information

---

## 💸 Transaction Management

- Add transactions
- Edit transactions
- Delete transactions
- Categorize expenses
- Track transaction history
- Reward coins calculation

### Supported Categories

```text
🍔 Food
🛍️ Shopping
✈️ Travel
📄 Bills
🎬 Entertainment
📦 Other
````

---

## 📊 Spending Analytics

* Spending overview
* Category-based expense tracking
* Credit utilization insights
* Transaction analysis
* Personalized financial dashboard

---

## 🎁 Rewards

* Rewards tracking
* Reward coins
* Credit card benefits interface

---

## 👤 Profile Management

* View user profile
* Update name
* Update email
* Account information management
* Secure logout

---

# 🏗️ Architecture

```text
                    ┌─────────────────────┐
                    │                     │
                    │    Flutter App      │
                    │      CredV          │
                    │                     │
                    └──────────┬──────────┘
                               │
                               │ REST APIs
                               ▼
                    ┌─────────────────────┐
                    │                     │
                    │      FastAPI        │
                    │      Backend        │
                    │                     │
                    └──────────┬──────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼

        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │   Supabase   │ │   Firebase   │ │    Render    │
        │ PostgreSQL DB│ │ Google Auth  │ │   Deployment │
        └──────────────┘ └──────────────┘ └──────────────┘
```

---

# 🔄 User Flow

## 🆕 New User

```text
Register
   │
   ▼
Create Account
   │
   ▼
Authentication
   │
   ▼
Card Setup
   │
   ▼
Enter Credit Card Details
   │
   ▼
Personalized Dashboard
```

## 🔑 Existing User

```text
Login
   │
   ▼
Authentication
   │
   ▼
Fetch User Data
   │
   ▼
Dashboard
```

## 🌐 Google Sign-In

```text
Continue with Google
        │
        ▼
Firebase Authentication
        │
        ▼
Google Account Verification
        │
        ▼
CredV Backend
        │
        ▼
Check User in Database
        │
   ┌────┴─────┐
   │          │
 New User   Existing User
   │          │
   ▼          ▼
Card Setup  Dashboard
```

---

# 🛠️ Tech Stack

### 📱 Frontend

| Technology      | Purpose                           |
| --------------- | --------------------------------- |
| Flutter         | Cross-platform mobile development |
| Dart            | Application programming           |
| Material Design | UI components                     |
| HTTP            | REST API integration              |

### ⚙️ Backend

| Technology | Purpose             |
| ---------- | ------------------- |
| FastAPI    | Backend REST API    |
| Python     | Backend development |
| SQLAlchemy | ORM                 |
| Uvicorn    | ASGI Server         |
| BCrypt     | Password hashing    |

### 🗄️ Database

| Technology | Purpose                |
| ---------- | ---------------------- |
| Supabase   | Cloud backend platform |
| PostgreSQL | Relational database    |

### 🔐 Authentication

| Technology              | Purpose               |
| ----------------------- | --------------------- |
| Firebase Authentication | User authentication   |
| Google Sign-In          | Google authentication |
| BCrypt                  | Password security     |

### ☁️ Deployment

| Technology | Purpose            |
| ---------- | ------------------ |
| Render     | Backend deployment |
| Supabase   | Cloud database     |

---

# 📂 Project Structure

```text
CredV
│
├── lib
│   │
│   ├── models
│   │   ├── card_model.dart
│   │   └── transaction.dart
│   │
│   ├── screens
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── card_setup_screen.dart
│   │   ├── card_details_screen.dart
│   │   ├── transactions_screen.dart
│   │   ├── analytics_screen.dart
│   │   ├── rewards_screen.dart
│   │   └── profile_screen.dart
│   │
│   ├── services
│   │   └── api_service.dart
│   │
│   ├── utils
│   │   └── user_session.dart
│   │
│   └── main.dart
│
├── backend
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   └── requirements.txt
│
├── android
├── assets
├── pubspec.yaml
└── README.md
```

---

# 🔌 API Features

### Authentication

```text
POST   /api/register
POST   /api/login
POST   /api/auth/google
PUT    /api/forgot-password
```

### Profile

```text
GET    /api/profile/{user_id}
PUT    /api/profile/{user_id}
```

### Credit Card

```text
GET    /api/card/{user_id}
PUT    /api/card/{user_id}
```

### Transactions

```text
GET    /api/transactions/{user_id}
POST   /api/transactions/{user_id}
PUT    /api/transactions/{transaction_id}
DELETE /api/transactions/{transaction_id}
```

---

# ⚙️ Installation

## 1️⃣ Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/CredV.git
```

```bash
cd CredV
```

---

## 2️⃣ Install Flutter Dependencies

```bash
flutter pub get
```

---

## 3️⃣ Firebase Setup

Add your Firebase configuration file:

```text
android/app/google-services.json
```

Enable:

* Email/Password Authentication
* Google Sign-In

---

## 4️⃣ Configure Backend

Navigate to the backend directory:

```bash
cd backend
```

Create a virtual environment:

```bash
python -m venv venv
```

Activate it:

### Windows

```bash
venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

---

## 5️⃣ Environment Variables

Configure your database connection:

```env
DATABASE_URL=your_supabase_postgresql_connection_string
```

---

## 6️⃣ Run Backend

```bash
uvicorn main:app --reload
```

---

## 7️⃣ Run Flutter App

```bash
flutter run
```

---

# 🌟 Key Highlights

* 📱 Full-stack mobile application
* 🔐 Multi-user authentication system
* 🌐 Google Sign-In integration
* 🔥 Firebase Authentication
* 🗄️ Supabase PostgreSQL database
* ⚡ FastAPI REST backend
* 💳 Personalized credit card setup
* 💸 Transaction CRUD operations
* 📊 Spending analytics
* 🎁 Rewards system
* ☁️ Cloud-deployed backend
* 🎨 Modern fintech-inspired UI

---

# 🔮 Future Enhancements

* [ ] Multiple credit card support
* [ ] Bill payment reminders
* [ ] Push notifications
* [ ] AI-powered spending insights
* [ ] Monthly expense reports
* [ ] Budget planning
* [ ] Biometric authentication
* [ ] Dark/Light theme support
* [ ] Real-time transaction updates
* [ ] Credit score improvement suggestions

---

# 👩‍💻 Developer

**Jahnvi Srivastava**

---

<p align="center">

### 💙 Built with Flutter, FastAPI & Supabase

**CredV — Manage Your Credit Smarter**

</p>
```

