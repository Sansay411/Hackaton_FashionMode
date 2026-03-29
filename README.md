# AVISHU Superapp

Репозиторий проекта AVISHU Superapp для хакатона

В составе:
frontend мобильное приложение на Flutter
backend API и синхронизация на FastAPI и pyhonm

## Роли

Клиент
Франчайзи
Производство:
  Менеджер
  Сотрудник


## Ручной запуск

Backend:

```bash
cd backend
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python seed_demo.py
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Frontend:

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
