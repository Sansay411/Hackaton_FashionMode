import '../../data/models/user.dart';

String roleLabel(UserRole role) {
  switch (role) {
    case UserRole.client:
      return 'Клиент';
    case UserRole.franchisee:
      return 'Франчайзи';
    case UserRole.production:
      return 'Производство';
  }
}

String roleValueLabel(String value) {
  switch (value) {
    case 'client':
      return 'Клиент';
    case 'franchisee':
      return 'Франчайзи';
    case 'production':
      return 'Производство';
    default:
      return value;
  }
}

String statusLabel(String value) {
  switch (value) {
    case 'placed':
      return 'Размещен';
    case 'accepted':
      return 'Принят';
    case 'in_production':
      return 'В работе';
    case 'ready':
      return 'Готов';
    case 'queued':
      return 'В очереди';
    case 'active':
      return 'Активно';
    case 'completed':
      return 'Завершено';
    case 'made_to_order':
      return 'Под заказ';
    case 'in_stock':
      return 'В наличии';
    default:
      return value.replaceAll('_', ' ');
  }
}

String fieldLabel(String value) {
  switch (value) {
    case 'full_name':
      return 'Полное имя';
    case 'email':
      return 'Почта';
    case 'role':
      return 'Роль';
    case 'franchise_id':
      return 'Франшиза';
    case 'created_at':
      return 'Создано';
    case 'mode':
      return 'Режим';
    case 'api_base_url':
      return 'Адрес API';
    case 'sync_interval_seconds':
      return 'Интервал синхронизации';
    case 'message':
      return 'Сообщение';
    case 'order_id':
      return 'Заказ';
    case 'client_id':
      return 'Клиент';
    case 'quantity':
      return 'Количество';
    case 'ready_date':
      return 'Дата готовности';
    case 'tracking_stage':
      return 'Этап';
    case 'order_type':
      return 'Тип заказа';
    case 'task_id':
      return 'Задача';
    case 'operation_stage':
      return 'Операция';
    default:
      return value.replaceAll('_', ' ');
  }
}

String modeLabel(bool isUsingMock) => isUsingMock ? 'Демо' : 'Сервер';
