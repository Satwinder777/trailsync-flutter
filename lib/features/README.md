# Feature module boundaries

Each module keeps `presentation`, `domain`, and `data` separate. Presentation owns pages, widgets and BLoC/Cubit state; domain owns immutable models, use cases and repository contracts; data owns repository implementations and external adapters. UI and BLoC code must not issue HTTP requests or query SQLite directly.

The foundation creates these modules without adding placeholder repositories or simulated product behavior:

- `authentication`
- `dashboard`
- `tracking`
- `synchronization`
- `history`
- `map`
- `settings`
