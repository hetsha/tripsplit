
# TripSplit AI Expense Chat — Repository Analysis & Implementation Specification

**Repository:** 'hetsha/tripsplit'  
**Branch:** 'main'  
**Status:** Implementation specification  
**Decision:** Remove WhatsApp expense integration and replace it with an in-app AI Expense Chat.

## 1. Executive decision

TripSplit should remove the planned WhatsApp expense parser and introduce an in-app AI chat where users can enter expenses naturally.

Example:

~~~text
I paid ₹1200 for dinner with Raj and Dev, split equally.
~~~

The LLM converts this into structured data. TripSplit's backend then validates the data, resolves real trip members/categories, calculates the split using the existing financial engine, shows a confirmation, and only then creates the transaction.

**Critical rule:** the LLM must never directly INSERT a financial transaction.

~~~text
Flutter AI Chat
  -> PHP /api/ai-chat.php
  -> LLM
  -> structured JSON
  -> PHP validation/member resolution/split validation
  -> confirmation
  -> existing expense creation flow
  -> transactions + expense_splits + transaction_payers
~~~

## 2. Current repository analysis

The current repository is already suitable for this feature.

| Layer | Current implementation | Decision |
|---|---|---|
| Mobile | Flutter / Dart | Keep |
| API | Core PHP 8+ | Keep |
| Database | MySQL | Keep |
| HTTP | Dio | Keep |
| State | Provider | Keep |
| OCR | Google ML Kit | Keep |
| Admin | Core PHP | Extend |
| AI | Planned only | Implement |
| WhatsApp | Planned only | Remove |

### Existing important files

~~~text
api/expenses.php
api/transactions.php
includes/calculations.php
includes/functions.php
includes/validation.php

tripbook_flutter/lib/core/api/api_client.dart
tripbook_flutter/lib/core/api/api_endpoints.dart
tripbook_flutter/lib/services/expense_service.dart
tripbook_flutter/lib/services/auth_service.dart
tripbook_flutter/lib/features/expenses/add_expense_screen.dart
tripbook_flutter/lib/features/dashboard/dashboard_screen.dart

admin/settings.php
admin/integrations.php
admin/includes/auth.php
admin/includes/db.php
admin/includes/permissions.php

sql/schema.sql
sql/seed.sql
sql/migration_auth.sql
~~~

The existing ExpenseService already sends the final expense payload to the existing expense API. The AI feature should reuse that path rather than creating a second transaction engine.

## 3. No programming-language change is required

Do **not** add Python, Node.js, Express, Laravel, React, or another backend only for AI.

Keep:

~~~text
Flutter / Dart
PHP 8+
MySQL
Dio
Provider
~~~

The first implementation should call the LLM from PHP using server-side HTTPS/cURL. The current repository does not have Composer-based AI infrastructure, so adding a large SDK is unnecessary for the MVP.

A separate Python/Node AI service can be introduced later only if scale or model orchestration requires it.

## 4. LLM integration

Use a server-side AI client:

~~~text
includes/ai/
  AiClient.php
  ExpenseChatParser.php
  AiPrompt.php
  AiValidator.php
~~~

The current OpenAI integration direction should use the **Responses API**, not the retired Assistants API. OpenAI's current documentation says the Assistants API was sunset on August 26, 2026 and new integrations should use Responses API.

Source: https://platform.openai.com/docs/

The API key must stay on the server:

~~~text
OPENAI_API_KEY
OPENAI_MODEL
~~~

Never put the key in Flutter, GitHub, app settings as plain text, or the mobile APK.

## 5. New backend API

Add:

~~~text
api/ai-chat.php
~~~

Initial actions:

~~~text
POST action=message
POST action=confirm
POST action=cancel
GET  action=history
GET  action=conversation
~~~

A request should contain only user-controlled conversation/message information:

~~~json
{
  "conversation_id": 123,
  "trip_id": 12,
  "message": "I paid 1200 for dinner with Raj and Dev"
}
~~~

The backend must derive the authenticated user and verify trip membership. Do not trust user_id supplied by Flutter.

## 6. Structured AI output

The model should return a strict structured contract similar to:

~~~json
{
  "intent": "create_expense",
  "confidence": 0.96,
  "amount": 1200,
  "currency": "INR",
  "description": "Dinner",
  "category": "Food & Drinks",
  "payer": {
    "type": "current_user",
    "name": null
  },
  "participants": [
    {"name": "current_user"},
    {"name": "Raj"},
    {"name": "Dev"}
  ],
  "split": {
    "type": "equal",
    "values": null
  },
  "transaction_date": null,
  "payment_method": null,
  "notes": null,
  "missing_fields": [],
  "requires_confirmation": true
}
~~~

The model should return names, not database IDs. PHP resolves names against the actual trip.

The backend must reject malformed or incomplete structured output.

## 7. Supported intents

Initial supported intents:

~~~text
create_expense
query_balance
query_expenses
help
unknown
~~~

Later:

~~~text
update_expense
delete_expense
add_income
record_settlement
~~~

Do not expose destructive update/delete actions to the LLM in the first release.

## 8. Expense understanding

The AI should understand:

### Amount

~~~text
1200
₹1200
₹ 1,200
Rs 1200
1.2k
1200 rupees
~~~

### Payer

~~~text
I paid
Het paid
Raj paid
paid by Raj
Raj ne diya
Maine diya
~~~

### Split

~~~text
split equally
split among everyone
split between me Raj Dev
Raj 500, Het 300
Raj 50%, Het 50%
Raj 2 shares, Het 1 share
~~~

### Categories

Use the existing database categories. The model can suggest a category name, but PHP must resolve it to an actual category record.

Examples:

~~~text
dinner -> Food & Drinks
hotel -> Hotel & Stay
uber -> Local Transport
petrol -> Fuel
movie -> Activities
shopping -> Shopping
~~~

## 9. Language support

No new language library is required for the first version.

The LLM should support:

- English
- Hinglish
- Gujarati Roman
- mixed English/Hindi/Gujarati

Examples:

~~~text
Maine 1500 dinner ke diye Raj aur Dev ke saath split kar do

Hu 1500 dinner na aapya Raj ane Dev sathe equal split karo
~~~

The repository should contain a test dataset for all three language groups.

## 10. Member resolution

Member resolution must happen on the server.

Example:

~~~text
Raj
 -> trip_members
 -> Raj Shah / user_id 24
~~~

If multiple members match:

~~~text
Raj
  -> Raj Shah
  -> Raj Patel
~~~

do not guess. Ask the user to select the correct member.

The AI must never invent a member who is not in the active trip.

## 11. Confirmation is mandatory

For the first release, every financial write requires user confirmation, even when confidence is high.

Example:

~~~text
I understood:

Dinner             ₹1,200
Paid by            You
Split between      You, Raj, Dev
Split method       Equal
Category           Food & Drinks

[ Edit ] [ Add Expense ]
~~~

Only the Add Expense action should create the transaction.

## 12. Financial source of truth

The existing transaction engine remains authoritative.

Reuse:

~~~text
api/expenses.php
includes/validation.php
includes/calculations.php
expense_splits
transaction_payers
~~~

Do not create an AI-specific financial INSERT implementation.

The final AI command should become the same payload used by the existing ExpenseService.

Example:

~~~json
{
  "amount": 1200,
  "description": "Dinner",
  "category_id": 1,
  "paid_by": 5,
  "payment_method": "upi",
  "is_personal": false,
  "client_request_id": "ai-unique-request-id",
  "splits": [
    {"user_id": 5, "amount": 400},
    {"user_id": 8, "amount": 400},
    {"user_id": 9, "amount": 400}
  ],
  "trip_id": 12
}
~~~

This keeps balances and settlement calculations identical to manual entry.

## 13. Database changes

The existing transaction tables do not need to change for AI-created expenses.

Add dedicated AI history/observability tables.

### ai_conversations

~~~sql
CREATE TABLE ai_conversations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    trip_id INT UNSIGNED NULL,
    title VARCHAR(150) NULL,
    status ENUM('active','archived') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ai_conv_user (user_id),
    INDEX idx_ai_conv_trip (trip_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
~~~

### ai_messages

~~~sql
CREATE TABLE ai_messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    role ENUM('user','assistant','system') NOT NULL,
    message_text MEDIUMTEXT NOT NULL,
    structured_output JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ai_messages_conversation (conversation_id),
    INDEX idx_ai_messages_user (user_id),
    FOREIGN KEY (conversation_id) REFERENCES ai_conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
~~~

### ai_parse_events

~~~sql
CREATE TABLE ai_parse_events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    conversation_id INT UNSIGNED NULL,
    message_id BIGINT UNSIGNED NULL,
    user_id INT UNSIGNED NULL,
    trip_id INT UNSIGNED NULL,
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(100) NOT NULL,
    prompt_version VARCHAR(50) NULL,
    input_hash CHAR(64) NULL,
    input_tokens INT UNSIGNED NULL,
    output_tokens INT UNSIGNED NULL,
    total_tokens INT UNSIGNED NULL,
    latency_ms INT UNSIGNED NULL,
    intent VARCHAR(50) NULL,
    confidence DECIMAL(5,4) NULL,
    parse_status ENUM('success','needs_review','rejected','error') NOT NULL DEFAULT 'success',
    validation_status ENUM('not_checked','valid','invalid') NOT NULL DEFAULT 'not_checked',
    created_transaction_id INT UNSIGNED NULL,
    error_code VARCHAR(100) NULL,
    error_message TEXT NULL,
    raw_output JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ai_events_user (user_id),
    INDEX idx_ai_events_trip (trip_id),
    INDEX idx_ai_events_status (parse_status),
    INDEX idx_ai_events_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
~~~

For fresh installations, add these tables to sql/schema.sql.

For existing installations, create:

~~~text
sql/migration_ai_chat.sql
~~~

Do not create these tables on every API request. The repository currently has runtime schema helpers for older features; the AI feature should use an explicit migration.

## 14. AI test data

The user-provided testing-data idea should become a first-class repository asset.

Add:

~~~text
tests/ai_expense_chat/
  english.json
  hinglish.json
  gujarati_roman.json
  split_methods.json
  multiple_payers.json
  corrections.json
  ambiguous.json
  invalid.json
  edge_cases.json
  run.php
~~~

Example:

~~~json
{
  "id": "en-001",
  "input": "I paid 1200 for dinner with Raj and Dev, split equally",
  "expected": {
    "intent": "create_expense",
    "amount": 1200,
    "payer": "current_user",
    "participants": ["current_user", "Raj", "Dev"],
    "split_type": "equal"
  }
}
~~~

Initial target:

~~~text
English:          100+
Hinglish:         100+
Gujarati Roman:   100+
Equal split:       50+
Exact split:       50+
Percentage:        50+
Shares:            50+
Multiple payer:    50+
Ambiguous:        100+
~~~

## 15. Automated evaluation

Create:

~~~text
php tests/ai_expense_chat/run.php
~~~

The runner should:

1. Load test JSON.
2. Send each case through the parser.
3. Normalize the result.
4. Compare against expected fields.
5. Print pass/fail.
6. Print category-level accuracy.
7. Save a machine-readable report.

Metrics:

~~~text
Intent Accuracy
Amount Accuracy
Payer Accuracy
Participant Accuracy
Split Accuracy
Category Accuracy
Overall Parse Accuracy
False Auto-Creation Rate
Clarification Rate
~~~

The most important safety metric is **False Auto-Creation Rate**.

Target:

~~~text
0%
~~~

The system should prefer asking a clarification question over guessing a financial value.

## 16. Backend validation

After the LLM response:

1. Validate JSON/schema.
2. Validate amount.
3. Validate payer.
4. Resolve members.
5. Validate category.
6. Validate split.
7. Validate trip membership.
8. Calculate server-side confidence.
9. Return a confirmation object.
10. Only confirmed commands reach expense creation.

### Split invariants

Exact:

~~~text
sum(split amounts) == transaction amount
~~~

Percentage:

~~~text
sum(percentages) == 100
~~~

Shares:

~~~text
calculated shares == transaction amount
~~~

Multiple payer:

~~~text
sum(payer amounts) == transaction amount
~~~

## 17. Confidence

Do not blindly trust the model's confidence.

Calculate a server-side score, for example:

~~~text
Amount valid              +25
Payer resolved            +20
Participants resolved     +20
Split valid               +20
Category resolved          +5
Intent clear              +10
------------------------------
Maximum                   100
~~~

Suggested behavior:

~~~text
90–100 -> confirmation
70–89  -> clarification/confirmation
<70    -> clarification
invalid -> reject
~~~

Confirmation remains mandatory for all financial writes in the MVP.

## 18. Conversation corrections

Example:

~~~text
User: Actually it was 1500, not 1200.
~~~

The assistant should modify the pending structured command, not create a second expense.

The final confirmation should contain only the corrected command.

## 19. Flutter changes

Add:

~~~text
tripbook_flutter/lib/features/ai_chat/
  ai_chat_screen.dart
  models/
    ai_message.dart
    ai_expense_preview.dart
  widgets/
    chat_message_bubble.dart
    expense_preview_card.dart
    chat_input.dart

tripbook_flutter/lib/services/ai_chat_service.dart
~~~

Update:

~~~text
tripbook_flutter/lib/core/api/api_endpoints.dart
tripbook_flutter/lib/main.dart
tripbook_flutter/lib/features/home/all_groups_home_screen.dart
tripbook_flutter/lib/features/dashboard/dashboard_screen.dart
~~~

Add to ApiEndpoints:

~~~dart
static const String aiChat = 'ai-chat.php';
~~~

No mandatory new Flutter package is required. Existing Dio, Provider and Flutter Material widgets are enough.

Optional later package:

~~~text
flutter_markdown
~~~

only if rich assistant responses are required.

## 20. Chat UI

Recommended:

~~~text
AI Expense Assistant
Trip: Current Trip

🤖 Hi! Tell me an expense.

You:
I paid ₹1200 dinner with Raj and Dev

🤖 I understood:
┌─────────────────────────┐
│ Dinner            ₹1200 │
│ Paid by You             │
│ You, Raj, Dev           │
│ Equal split             │
└─────────────────────────┘

[ Edit ] [ Add Expense ]

Type an expense...                 ➤
~~~

The UI should support:

~~~text
idle
sending
thinking
parsed
needs_clarification
needs_confirmation
creating
created
error
~~~

## 21. Clarification flow

Example:

~~~text
User: Raj paid 2000

AI: What was the ₹2,000 expense for?
~~~

Then:

~~~text
User: Hotel

AI: Who should split the hotel expense?
[ Everyone ]
[ Choose members ]
~~~

Conversation context should be sufficient to finish the pending command.

## 22. Conversation context limits

Do not send unlimited chat history.

MVP:

- last 10–20 relevant messages
- active trip information
- active trip members
- categories
- pending expense command

Later, add summarization for long conversations.

## 23. Prompt versioning

Create a versioned prompt:

~~~text
expense-chat-v1
~~~

The prompt must instruct the model:

- You are TripSplit's expense assistant.
- Return the required structured format.
- Never invent members.
- Never invent amounts.
- Never invent database IDs.
- Ask for missing information.
- Do not claim a transaction was created.
- Use supplied trip context only.
- Support English, Hinglish and Gujarati Roman.
- Flag ambiguity.
- Never execute financial actions.

Store the prompt version in ai_parse_events.

## 24. Rate limiting and cost control

Protect the AI endpoint.

Suggested initial limits:

~~~text
30 requests / 10 minutes / user
2000 characters / message
configurable daily request limit
~~~

Use HTTP 429 when the limit is exceeded.

Control cost by:

- limiting message length
- limiting conversation history
- sending only required trip context
- avoiding unnecessary retries
- logging token usage
- configurable model/provider
- admin AI disable switch

Current model pricing changes over time, so do not hard-code pricing assumptions into the application.

## 25. Privacy

AI chat can contain financial information.

Rules:

- API key remains server-side.
- Send only the current trip context required for parsing.
- Do not send unrelated users or trips.
- Never send authentication secrets.
- Do not expose database IDs unnecessarily to the model.
- Restrict AI logs in admin.
- Consider masking unnecessary phone/email information.
- Support chat deletion/retention policy when product requirements are finalized.

## 26. Admin changes

The existing admin panel already has an integrations page:

~~~text
admin/integrations.php
~~~

It currently combines AI and WhatsApp. Replace it with:

~~~text
admin/ai.php
~~~

Recommended dashboard:

~~~text
AI Expense Chat
  Provider
  Model
  Status
  Requests Today
  Success Rate
  Needs Review
  Errors
  Average Latency
  Token Usage
  Estimated Cost
~~~

Recent requests:

~~~text
Time
User
Trip
Intent
Model
Latency
Status
Transaction
~~~

Details:

~~~text
Original user message
Structured output
Validation result
Normalized command
Confidence
Prompt version
Transaction ID
Error
~~~

Add evaluation results:

~~~text
English
Hinglish
Gujarati Roman
Split methods
Ambiguous
Corrections
Overall
~~~

## 27. Admin settings

Current flags include:

~~~text
feature_whatsapp
feature_ai_parser
~~~

Replace with:

~~~text
feature_ai_chat
ai_require_confirmation
ai_logging_enabled
ai_max_message_length
ai_history_limit
ai_daily_request_limit
ai_prompt_version
~~~

Keep AI provider/model configuration server-side where possible.

## 28. Remove WhatsApp from the product

Update:

~~~text
README.md
docs/TripSplit_Admin_Panel_Feature_Specification.md
admin/settings.php
admin/integrations.php
admin/includes/header.php
~~~

Remove:

- WhatsApp connections
- WhatsApp QR
- WhatsApp messages
- WhatsApp groups
- WhatsApp parser
- WhatsApp monitoring
- WhatsApp health status
- WhatsApp feature flag

Replace them with AI Expense Chat equivalents.

The existing admin specification currently contains extensive WhatsApp sections, so it must be revised rather than leaving obsolete architecture in documentation.

## 29. System health

Remove:

~~~text
WhatsApp service status
~~~

Add:

~~~text
AI provider status
AI API latency
AI request health
AI daily usage
~~~

Example:

~~~text
Database       ● Healthy
API            ● Healthy
AI Provider    ● Healthy
OCR            ● Healthy
Email          ● Healthy
~~~

## 30. Security findings that must be addressed

The repository currently has security shortcuts that are particularly important before exposing an AI financial-write endpoint.

### X-User-Id

Current authentication trusts the X-User-Id header.

This must not be the authoritative production identity mechanism.

### Development fallback

getCurrentUser() contains a development fallback that can select the first trip member when no session is present.

This must be disabled in production.

### CSRF

The current CSRF implementation bypasses validation when X-User-Id exists.

This must be corrected.

### AI endpoint authorization

Every AI request must verify:

~~~text
authenticated user
+
conversation ownership
+
trip membership
~~~

A user must not be able to submit another user's conversation_id or trip_id to access data.

## 31. AI-specific security

Treat all model output as untrusted input.

Never allow model output to become:

~~~text
SQL
PHP
authorization decisions
permission decisions
raw database IDs
unescaped HTML
~~~

Never execute model-generated code.

## 32. Idempotency

The AI confirmation endpoint must be idempotent.

Protect against:

- double tapping Add Expense
- network retry
- duplicate HTTP requests
- delayed response followed by retry

Use the existing client_request_id mechanism.

A repeated confirmation must return the existing transaction result instead of creating a second transaction.

## 33. Migration strategy

Add:

~~~text
sql/migration_ai_chat.sql
~~~

Update:

~~~text
sql/schema.sql
~~~

Do not put AI table creation inside normal request handling.

Fresh installations should get the AI tables from schema.sql. Existing installations should run the migration.

## 34. Recommended implementation phases

### Phase 1 — Documentation/schema

- Add this specification.
- Remove WhatsApp from product specification.
- Add AI tables.
- Add migration.
- Define structured contract.

### Phase 2 — Backend

- AiClient
- prompt
- parser
- validator
- member resolver
- ai-chat API
- logging
- confirmation endpoint

### Phase 3 — Test dataset

- English
- Hinglish
- Gujarati Roman
- split methods
- multiple payers
- corrections
- ambiguity
- invalid cases
- automated evaluation runner

### Phase 4 — Flutter

- AI chat screen
- service
- message model
- preview card
- clarification UI
- confirmation UI
- error states

### Phase 5 — Integration

- confirmation -> existing ExpenseService/expense API
- validate balances
- validate settlements
- test idempotency

### Phase 6 — Admin

- AI dashboard
- request logs
- parser details
- evaluation dashboard
- settings
- provider health

### Phase 7 — Production hardening

- session authentication
- CSRF
- rate limiting
- API key protection
- privacy controls
- monitoring
- false-auto-creation tests

## 35. Expected new files

~~~text
api/ai-chat.php

includes/ai/
  AiClient.php
  ExpenseChatParser.php
  AiPrompt.php
  AiValidator.php

sql/migration_ai_chat.sql

admin/ai.php

tests/ai_expense_chat/
  english.json
  hinglish.json
  gujarati_roman.json
  split_methods.json
  multiple_payers.json
  corrections.json
  ambiguous.json
  invalid.json
  edge_cases.json
  run.php

tripbook_flutter/lib/features/ai_chat/
  ai_chat_screen.dart
  models/ai_message.dart
  models/ai_expense_preview.dart
  widgets/chat_message_bubble.dart
  widgets/expense_preview_card.dart
  widgets/chat_input.dart

tripbook_flutter/lib/services/ai_chat_service.dart
~~~

## 36. Expected updated files

~~~text
README.md
sql/schema.sql
admin/settings.php
admin/integrations.php
admin/includes/header.php
docs/TripSplit_Admin_Panel_Feature_Specification.md

tripbook_flutter/lib/core/api/api_endpoints.dart
tripbook_flutter/lib/main.dart
tripbook_flutter/lib/features/home/all_groups_home_screen.dart
tripbook_flutter/lib/features/dashboard/dashboard_screen.dart
~~~

Existing expense/calculation files should be reused, not replaced.

## 37. Final architecture

~~~text
                         Flutter App
                              |
                       AI Expense Chat
                              |
                         Dio ApiClient
                              |
                         HTTPS / JSON
                              |
                      /api/ai-chat.php
                              |
             +----------------+----------------+
             |                                 |
      Conversation DB                    Trip Context
                                      members/categories
             |                                 |
             +----------------+----------------+
                              |
                     ExpenseChatParser
                              |
                         LLM API
                              |
                      Structured JSON
                              |
                       AiValidator
                              |
                      Member Resolver
                              |
                    Split Validation
                              |
                         Confirmation
                              |
                    Existing Expense API
                              |
                +-------------+-------------+
                |             |             |
          transactions  expense_splits  transaction_payers
                              |
                         calculations
                              |
                    balances/settlements
~~~

## 38. Final recommendation

### Keep

- Flutter/Dart
- PHP 8+
- MySQL
- Dio
- Provider
- existing expense API
- existing split calculations
- existing OCR

### Add

- server-side LLM client
- AI chat API
- AI conversation storage
- AI parse logs
- AI test dataset
- automated evaluation
- Flutter AI chat UI
- admin AI monitoring

### Remove

- WhatsApp integration
- WhatsApp parser
- WhatsApp connection infrastructure
- WhatsApp admin monitoring
- WhatsApp feature flag

### Core product rule

~~~text
LLM understands the message.
PHP validates the meaning.
TripSplit calculates the money.
User confirms.
Only then is the transaction created.
~~~

## 39. Acceptance criteria

- [ ] User can open AI Expense Chat.
- [ ] Natural-language expense entry works.
- [ ] English works.
- [ ] Hinglish works.
- [ ] Gujarati Roman works.
- [ ] Amount extraction is validated.
- [ ] Payer is resolved to an actual member.
- [ ] Ambiguous members trigger clarification.
- [ ] Equal split works.
- [ ] Exact split works.
- [ ] Percentage split works.
- [ ] Shares split works.
- [ ] Multiple payers work.
- [ ] Invalid splits are rejected.
- [ ] LLM never directly creates financial records.
- [ ] Confirmation is required before creation.
- [ ] Existing expense API creates the transaction.
- [ ] Existing balance calculations remain correct.
- [ ] Duplicate confirmation cannot create duplicate transactions.
- [ ] API key is never shipped to Flutter.
- [ ] AI requests are rate-limited.
- [ ] AI calls are logged.
- [ ] AI failure does not disable manual expense entry.
- [ ] Test datasets are included.
- [ ] Automated evaluation can run.
- [ ] False auto-creation rate is 0% in the acceptance dataset.
- [ ] WhatsApp is removed from product/admin documentation.
- [ ] Admin can monitor AI health and parsing.
- [ ] Production authentication does not rely solely on X-User-Id.

## 40. Implementation order

Do not start by building only the UI.

Recommended order:

~~~text
1. Database migration
2. AI service abstraction
3. Structured response contract
4. Backend validation
5. AI chat API
6. Test dataset + evaluation runner
7. Flutter chat UI
8. Confirmation -> existing expense API
9. Admin monitoring
10. Remove remaining WhatsApp references
11. Security hardening
12. Production evaluation
~~~

This keeps the Flutter UI decoupled from unstable model output and preserves the existing TripSplit financial engine as the source of truth.
