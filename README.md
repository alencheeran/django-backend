# 📈 ApexTrade — Full-Stack Paper Trading & Portfolio Platform

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?logo=python&logoColor=white)
![Django](https://img.shields.io/badge/Django-6.0-092E20?logo=django&logoColor=white)
![DRF](https://img.shields.io/badge/DRF-3.17-red?logo=django&logoColor=white)
![Channels](https://img.shields.io/badge/Channels-ASGI%20WebSockets-green)
![Flutter](https://img.shields.io/badge/Flutter-3.8%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart&logoColor=white)
![Swagger](https://img.shields.io/badge/Swagger-OpenAPI%20Docs-85EA2D?logo=swagger&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-purple)

**ApexTrade** is a high-performance, real-time paper trading and portfolio simulation system. It features an asynchronous **Django REST Framework + Django Channels (ASGI)** backend integrated with **Yahoo Finance** and continuous **WebSocket price streaming**, accompanied by a cross-platform **Flutter** client (Android, iOS, Web, and Desktop) styled with an ultramodern slate-dark theme.

---

## 📑 Table of Contents

- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Repository Structure](#-repository-structure)
- [Backend Installation & Setup](#-backend-installation--setup)
- [Frontend Installation & Setup](#-frontend-installation--setup)
- [API Reference](#-api-reference)
  - [Authentication](#authentication)
  - [Market Data](#market-data)
  - [Portfolio & Orders](#portfolio--orders)
  - [Watchlist & Leaderboard](#watchlist--leaderboard)
  - [Wallet Simulation](#wallet-simulation)
  - [Interactive Documentation](#interactive-documentation)
- [WebSocket Streaming Protocol](#-websocket-streaming-protocol)
- [Trading Engine Rules](#-trading-engine-rules)
- [Configuration & Environment](#-configuration--environment)
- [Contributing & License](#-contributing--license)

---

## 🚀 Key Features

### 📊 Real-Time Market & Interactive Candlesticks
- **Live Stock Feeds**: Fetches real-time price quotes, historical candles, daily highs/lows, and volume for NIFTY 50 and Indian equities via `yfinance`.
- **Low-Latency WebSockets**: Bi-directional asynchronous WebSocket streaming via Django Channels (`/ws/stocks/`) providing real-time live price ticks.
- **Interactive Candlestick Charts**: Multi-interval/multi-period historical candlestick chart rendering powered by Flutter's `candlesticks` engine.

### 💼 Paper Trading Engine & Order Execution
- **Realistic Trading Rules**: Enforces National Stock Exchange (NSE) trading hours (Monday–Friday, 9:15 AM – 3:30 PM IST).
- **Instant Buy & Sell Execution**: Validates buying power against available virtual balance and calculates volume-weighted average price (VWAP) on acquisitions.
- **Realized & Unrealized P&L**: Automatically calculates realized profit/loss on liquidations and real-time mark-to-market unrealized P&L on open positions.

### 📂 Comprehensive Portfolio Management
- **Holdings Breakdown**: View active positions, quantities, average cost, live market value, absolute returns, and percentage returns.
- **Portfolio Summary & History**: Dynamic summary tracking total asset value, cash balance, 1-day change, overall ROI, and 5-day historical performance equity curve.
- **Ledger Audit Trail**: Complete immutable transaction history for all orders (`BUY`, `SELL`, `DEP`, `WIT`).

### 🏆 Gamified Social Trading & Tools
- **Global Leaderboard**: Public ranking of top traders sorted by overall portfolio returns and net worth.
- **Watchlist**: Real-time personal watchlist toggle with live price movement tracking.
- **Virtual Banking**: Simulated deposits and withdrawals for seamless wallet capital management.

### 🎨 Cross-Platform Flutter Interface
- **State Management**: Built with Flutter Riverpod for reactive, robust state handling.
- **Custom UI / UX**: Electric Indigo & Emerald Green accents over a sleek deep-slate dark palette (`#0B0F1E` / `#131B2E`), interactive custom donut chart painters, and haptic feedback.
- **Network Configurator**: In-app runtime configuration to dynamically point the client to local networks, emulators, or production tunnels.

---

## 🏗 System Architecture

```mermaid
flowchart TD
    subgraph Client ["Flutter Client (Android / iOS / Web / Desktop)"]
        UI[UI Views: Dashboard, Trade, Holdings, Leaderboard]
        Riverpod[Riverpod State Providers]
        WSChannel[WebSocket Channel Client]
        HTTPClient[HTTP ApiClient with JWT Refresh]
    end

    subgraph Backend ["Django ASGI Application"]
        Daphne[Daphne / ASGI Server]
        Auth[SimpleJWT Authentication]
        
        subgraph REST_API ["Django REST Framework"]
            UsersApp["/api/users/ (Auth & Balances)"]
            MarketApp["/api/stocks/ (Nifty 50 & Charts)"]
            PortfolioApp["/api/portfolio/ (Orders & Holdings)"]
        end
        
        subgraph Channels ["Django Channels"]
            Consumer[StockPriceConsumer (ws/stocks/)]
            InMemoryLayer[InMemory Channel Layer]
        end
    end

    subgraph External ["External Services & Storage"]
        YFinance[Yahoo Finance API (yfinance)]
        DB[(SQLite / PostgreSQL)]
    end

    UI --> Riverpod
    Riverpod --> HTTPClient
    Riverpod --> WSChannel

    HTTPClient -->|REST Requests + JWT| Daphne
    WSChannel -->|WebSocket Ticks| Daphne

    Daphne --> REST_API
    Daphne --> Channels

    REST_API --> DB
    REST_API --> YFinance
    Channels --> YFinance
```

---

## 🛠 Tech Stack

| Layer | Technologies |
| :--- | :--- |
| **Backend Framework** | [Django 6.0](https://www.djangoproject.com/) & [Django REST Framework](https://www.django-rest-framework.org/) |
| **Real-time / ASGI** | [Django Channels](https://channels.readthedocs.io/), [Daphne](https://github.com/django/daphne), `asgiref` |
| **Authentication** | [SimpleJWT](https://django-rest-framework-simplejwt.readthedocs.io/) (JSON Web Tokens) |
| **Market Data** | [yfinance](https://github.com/ranaroussi/yfinance), `pandas`, `numpy` |
| **API Documentation** | [drf-yasg](https://drf-yasg.readthedocs.io/) (Swagger UI & ReDoc OpenAPI) |
| **Database** | SQLite (Development) / PostgreSQL-ready |
| **Frontend Framework** | [Flutter 3.8+](https://flutter.dev/) (Dart 3.8+) |
| **Frontend State** | [Flutter Riverpod](https://riverpod.dev/) |
| **Charts & Visuals** | `candlesticks`, Custom Painter (Donut Chart) |
| **Persistence & Network** | `shared_preferences`, `http`, `web_socket_channel` |

---

## 📁 Repository Structure

```text
Trading backend/
├── manage.py                     # Django management script
├── requirements.txt              # Backend Python dependencies
├── db.sqlite3                    # Local SQLite database
│
├── config/                       # Core Django Project Configuration
│   ├── settings.py               # Settings, apps, middleware, JWT & channels config
│   ├── urls.py                   # Root URL declarations & Swagger endpoint
│   ├── asgi.py                   # ASGI application entrypoint for Channels & Daphne
│   └── wsgi.py                   # WSGI fallback entrypoint
│
├── users/                        # User Management & Authentication
│   ├── models.py                 # Custom User model (balances, initial capital)
│   ├── views.py                  # User registration endpoint
│   ├── serializers.py            # User registration serializers
│   └── urls.py                   # Routes for /api/users/
│
├── market/                       # Market Data & Real-Time Feeds
│   ├── consumers.py              # AsyncJsonWebsocketConsumer (StockPriceConsumer)
│   ├── routing.py                # WebSocket URL routing (ws/stocks/)
│   ├── views.py                  # Nifty50 list view & historical candle chart view
│   └── urls.py                   # Routes for /api/stocks/
│
├── portfolio/                    # Orders, Positions & Trading Engine
│   ├── models.py                 # Portfolio, Transaction, Watchlist models
│   ├── views.py                  # Buy, Sell, Holdings, Summary, History, Leaderboard
│   ├── serializers.py            # Portfolio serializers
│   ├── transaction_serializer.py # Transaction audit serializers
│   └── urls.py                   # Routes for /api/portfolio/
│
├── trading/                      # Trading domain models & configurations
│   └── models.py                 # Core trading abstractions
│
└── frontend/                     # Flutter Cross-Platform Application
    ├── pubspec.yaml              # Flutter dependencies and assets
    └── lib/
        ├── main.dart             # App entrypoint, ProviderScope & dark theme
        ├── models/               # Dart data models (Holdings, Orders, Candles)
        ├── providers/            # Riverpod providers (Auth, API, Market, Portfolio)
        │   ├── api_client.dart   # Authenticated HTTP client with token refresh
        │   ├── auth_provider.dart# Login/Register state machine
        │   ├── market_provider.dart # Market WebSocket & ticker state
        │   ├── portfolio_provider.dart # Portfolio, holdings & balance state
        │   └── settings_provider.dart  # Dynamic API & WS URL configuration
        └── views/                # Presentation views
            ├── auth_view.dart        # Login & Signup screen
            ├── dashboard_view.dart   # Main dashboard with stats & asset allocation
            ├── trade_view.dart       # Interactive trade terminal & candlestick chart
            ├── holdings_view.dart    # User positions & unrealized P&L
            ├── watchlist_view.dart   # Stock watchlist
            ├── leaderboard_view.dart # Global trader performance rankings
            ├── transactions_view.dart# Audit ledger of all operations
            ├── deposit_view.dart     # Virtual wallet fund deposits
            ├── withdrawal_view.dart  # Virtual wallet fund withdrawals
            └── settings_view.dart    # Backend IP/port settings modal
```

---

## 💻 Backend Installation & Setup

### Prerequisites
- **Python 3.10+**
- **Git**

### 1. Clone the Repository
```bash
git clone https://github.com/alencheeran/django-backend.git
cd django-backend
```

### 2. Set Up Virtual Environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Run Migrations & Setup Database
```bash
python manage.py makemigrations
python manage.py migrate
```

### 5. Create Superuser (Admin Access)
```bash
python manage.py createsuperuser
```

### 6. Run the ASGI Development Server
For real-time WebSocket support, start Django via ASGI:
```bash
python manage.py runserver 0.0.0.0:8000
```
*Or run explicitly via Daphne:*
```bash
daphne -b 0.0.0.0 -p 8000 config.asgi:application
```

---

## 📱 Frontend Installation & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`3.8.0` or higher)
- Chrome (for Web) or Android Studio / Xcode (for Mobile)

### 1. Navigate to the Frontend Directory
```bash
cd frontend
```

### 2. Install Packages
```bash
flutter pub get
```

### 3. Configure the Backend URL
- By default, the application connects to `http://127.0.0.1:8000` (or local IP configured in `lib/providers/settings_provider.dart`).
- When running on physical Android devices, set your machine's LAN IP (e.g. `http://192.168.1.X:8000`) or use the in-app **Settings View** to change the endpoint anytime.

### 4. Run the Application
```bash
# Run on Web (Chrome)
flutter run -d chrome

# Run on connected Mobile Emulator / Device
flutter run
```

---

## 📡 API Reference

All protected endpoints require an `Authorization` header containing the JWT Bearer token:
```http
Authorization: Bearer <your_access_token>
```

### Authentication

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/users/register/` | Register new user with default ₹1,00,000 balance | No |
| `POST` | `/api/token/` | Obtain JWT access and refresh token pair | No |
| `POST` | `/api/token/refresh/` | Refresh expired access token | No |

#### Register Request Body:
```json
{
  "username": "trader_alice",
  "email": "alice@example.com",
  "password": "StrongPassword123"
}
```

### Market Data

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/stocks/nifty50/` | Fetch live quotes & daily changes for top NIFTY 50 stocks | Yes |
| `GET` | `/api/stocks/<symbol>/chart/` | Historical candlestick data (`?period=1mo&interval=1d`) | Yes |

### Portfolio & Orders

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/portfolio/` | List all user portfolio positions | Yes |
| `GET` | `/api/portfolio/summary/` | Summary metrics: total value, available cash, 1-day & total ROI | Yes |
| `GET` | `/api/portfolio/holdings/` | Mark-to-market holdings with live profit/loss | Yes |
| `GET` | `/api/portfolio/history/` | 5-day historical portfolio value timeline | Yes |
| `POST` | `/api/portfolio/buy/` | Execute market buy order (validates market hours & funds) | Yes |
| `POST` | `/api/portfolio/sell/` | Execute market sell order (realizes profit/loss) | Yes |
| `GET` | `/api/portfolio/transactions/` | Immutable log of all transactions | Yes |

#### Buy Order Payload:
```json
{
  "stock_symbol": "RELIANCE.NS",
  "quantity": 10,
  "price": 2450.00
}
```

#### Sell Order Payload:
```json
{
  "stock_symbol": "RELIANCE.NS",
  "quantity": 5
}
```

### Watchlist & Leaderboard

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/portfolio/watchlist/` | Get user watchlist with live pricing & % change | Yes |
| `POST` | `/api/portfolio/watchlist/toggle/` | Add/remove stock symbol from user watchlist | Yes |
| `GET` | `/api/portfolio/leaderboard/` | Leaderboard ranked by portfolio ROI & net worth | Yes |

### Wallet Simulation

| Method | Endpoint | Description | Auth Required |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/portfolio/deposit/` | Add virtual capital to user balance | Yes |
| `POST` | `/api/portfolio/withdraw/` | Withdraw funds from user balance | Yes |

#### Deposit Payload:
```json
{
  "amount": 50000,
  "bank_name": "Bank of Baroda"
}
```

### Interactive Documentation
Interactive API docs are available out-of-the-box:
- **Swagger UI**: `http://localhost:8000/swagger/`
- Supports Bearer token authorization directly from the browser.

---

## ⚡ WebSocket Streaming Protocol

### Connection URL
```text
ws://localhost:8000/ws/stocks/
```

### 1. Subscribe to Symbols
Send a JSON payload to subscribe to live price ticks:
```json
{
  "action": "subscribe",
  "symbols": ["RELIANCE.NS", "TCS.NS", "INFY.NS"]
}
```

### 2. Unsubscribe
```json
{
  "action": "unsubscribe",
  "symbols": ["TCS.NS"]
}
```

### 3. Server Tick Broadcast
The server broadcasts periodic price updates for active subscriptions:
```json
{
  "type": "price_update",
  "symbol": "RELIANCE.NS",
  "price": 2453.20,
  "change": 3.20,
  "change_percentage": 0.13,
  "timestamp": "2026-10-16T11:00:00Z"
}
```

---

## ⚖️ Trading Engine Rules

1. **Market Hours Verification**:
   - Trading orders (`BUY` and `SELL`) are restricted to standard NSE market trading hours: **Monday to Friday, 9:15 AM to 3:30 PM IST (Asia/Kolkata)**.
   - Weekend and after-hours execution attempts return HTTP 400 with a descriptive schedule error.
2. **Volume-Weighted Average Price (VWAP)**:
   - Successive purchases dynamically recompute the holding's average buy price:
     $$\text{New Avg Price} = \frac{(\text{Current Qty} \times \text{Current Avg}) + (\text{New Qty} \times \text{Execution Price})}{\text{Current Qty} + \text{New Qty}}$$
3. **Realized Profit Tracking**:
   - Liquidating shares computes realized profit/loss immediately against current market prices and credits the user's cash balance.
4. **Initial Capital**:
   - Every newly registered account starts with an initial virtual credit of **₹1,00,000**.

---

## ⚙️ Configuration & Environment

In `config/settings.py`, customize key environment options:

- `SECRET_KEY`: Set your production secret key.
- `DEBUG`: Toggle debug mode (`True` for local development, `False` for production).
- `ALLOWED_HOSTS`: Add client domain names, IP addresses, or tunnels (e.g. `ngrok`).
- `CORS_ALLOW_ALL_ORIGINS`: Set to `True` for cross-origin local Flutter clients.
- `AUTH_USER_MODEL`: Custom user model set to `'users.User'`.

---

## 🤝 Contributing & License

Contributions, bug reports, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Distributed under the **MIT License**.
