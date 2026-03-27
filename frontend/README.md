# AVISHU Superapp Frontend MVP

Flutter mobile MVP for the AVISHU fashion franchise superapp.

The frontend is built strictly around `contracts/system_contract.docx` and only covers the judging flow:

1. Client creates order
2. Franchisee sees the new order
3. Production sees the task
4. Production completes the task
5. Client sees final `ready` status

## Frontend Architecture Summary

- Flutter single-codebase mobile app
- One shared `AppController` for session, screen data, and action state
- Contract-shaped models only: `User`, `Product`, `Order`, `ProductionTask`, `Session`
- `AppRepository` abstraction with:
  - `ApiRepository` for real backend calls
  - `MockRepository` for demo-safe fallback
- Polling-based realtime sync via `RealtimeSyncService`
  - The contract requires instant updates but does not define websocket/BaaS transport
  - The MVP uses short-interval polling so the flow remains stable without inventing backend protocols
- Minimal route map with role-based home routing
- Premium black/white editorial UI with large production actions
- Dark glassmorphism shell with `Home`, `Profile`, and `Settings` tabs per role

## Folder Structure

```text
frontend/
├── README.md
├── TEST_CHECKLIST.md
├── analysis_options.yaml
├── pubspec.yaml
└── lib
    ├── app.dart
    ├── app_controller.dart
    ├── app_scope.dart
    ├── main.dart
    ├── core
    │   ├── config
    │   │   └── app_config.dart
    │   ├── routing
    │   │   ├── app_router.dart
    │   │   └── route_names.dart
    │   ├── theme
    │   │   └── app_theme.dart
    │   └── widgets
    │       ├── app_scaffold.dart
    │       ├── primary_button.dart
    │       ├── section_header.dart
    │       ├── state_views.dart
    │       └── status_chip.dart
    ├── data
    │   ├── models
    │   │   ├── order.dart
    │   │   ├── product.dart
    │   │   ├── production_task.dart
    │   │   ├── session.dart
    │   │   └── user.dart
    │   ├── repositories
    │   │   ├── api_repository.dart
    │   │   ├── app_repository.dart
    │   │   └── mock_repository.dart
    │   └── services
    │       ├── http_client.dart
    │       └── realtime_sync_service.dart
    └── features
        ├── auth
        │   ├── demo_banner.dart
        │   └── login_screen.dart
        ├── client
        │   └── client_home_screen.dart
        ├── franchisee
        │   └── franchisee_home_screen.dart
        └── production
            └── production_home_screen.dart
```

## Route Map

- `/` -> login
- `/role-gate` -> resolves the correct home screen from `user.role`
- `/client` -> client dashboard
- `/franchisee` -> franchisee dashboard
- `/production` -> production dashboard

## API Integration Notes

The contract defines these endpoints:

- `POST /auth/login`
- `GET /products`
- `POST /orders`
- `GET /orders/client/{id}`
- `GET /orders/franchise/{id}`
- `PATCH /orders/{id}/status`
- `GET /production/tasks/{franchiseId}`
- `PATCH /production/tasks/{taskId}/complete`

This frontend keeps request fields aligned to the contract field names. Two implementation details are isolated in `ApiRepository` because the contract does not define those bodies explicitly:

- `PATCH /orders/{id}/status` sends `{ "status": "<contract_status>" }`
- `PATCH /production/tasks/{taskId}/complete` sends an empty patch body

If your backend uses a slightly different patch body shape, update only `lib/data/repositories/api_repository.dart`.

## Realtime Strategy

- Client polls client orders
- Franchisee polls franchise orders
- Production polls production tasks
- Poll interval defaults to 2 seconds
- Backend outage automatically switches the app into mock demo mode

## Demo Credentials In Mock Mode

- `client@avishu.app` / `demo123`
- `franchisee@avishu.app` / `demo123`
- `production@avishu.app` / `demo123`

The login screen also includes quick role preset buttons, so you can preview each role without typing the credentials manually.

## Run Instructions

1. Install Flutter 3.24+ and confirm `flutter --version` works.
2. From the repo root, open the frontend folder:

   ```bash
   cd frontend
   ```

3. Fetch packages:

   ```bash
   flutter pub get
   ```

4. If this directory was created before Flutter platform folders exist, generate them once:

   ```bash
   flutter create .
   ```

5. Run with backend:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://localhost:8080
   ```

6. Run in forced demo mode:

   ```bash
   flutter run --dart-define=USE_MOCK=true
   ```

7. Without backend:

   - Launch with `USE_MOCK=true`
   - On the login screen tap `Client`, `Franchisee`, or `Production`
   - Press `Login`
   - Use the bottom navigation to switch between `Home`, `Profile`, and `Settings`

## Notes

- This environment did not have Flutter installed, so I could not execute `flutter pub get` or a local simulator run here.
- The app source is ready, but final platform generation and runtime verification require a machine with Flutter SDK available.
