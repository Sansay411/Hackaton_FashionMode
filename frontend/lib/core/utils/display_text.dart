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

String productionTypeLabel(String? value) {
  switch (value) {
    case 'manager':
      return 'Менеджер цеха';
    case 'worker':
      return 'Сотрудник цеха';
    default:
      return value ?? '-';
  }
}

String specializationLabel(String? value) {
  switch (value) {
    case 'cutting':
      return 'Раскрой';
    case 'sewing':
      return 'Пошив';
    case 'finishing':
      return 'Отделка';
    case 'qc':
      return 'Контроль качества';
    default:
      return value ?? '-';
  }
}

String statusLabel(String value) {
  switch (value) {
    case 'placed':
      return 'Создан';
    case 'paid':
      return 'Оплачен';
    case 'accepted':
      return 'Подтвержден';
    case 'in_production':
      return 'В производстве';
    case 'ready':
      return 'Готов';
    case 'delivered':
      return 'Выдан';
    case 'archived':
      return 'Архив';
    case 'queued':
      return 'В очереди';
    case 'assigned':
      return 'Назначено';
    case 'active':
      return 'В работе';
    case 'in_progress':
      return 'В работе';
    case 'completed':
      return 'Завершено';
    case 'low':
      return 'Низкий';
    case 'medium':
      return 'Средний';
    case 'high':
      return 'Высокий';
    case 'made_to_order':
      return 'Под заказ';
    case 'in_stock':
      return 'В наличии';
    case 'qc':
      return 'ОТК';
    default:
      return value.replaceAll('_', ' ');
  }
}

String fieldLabel(String value) {
  switch (value) {
    case 'full_name':
      return 'Имя';
    case 'email':
      return 'Почта';
    case 'role':
      return 'Роль';
    case 'franchise_id':
      return 'Филиал';
    case 'created_at':
      return 'Дата создания';
    case 'mode':
      return 'Режим';
    case 'production_type':
      return 'Роль в цехе';
    case 'specialization':
      return 'Специализация';
    case 'priority':
      return 'Приоритет';
    case 'api_base_url':
      return 'Адрес сервера';
    case 'sync_interval_seconds':
      return 'Интервал синхронизации';
    case 'realtime':
      return 'Синхронизация';
    case 'message':
      return 'Сообщение';
    case 'notifications':
      return 'Уведомления';
    case 'instant_updates':
      return 'Мгновенные обновления';
    case 'editorial_cards':
      return 'Каталоговый вид';
    case 'compact_mode':
      return 'Компактный режим';
    case 'biometric_lock':
      return 'Защита входа';
    case 'order_id':
      return '№ заказа';
    case 'order_code':
      return 'Код заказа';
    case 'client_id':
      return 'ID клиента';
    case 'quantity':
      return 'Количество';
    case 'price':
      return 'Сумма';
    case 'ready_date':
      return 'Готовность';
    case 'tracking_stage':
      return 'Этап';
    case 'order_type':
      return 'Тип заказа';
    case 'task_id':
      return 'Задача';
    case 'assigned_to':
      return 'Назначено';
    case 'assigned_to_name':
      return 'Исполнитель';
    case 'created_by':
      return 'Создал';
    case 'started_at':
      return 'Начато';
    case 'completed_at':
      return 'Завершено';
    case 'updated_at':
      return 'Обновлено';
    case 'operation_stage':
      return 'Этап';
    default:
      return value.replaceAll('_', ' ');
  }
}

String modeLabel(bool isUsingMock) => isUsingMock ? 'Демо' : 'Сервер';

String formatTenge(dynamic rawValue, {String currency = '₸'}) {
  final numeric = num.tryParse(rawValue.toString().replaceAll(',', '.')) ?? 0;
  final rounded = numeric.round().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < rounded.length; index += 1) {
    final reverseIndex = rounded.length - index;
    buffer.write(rounded[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(' ');
    }
  }

  return '${buffer.toString().trim()} $currency';
}
