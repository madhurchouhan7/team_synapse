<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB" />
  <img src="https://img.shields.io/badge/Google_Gemini-8E75B2?style=for-the-badge&logo=google-bard&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/LangGraph-FF9900?style=for-the-badge&logoColor=white" alt="LangGraph" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase" />
  
  <br />
  <h1>⚡ WattWise (HACKSAGON Project)</h1>
  <p><h3>An AI-Powered Smart Home Appliance Energy Optimization Platform</h3></p>
</div>

<hr />

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started (From Scratch)](#-getting-started-from-scratch)
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

**WattWise** is an intelligent, cross-platform mobile application utilizing advanced AI architectures to monitor, analyze, and optimize smart home appliance energy consumption. Built for the **HACKSAGON** project, it leverages robust cloud backends, real-time AI agents powered by LangGraph & Google Gemini, and seamless mobile interfaces to give users a comprehensive, actionable breakdown of their power usage and expenditure.

With features ranging from real-time dashboard tracking to advanced, proactive efficiency plans and "upgrade advisors," WattWise transforms raw power data into sustainable, cost-saving strategies.

---

## ✨ Key Features

- **📊 Dynamic Dashboards:** Real-time data visualization of power consumption and estimated cost breakdowns per appliance.
- **🤖 Artificial Intelligence Pipelines (LangGraph):**
  - **Efficiency Plan Agent:** Generates custom optimization schedules for devices.
  - **Bill Decoder Agent:** Parses external billing and telemetry data to find discrepancies.
  - **Upgrade Advisor Agent:** Recommends energy-efficient device replacements based on current wattage consumption and lifecycle.
- **📷 Smart OCR & Reading Integration:** Scan utility bills easily using integrated Firebase ML Kit Text Recognition to auto-populate usage metrics.
- **🔐 Secure Authentication:** Seamless user login via Firebase Auth (Google Sign-in integrated).
- **🌍 Scalable Monorepo:** Structured optimally keeping isolation between Node.js servers, AI python-based pipelines (conceptual execution/state), and the Flutter clients.

---

## 🏗 System Architecture

The application is structured as a **Monorepo** consisting of two main layers:

1. **Frontend (Flutter):** Provides extreme cross-platform performance utilizing caching (Hive/SharedPreferences) and Riverpod State Management for a snappy UI.
2. **Backend (Node.js/Express + MongoDB + Redis):** Interacts securely with the frontend and drives the core Logic, processing telemetry, appliance CRUD operations, caching metrics in Redis, and executing the LangGraph/Gemini AI models to return semantic planning.

---

## 💻 Tech Stack

### Frontend
- **Framework:** Flutter / Dart
- **State Management:** Riverpod
- **Local Storage / Caching:** Hive, SharedPreferences
- **Networking:** Dio
- **Auth & Cloud Services:** Firebase Auth, Firebase Storage, Google ML Kit

### Backend
- **Runtime & Web Framework:** Node.js, Express.js
- **Database:** MongoDB (Mongoose)
- **Caching & Job Queue:** Redis (`ioredis`)
- **AI / LLMs:** `@google/generative-ai`, `@langchain/google-genai`, `@langchain/langgraph`
- **Validation:** Zod

---

## 📂 Project Structure

```text
team_synapse/
├── README.md                 # You are reading this
├── package.json              # Monorepo/Root package settings
├── .gitignore                # Global git ignores
├── backend/                  # NODE.JS BACKEND DIRECTORY
│   ├── src/                  # Application source code
│   │   ├── app.js            # Express application entry point
│   │   ├── controllers/      # Route handlers
│   │   ├── routes/           # API Endpoints
│   │   ├── models/           # Mongoose schemas & generic data models
│   │   ├── services/         # LangGraph agents, Firebase logic, etc.
│   │   └── utils/            # Helper functions / Zod schemas
│   ├── .env                  # Backend environments (Not tracked)
│   └── package.json          # Backend dependencies
└── frontend/                 # FLUTTER FRONTEND DIRECTORY
    ├── lib/                  # Dart source code
    │   ├── main.dart         # Flutter execution entry point
    │   ├── core/             # Network constants, themes, global utils
    │   ├── features/         # Screen specific architectures
    │   └── providers/        # Riverpod logic & State definitions
    ├── pubspec.yaml          # Flutter dependencies
    └── assets/               # Splash screens, SVG icons, dummy datasets
```

---

## 🛠 Getting Started (From Scratch)

Follow these steps to set up the development environment successfully. 

### 1. Prerequisites
Ensure you have the following installed on your local machine:
- **Git**
- **Flutter SDK** (v3.10.0+ highly recommended) ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Node.js** (v18.0.0+ LTS recommended) ([Download](https://nodejs.org/))
- **MongoDB Database** (Local instance or MongoDB Atlas cluster URI)
- **Redis Server** (Local instance running on `localhost:6379`)
- **Google Gemini API Key** ([Get it here](https://aistudio.google.com/))

### 2. Backend Setup
1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```
2. **Install node dependencies:**
   ```bash
   npm install
   ```
3. **Configure Environment Variables:**
   Create a `.env` file in the `backend/` root directory (See [Environment Variables](#-environment-variables) below) and insert your credentials.

4. **Start the backend development server:**
   ```bash
   npm run dev
   ```
   *The backend should successfully connect to MongoDB, sync with Redis, and initialize the LangGraph pipelines.*

### 3. Frontend Setup
1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```
2. **Install Flutter packages & auto-generate code:**
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   *The `build_runner` step is crucial for `freezed_annotation` and `json_serializable` class regeneration.*
3. **Run the application:**
   Ensure you have a simulator (iOS/Android) or a physical device connected.
   ```bash
   flutter run
   ```

---

## 🔐 Environment Variables

The system relies on securely configured parameters. You must set up standard `.env` variables depending on the environment.

**`backend/.env` Example:**
```env
# System Configs
PORT=3000
NODE_ENV=development

# Databases
MONGODB_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/wattwise
REDIS_URL=redis://localhost:6379

# AI API Keys
GEMINI_API_KEY=AIzaSyB_Your_Gemini_Key_Here
OPENAI_API_KEY=sk-your-openai-key-here # Optional if fallback is needed

# Firebase Admin configuration
FIREBASE_SERVICE_ACCOUNT_BASE64=your_base64_encoded_firebase_admin_key
```

---

## ⚡ Advanced Concepts

### AI Agent Workflow (LangGraph & Gemini)
WattWise utilizes an autonomous state-graph powered by **LangChain's LangGraph**. Rather than using simple zero-shot prompts, the backend employs multi-step reasoning:
1. **Context Extraction:** User's device constraints and historical consumption telemetry are embedded into Pinecone vector storage.
2. **Graph Traversal:** The input query initializes a graph workflow involving conditional routing. If a user asks for generic efficiency, the node pushes context to the `Efficiency Planner Agent`. If the system detects a heavily degrading hardware component tracking, it redirects to the `Upgrade Advisor`.
3. **Response Assembly:** Post-processing nodes ensure strictly typed JSON outputs (enforced by Zod parsing) to be sent structurally back to the Flutter frontend application.

### Data Model & Telemetry
High traffic bulk appliance updates are validated in real-time gracefully with schemas. When modifying thousands of data points at once, we utilize queued Redis transactions mapping out anomalous device state spikes avoiding sudden 500 server crashes.

---

## 🤝 Contributing

We welcome community contributions to build better AI utilities! To contribute:

1. Fork the Repository.
2. Create a Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'feat: Added some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

Make sure you've passed the existing linters before raising a PR:
```bash
# Frontend
cd frontend && flutter analyze 

# Backend
cd backend && npm run lint
```

---

## 📄 License

This application and related codebase are currently developed for **HACKSAGON Project** boundaries. 

<div align="center">
  <sub>Built with ❤️ by the WattWise (Team Synapse) Developers</sub>
</div>