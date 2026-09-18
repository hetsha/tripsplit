# TripBook — Documentation Index

This folder is the **single source of truth** for the entire TripBook application. Every product decision, technical contract, and implementation detail lives here. If a question arises during development, the answer is in one of these files.

---

## How This Documentation Is Organized

The files are numbered by layer, from high-level product definition down to implementation specifics. Read top-to-bottom for a full understanding, or jump to a specific file when working on a particular module.

### Layer 1 — Product Definition

| File | Topic | Source of Truth For |
|------|-------|---------------------|
| `00-PROJECT-OVERVIEW.md` | Product vision, architecture, technology, locked decisions | What we are building and why |
| `01-FEATURES.md` | Complete feature inventory with priority and status | Every feature in the application |
| `02-USER-FLOWS.md` | User journey maps, step-by-step flows | How users move through the product |
| `03-SCREEN-SPECIFICATION.md` | Screen inventory, components, states, actions | Every screen in the application |
| `04-DESIGN-SYSTEM.md` | Colors, typography, spacing, components, dark mode | Visual language and UI components |

### Layer 2 — Product Modules

| File | Topic | Source of Truth For |
|------|-------|---------------------|
| `05-AUTHENTICATION.md` | Login, signup, OTP, Google OAuth, sessions | Auth flow and security |
| `06-GROUPS.md` | Group creation, members, roles, settings | Group management |
| `07-EXPENSES.md` | Shared expenses, categories, CRUD operations | Expense lifecycle |
| `08-SPLIT-METHODS.md` | Equal, exact, percentage, shares, item-wise splitting | Split calculation rules |
| `09-SETTLEMENTS.md` | Debt simplification, settlement recording, history | Who owes whom and settlement flow |
| `10-PERSONAL-EXPENSES.md` | Personal expense/income tracking, categories | First-class personal finance module |
| `11-BILLS-AND-REMINDERS.md` | Recurring bills, due dates, priority bills, reminders | Bill management |
| `12-ANALYTICS.md` | Personal, group, overall analytics with formulas | All financial metrics and charts |
| `13-PEOPLE-AND-FRIENDS.md` | People list, friend connections, person details | Social graph |
| `14-REPORTS-IMPORT-EXPORT.md` | PDF, CSV, Excel export, Splitwise import | Reports and data portability |

### Layer 3 — Integrations

| File | Topic | Source of Truth For |
|------|-------|---------------------|
| `15-WHATSAPP-INTEGRATION.md` | WhatsApp transport layer, architecture, message handling | WhatsApp technical architecture |
| `16-WHATSAPP-CONVERSATION-FLOWS.md` | Conversation state machines, guided flows, NLU | WhatsApp user experience |
| `17-AI-AND-LLM.md` | AI responsibilities, hybrid architecture, LLM selection | AI/LLM integration rules |
| `18-RECEIPT-OCR.md` | Camera capture, OCR processing, extraction | Receipt and bill scanning |
| `19-ONLINE-BILL-IMPORT.md` | Vendor integrations, invoice import architecture | Online bill import system |

### Layer 4 — Technical Architecture

| File | Topic | Source of Truth For |
|------|-------|---------------------|
| `20-DATABASE-SCHEMA.md` | Complete database schema, all tables and fields | Database design |
| `21-API-SPECIFICATION.md` | All API endpoints, request/response contracts | Backend API |
| `22-BACKEND-ARCHITECTURE.md` | PHP framework, modules, services, queues | Backend implementation |
| `23-FRONTEND-ARCHITECTURE.md` | Web app architecture, state management, routing | Web frontend |
| `24-FLUTTER-ARCHITECTURE.md` | Flutter app architecture, models, services | Android app |
| `25-NOTIFICATIONS.md` | Push notifications, in-app, WhatsApp notifications | Notification system |
| `26-SECURITY-PRIVACY.md` | Auth security, encryption, privacy, data deletion | Security posture |
| `27-SYNC-OFFLINE.md` | API sync, offline transactions, conflict resolution | Data synchronization |

### Layer 5 — Operations

| File | Topic | Source of Truth For |
|------|-------|---------------------|
| `28-ADMIN-PANEL.md` | Admin dashboard, user/group management, monitoring | Admin tooling |
| `29-SUBSCRIPTION-AND-COST.md` | Cost optimization, self-hosted services, pricing | Cost model |
| `30-TESTING.md` | Test strategy, financial calculation tests | Quality assurance |
| `31-IMPLEMENTATION-ROADMAP.md` | Phased development plan, completion criteria | Development timeline |

### Legacy Documentation

| File | Status |
|------|--------|
| `api.md` | **Legacy** — Partial API docs from original implementation. Superseded by `21-API-SPECIFICATION.md`. Preserved for reference during migration. |

---

## Documentation Rules

1. Every file ends with **Dependencies**, **Related Documents**, and **Open Questions** sections.
2. Financial formulas are explicitly stated — never implied.
3. Edge cases and error states are documented alongside happy paths.
4. Permissions and authorization requirements are specified per operation.
5. Cross-references use relative Markdown links: `[08-SPLIT-METHODS.md](./08-SPLIT-METHODS.md)`.
6. The database schema (`20-DATABASE-SCHEMA.md`) is the canonical reference for all data structures.
7. The API specification (`21-API-SPECIFICATION.md`) is the canonical reference for all backend contracts.
8. No application code is written until documentation is reviewed and locked.

---

## Terminology

| Term | Meaning |
|------|---------|
| **Group** | Product term for a shared expense context (e.g., "Goa Trip", "Flat Expenses") |
| **Trip** | Existing database table name (`trips`). Groups map to trips in the database. |
| **Member** | A user who belongs to a group |
| **Owner** | The user who created a group (role: `owner`) |
| **Admin** | A user with elevated permissions within a group (role: `admin`) |
| **Settlement** | A recorded payment that clears debt between two users |
| **Split** | How an expense is divided among participants |
| **Personal Expense** | An expense tracked for the user only, not shared with any group |
| **CashBook** | The shared money pool tracking within a group |
| **Balance** | Net amount a user owes or is owed within a group |

---

## Financial Invariants

These invariants are enforced by the backend and documented across multiple files:

| # | Invariant | Enforced In |
|---|-----------|-------------|
| F1 | `expense_total = Σ(participant_shares)` | `07-EXPENSES.md`, `08-SPLIT-METHODS.md`, `20-DATABASE-SCHEMA.md` |
| F2 | `settlement = actual recorded transfer` | `09-SETTLEMENTS.md` |
| F3 | `group_balance = paid - responsible + settlements_received - settlements_sent` | `09-SETTLEMENTS.md`, `12-ANALYTICS.md` |
| F4 | All financial operations are idempotent via `client_request_id` | `21-API-SPECIFICATION.md` |
| F5 | Backend is the single source of truth for all financial calculations | All financial docs |

---

## Reading Order for New Developers

1. Start with `00-PROJECT-OVERVIEW.md` to understand what we are building.
2. Read `01-FEATURES.md` for the complete feature list.
3. Read `04-DESIGN-SYSTEM.md` to understand the visual language.
4. Read `20-DATABASE-SCHEMA.md` to understand the data model.
5. Read `21-API-SPECIFICATION.md` to understand the backend contracts.
6. Read your specific module's documentation from Layer 2 or 3.

---

*This documentation is maintained as the single source of truth. Do not implement features without a corresponding specification here. Do not modify application code without updating the relevant documentation first.*
