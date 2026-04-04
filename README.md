<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB" />
  <img src="https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white" alt="Redis" />
  <img src="https://img.shields.io/badge/Google_Gemini-8E75B2?style=for-the-badge&logo=google-bard&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/LangGraph-FF9900?style=for-the-badge&logoColor=white" alt="LangGraph" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase" />
  
  <br />
  <h1>⚡ WattSense (HACKSAGON Project)</h1>
  <p><h3>An AI-Powered Smart Home Appliance Energy Optimization Platform</h3></p>
</div>

<hr />

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Environment Variables](#-environment-variables)
- [Getting Started (Local Setup)](#-getting-started-local-setup)
  - [Prerequisites](#1-prerequisites)
  - [Backend Setup](#2-backend-setup)
  - [Frontend Setup](#3-frontend-setup)
- [Environment Variables](#-environment-variables)
- [Advanced Concepts](#-advanced-concepts)
  - [AI Agent Workflow (LangGraph & Gemini)](#ai-agent-workflow-langgraph--gemini)
  - [Data Model & Telemetry](#data-model--telemetry)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🚀 Overview

**WattSense** (formerly WattWise) is an intelligent, cross-platform mobile application utilizing advanced AI architectures to monitor, analyze, and optimize smart home appliance energy consumption. Built for the **HACKSAGON** project, it leverages robust cloud backends, real-time AI agents powered by LangGraph & Google Gemini, and seamless mobile interfaces to give users a comprehensive, actionable breakdown of their power usage and expenditure.

With recent **Phase 2 Architecture Upgrades**, the platform now features an enterprise-grade backend with advanced Redis caching, a clean layered architecture (Repository & Service patterns), comprehensive security validations, and Tuya IoT platform integration for live hardware telemetry tracking.

---

## ✨ Key Features

- **📊 Dynamic Dashboards:** Real-time data visualization of power consumption and estimated cost breakdowns per appliance.
- **🤖 Artificial Intelligence Pipelines (LangGraph):**
  - **Efficiency Plan Agent:** Generates custom optimization schedules for devices.
  - **Bill Decoder Agent:** Parses external billing and telemetry data to find discrepancies.
  - **Upgrade Advisor Agent:** Recommends energy-efficient device replacements based on current wattage consumption and lifecycle.
- **🌐 Tuya IoT Integration:** Native integration with Tuya Platform for live telemetry and physical device usage tracking.
- **📷 Smart OCR & Reading Integration:** Scan utility bills easily using integrated Firebase ML Kit Text Recognition to auto-populate usage metrics.
- **🔐 Secure Authentication:** Seamless user login via Firebase Auth (Google Sign-in integrated).
- **🌍 Scalable Monorepo:** Structured optimally keeping isolation between Node.js servers, AI python-based pipelines (conceptual execution/state), and the Flutter clients.

---

## 🏗 System Architecture

The application is structured as a **Monorepo** consisting of two main layers:

1. **Frontend (Flutter):** Provides extreme cross-platform performance utilizing caching (Hive/SharedPreferences) and Riverpod State Management for a snappy UI.
2. **Backend (Node.js/Express + MongoDB + Redis):** Employs an n-tier architecture:
   - **Controllers:** HTTP layer handling routing, versioning, and unified response formats.
   - **Services:** Pure business rules, LangGraph/AI pipeline execution, and caching logic.
   - **Repositories:** Data access layer mapping to MongoDB isolated collections.

---

## 💻 Tech Stack

### Frontend
- **Framework:** Flutter / Dart
- **State Management:** Riverpod
- **Local Storage / Caching:** Hive, SharedPreferences
- **Networking:** Dio
- **Auth & Cloud Services:** Firebase Auth, Firebase Storage, Google ML Kit

### Backend
- **Framework:** Node.js, Express.js
- **Database:** MongoDB (Mongoose)
- **Caching & Rate Limiting:** Redis (`ioredis`)
- **IoT Provider:** Tuya API
- **AI / LLMs:** `@google/generative-ai`, `@langchain/google-genai`, `@langchain/langgraph`
- **Validation & Security:** Zod, Helmet
- **Logging:** Winston / Morgan (Structured JSON Logs)

---

## 📂 Project Structure

```text
team_synapse/
├── README.md                 # You are reading this
├── example.env               # Monorepo template for environment configurations
├── package.json              # Monorepo script orchestration
├── backend/                  # NODE.JS MODULAR BACKEND
│   ├── src/
│   │   ├── controllers/      # API entrypoints and versioning
│   │   ├── services/         # Business logic & Cache operations
│   │   ├── repositories/     # Database layer
│   │   ├── models/           # Zod & Mongoose schemas (User, Address, Bill, etc.)
│   │   ├── middlewares/      # Security, Validation, and Rate Limiters
│   │   └── utils/            # Helper functions / Loggers
│   ├── scripts/              # Database migration & auto-cleanup scripts
│   ├── .env.example          # Extended Backend configuration blueprint
│   └── package.json          # Backend dependencies
└── frontend/                 # FLUTTER FRONTEND
    ├── lib/
    │   ├── main.dart         # Flutter execution entry point
    │   ├── core/             # Themes, global utils
    │   ├── features/         # Screen specific architectures
    │   └── providers/        # Riverpod logic & State definitions
    └── pubspec.yaml          # Flutter dependencies
```

---

## 🔐 Environment Variables

Properly configuring the `.env` file is required before startup. We have provided an `example.env` at the root, and a more specific `.env.example` in the backend directory. 

Create a `.env` file inside the `backend/` directory based on the example structure below.

<details>
<summary><b>Click to expand backend/.env configuration</b></summary>

```env
# ── Server ──
PORT=5000
NODE_ENV=development

# ── MongoDB ──
MONGODB_URI=mongodb+srv://<user>:<pass>@cluster.mongodb.net/wattsense

# ── Redis ──
REDIS_URL=redis://localhost:6379

# ── Firebase Admin SDK ──
FIREBASE_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=./config/wattwise-firebase-adminsdk.json

# ── Gemini AI ──
GEMINI_API_KEY=your-gemini-api-key

# ── TUYA IoT Platform Credentials ──
TUYA_CLIENT_ID=your_tuya_access_key_here
TUYA_CLIENT_SECRET=your_tuya_secret_key_here
TUYA_BASE_URL=https://openapi.tuyaeu.com

# ── Security ──
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5000
JWT_SECRET=your-super-secret-jwt-key
```
</details>

---

## 🛠 Getting Started (Local Setup)

Follow these steps to comprehensively run the full-stack system locally.

### 1. Prerequisites
- **Git**
- **Flutter SDK** (v3.10.0+ recommended)
- **Node.js** (v18.0.0+ LTS recommended)
- **MongoDB** (Local instance or external SaaS Cluster)
- **Redis Server** (Local instance running on `localhost:6379`)
- **Google Gemini API Key** ([aistudio.google.com](https://aistudio.google.com/))
- **Tuya Developer Account** ([iot.tuya.com](https://iot.tuya.com) for physical hardware telemetry)

### 2. Backend Setup
1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```
2. **Install dependencies:**
   ```bash
   npm install
   ```
3. **Configure Environment Variables:**
   Copy the `backend/.env.example` to `backend/.env` and securely populate all fields.
   ```bash
   cp .env.example .env
   ```
4. **(Optional) Run Legacy Database Migrations:**
   If migrating from Phase 1, automatically restructure your MongoDB schemas:
   ```bash
   AUTO_CLEANUP=true node scripts/migrateUserData.js
   ```
5. **Start the backend development server:**
   ```bash
   npm run dev
   ```
   *The server validates the Redis connection, connects to MongoDB, and verifies Tuya scopes before mounting the APIs. You can verify system health by hitting `http://localhost:5000/api/v1/health/detailed`.*

### 3. Frontend Setup
1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```
2. **Fetch packages & trigger automated build runners:**
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   *Generation of freezed, JSON serializable, and Riverpod artifacts is required.*
3. **Run the Flutter application:**
   Launch an iOS/Android Simulator or connect a physical device.
   ```bash
   flutter run
   ```

---

## ⚡ Advanced Concepts

### AI Agent Workflow (LangGraph)
WattSense uses graph-oriented multi-step reasoning:
1. **Context Parsing:** Tuya device states and MongoDB history form the vector state.
2. **Graph Traversal:** Prompts route through specialized nodes (`EfficiencyPlanner`, `UpgradeAdvisor`, `BillDecoder`).
3. **Zod Post-Processing:** Final output strictly mapped natively via Validation to structured payloads readable by Flutter.

### Health Probes & Monitoring
The backend actively tracks database IO, memory thresholds, and Redis miss rates. Endpoints such as `/health/ready` check whether container resources are primed prior to serving traffic—meaning WattSense is entirely Docker & Kubernetes compliant out-of-the-box.

---

## 🤝 Contributing

We welcome community contributions! Please make sure to follow the new modular architecture when submitting backend features.

1. Fork the Repository.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'feat: Supported XYZ'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

Ensure linters pass before raising a PR:
```bash
# Frontend Validation
cd frontend && flutter analyze 
# Backend Validation
cd backend && npm run lint
```

---

## 📄 License

This application and related codebase are currently developed for **HACKSAGON Project** boundaries. 

<div align="center">
  <sub>Built with ❤️ by the WattSense (Team Synapse) Developers</sub>
</div>
