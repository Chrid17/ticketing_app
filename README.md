# TicketDesk — Client Support Ticketing App

A professional, offline-first helpdesk app built with **Flutter** and **GetX**. Log client issues, triage them by
priority, assign owners, hold conversations, and track every change through to resolution — on Android, iOS, web,
Windows, macOS and Linux.

## Features

**Dashboard**
- Live KPIs: active tickets, urgent, overdue, resolved in the last 7 days, average resolution time
- 7-day chart of tickets created vs resolved
- Breakdown by priority, status and category (tap any status to jump to those tickets)
- "Needs attention" queue (overdue, due within 24 h, high/urgent) and recent activity

**Tickets**
- Full-text search across reference, subject, description, client, email, assignee and tags
- Quick views with live counts: Active, All, Assigned to me, Unassigned, Overdue, Open, In progress, On hold, Resolved, Closed
- Filters by priority (multi-select) and category; six sort orders
- Quick actions menu on every ticket (change status, edit, delete with **undo**)

**Ticket details**
- Sequential references (`TCK-0001`), status workflow: Open → In progress → On hold → Resolved → Closed
- One-tap actions: Start work, Resolve, Close, Reopen, Assign to me
- Inline status, priority and assignee changes
- Conversation thread with client replies and **internal notes**
- Automatic audit trail of every change (who, what, when)
- Due dates with "due soon" and "overdue" indicators; resolution time tracking

**Create / edit**
- Validated form (client name, email format, subject, description)
- Category, priority, status, assignee suggestions, due date + time with quick presets, tags
- Unsaved-changes protection

**Settings**
- Display name used for replies and the activity log
- Light / dark / system theme
- Load demo tickets, export to JSON (clipboard), import from JSON, delete all data

All data is stored locally with `shared_preferences`, so the app works fully offline.

## Getting started

```bash
flutter pub get
flutter run            # pick a device, or: flutter run -d chrome
flutter test           # unit + widget tests
flutter build web      # or: flutter build apk --release
```

On first launch the app is empty — tap **Load demo tickets** on the dashboard to explore it with sample data,
or **New ticket** to start logging real ones.

## Project structure

```
lib/
├── main.dart                     # App bootstrap, theme, routes
├── routes.dart                   # Named routes (/, /new-ticket, /ticket/:id, /ticket/:id/edit)
├── models/ticket_model.dart      # Ticket, comments, activity, priority/status/category enums
├── services/
│   ├── storage_service.dart      # Local persistence
│   └── demo_data.dart            # Optional sample tickets
├── controllers/
│   ├── ticket_controller.dart    # CRUD, filters, sorting, dashboard metrics, import/export
│   └── settings_controller.dart  # Theme and agent name
├── pages/                        # Shell (responsive nav), dashboard, tickets, detail, form, settings
├── widgets/                      # Ticket card, badges, avatars, shared UI
└── utils/                        # Theme, formatters, notifications
```

The layout adapts automatically: bottom navigation on phones, a navigation rail on tablets, and an extended
sidebar with two-column ticket details on desktop and web.
