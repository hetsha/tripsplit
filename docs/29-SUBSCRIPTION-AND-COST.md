# 29 — Subscription and Cost

This document specifies the cost model: self-hosted services, external costs, and pricing strategy.

---

## 1. Pricing Strategy

| Rule | Value |
|------|-------|
| User pricing | Free |
| Revenue model | Future premium features (not initial launch) |
| Cost absorption | Self-hosted infrastructure |

---

## 2. Self-Hosted Components

| Component | Technology | Cost |
|-----------|-----------|------|
| Database | MySQL 8+ | Free |
| Web server | Apache/Nginx | Free |
| OCR | Tesseract | Free |
| LLM (primary) | Ollama + small model | Free (GPU hardware) |
| WhatsApp | OpenWA | Free |
| WebSocket | Ratchet | Free |
| Background workers | PHP CLI + cron | Free |
| PDF generation | dompdf or wkhtmltopdf | Free |
| Image processing | Imagick/OpenCV | Free |
| Analytics | Custom (PHP) | Free |
| Notifications (in-app) | Database table | Free |
| File storage | Local filesystem | Hardware cost |

---

## 3. Potential External Costs

| Service | Provider | Estimated Cost | Priority |
|---------|----------|---------------|----------|
| SMS OTP | upparac.com | ₹0.20-0.50 per SMS | P0 |
| Email SMTP | Self-hosted | Free (if self-hosted) | P2 |
| LLM fallback | OpenAI/Google | $0.001-0.01 per request | P3 |
| Cloud storage | Future | $5-20/month | P3 |
| WhatsApp Business API | Meta (future) | $0.005 per conversation | P3 |
| Payment processing | Future | 2-3% per transaction | P3 |
| Domain + SSL | Let's Encrypt | Free | P0 |
| Server hosting | VPS | $5-20/month | P0 |

---

## 4. Cost Optimization Strategies

| Strategy | Implementation |
|----------|---------------|
| Self-hosted OCR | Tesseract on server |
| Local LLM | Ollama with quantized model |
| SMS bypass | WhatsApp as primary communication |
| Caching | Reduce database queries |
| Compression | gzip responses |
| Image optimization | Compress receipts before storage |
| Rate limiting | Prevent abuse |

---

## 5. Infrastructure Requirements

### Minimum Server

| Resource | Requirement |
|----------|-------------|
| CPU | 2 cores |
| RAM | 4 GB |
| Storage | 20 GB |
| Bandwidth | 100 GB/month |
| OS | Ubuntu 22.04 / Debian 12 |

### Recommended

| Resource | Requirement |
|----------|-------------|
| CPU | 4 cores |
| RAM | 8 GB |
| Storage | 50 GB SSD |
| GPU | Optional (for LLM) |

---

## 6. Scaling Considerations

| Stage | Users | Strategy |
|-------|-------|----------|
| 0-1000 | Personal/small groups | Single server |
| 1000-10000 | Growing | Add caching, optimize queries |
| 10000-100000 | Scale | Load balancer, read replicas |
| 100000+ | Enterprise | Microservices, CDN |

---

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| OQ-1 | What is the target monthly infrastructure budget? | Server sizing |
| OQ-2 | Should we implement a freemium model later? | Revenue strategy |
| OQ-3 | Should we accept donations? | Funding model |

---

## Dependencies

- `00-PROJECT-OVERVIEW.md` — Pricing decisions

## Related Documents

- `22-BACKEND-ARCHITECTURE.md` — Infrastructure
- `26-SECURITY-PRIVACY.md` — Security costs
- `31-IMPLEMENTATION-ROADMAP.md` — Phased rollout
