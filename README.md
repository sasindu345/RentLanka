# RentLanka

RentLanka is a peer-to-peer (P2P) equipment rental marketplace tailored for Sri Lanka. It enables users to list their tools, cameras, camping gear, and other equipment for rent, while facilitating secure transactions, trusted user verification, and geographic discovery.

---

## 🏗️ Project Architecture & Layout

The project is designed with modularity, scalability, and ease of development in mind:

```text
RentLanka/
├── api/                  # Backend REST API (ASP.NET Core / .NET 10)
│   ├── Controllers/      # Presentation Layer (HTTP controllers)
│   ├── Services/         # Business Logic Layer (Interfaces & Implementations)
│   ├── Models/           # Domain Entities, Requests, and DTOs
│   ├── Data/             # Database context (EF Core)
│   ├── Middleware/       # Global pipelines (Exception handling, etc.)
│   └── Migrations/       # Database schema migrations
├── web/                  # Admin Dashboard (Next.js 15) — ops team only, NOT a public consumer site
├── mobile/               # User App (Flutter) — renters & owners
├── doc/                  # Roadmap, market analysis, and project specifications
└── .github/              # CI/CD Workflows
```

---

## 🛠️ Technology Stack

### Backend API (`/api`)
- **Runtime**: .NET 10 (C#)
- **Web Framework**: ASP.NET Core Web API
- **ORM**: Entity Framework Core 10 (EF Core)
- **Database**: PostgreSQL 18 + **PostGIS** Spatial Extension
- **Spatial Queries**: NetTopologySuite (NTS) for geodetic proximity calculations
- **Authentication**: JWT Bearer Tokens & BCrypt password hashing
- **File Storage**: AWS S3 integration with a local disk upload fallback during development

### Web — Admin Dashboard (`/web`)
- Next.js 15, Tailwind CSS 4
- **Admin-only** internal dashboard: KYC review, disputes, moderation, analytics
- Not a public consumer website — users interact via the mobile app

### Mobile App — User Product (`/mobile`)
- Flutter (Dart) for Android and iOS
- **Primary client** for renters and owners: discover, list, book, pay, chat

---

## 🌟 Core Features (Implemented Backend Phases)

### 🔒 Phase 2: Auth & Identity Verification
- **JWT-Based Authentication**: Secure registration and login endpoints.
- **Email Verification**: Token-based validation with console gateway simulation.
- **SMS Verification**: Phone number validation using mock OTP gateways.
- **KYC Verification**: Submission of National Identity Card (NIC) details.
- **Biometric Check**: Mock facial biometric completion transitioning users to a "Trusted" level.

### 📍 Phase 3: Spatial Listings & Proximity Search
- **Point Geography**: Geographic points indexed with SRID 4326 (`geography` type in PostgreSQL).
- **Proximity Search**: Discovery searches querying listings in real-world meters (`ST_Distance` under the hood) from specified user coordinates (`lat`/`lon`).
- **Discovery Engine**: Search filtering by textual matches (titles/descriptions), categories, and district bounds.

---

## 🚀 Getting Started

### Prerequisites
1. **.NET 10 SDK**
2. **PostgreSQL 18** (or compatible version)
3. **PostGIS Spatial Extension** (`brew install postgis` on macOS)

### Backend Local Setup

1. **Configure Connection Strings**
   Update the PostgreSQL connection string in `api/appsettings.json`:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Host=localhost;Database=rentlanka_db;Username=YOUR_USERNAME;Password=YOUR_PASSWORD"
   }
   ```

2. **Run Migrations**
   Generate/apply database schemas and verify the `postgis` extension:
   ```bash
   dotnet ef database update --project api/RentLanka.Api.csproj
   ```

3. **Start the API Server**
   From the repository root:
   ```bash
   dotnet run --project api/RentLanka.Api.csproj
   ```
   Or if you are inside the `api` folder:
   ```bash
   dotnet run
   ```
   The API will start listening locally (defaulting to `http://localhost:5021`).

### Frontend Admin Dashboard Setup

1. **Install Dependencies**
   From the repository root:
   ```bash
   cd web
   npm install
   ```

2. **Start Development Server**
   ```bash
   npm run dev
   ```
   The dashboard will start listening locally (defaulting to `http://localhost:3000` or `http://localhost:3001`).

### Default Admin Credentials

For logging into the admin web panel:
* **Email:** `admin@rentlanka.lk`
* **Password:** `RentLankaAdmin123!`

---

## 🔌 API Endpoints Reference

### Authentication (`/api/auth`)
* `POST /api/auth/register` - Registers a new user.
* `POST /api/auth/login` - Authenticates a user and returns a JWT token.

### Verification (`/api/verification`)
* `POST /api/verification/send-email-token` - Sends email validation token.
* `POST /api/verification/verify-email` - Submits token for email validation.
* `POST /api/verification/send-sms-otp` - Submits phone and sends OTP code.
* `POST /api/verification/verify-sms-otp` - Submits SMS code.
* `POST /api/verification/nic` - Submits NIC details & document URL.
* `POST /api/verification/face` - Completes face verification.

### Listings (`/api/listings`)
* `POST /api/listings` *(Authorized)* - Submits a new rental item with location coordinates.
* `GET /api/listings/{id}` - Retrieves listing details (includes owner summary).
* `GET /api/listings/search` - Searches listings with pagination, price filters, and spatial distance.
* `GET /api/listings/mine` *(Authorized)* - Returns the current user's listings.
* `PUT /api/listings/{id}` *(Authorized)* - Updates a listing (owner only).
* `DELETE /api/listings/{id}` *(Authorized)* - Soft-deletes a listing (owner only).
* `PATCH /api/listings/{id}/pause` *(Authorized)* - Toggles listing pause state.

### Users (`/api/users`)
* `GET /api/users/me` *(Authorized)* - Returns the authenticated user's profile.
* `PATCH /api/users/me` *(Authorized)* - Updates name or phone number.
* `GET /api/users/{id}` - Returns a public user profile.

### Wishlist (`/api/wishlist`)
* `GET /api/wishlist` *(Authorized)* - Returns paginated saved listings.
* `POST /api/wishlist/{listingId}` *(Authorized)* - Saves a listing to wishlist.
* `DELETE /api/wishlist/{listingId}` *(Authorized)* - Removes a listing from wishlist.

### Files (`/api/file`)
* `POST /api/file/avatar` *(Authorized)* - Upload user avatar.
* `POST /api/file/listing-image` *(Authorized)* - Upload a listing photo.
