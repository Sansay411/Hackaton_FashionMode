from __future__ import annotations


def _login(client, email: str, password: str) -> tuple[str, dict]:
    response = client.post(
        "/auth/login",
        json={
            "email": email,
            "password": password,
        },
    )
    assert response.status_code == 200, response.text
    payload = response.json()
    return payload["token"], payload["user"]


def test_login_success_client(api_client):
    token, user = _login(api_client, "client@avishu.com", "demo123")
    assert token
    assert user["role"] == "client"
    assert user["email"] == "client@avishu.com"


def test_login_invalid_credentials(api_client):
    response = api_client.post(
        "/auth/login",
        json={
            "email": "client@avishu.com",
            "password": "wrong-password",
        },
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"


def test_protected_route_requires_token(api_client):
    response = api_client.get("/products")
    assert response.status_code == 401


def test_order_status_transition_validation(api_client):
    client_token, client_user = _login(api_client, "client@avishu.com", "demo123")
    franchisee_token, _ = _login(api_client, "franchisee@avishu.com", "demo123")

    created = api_client.post(
        "/orders",
        headers={"Authorization": f"Bearer {client_token}"},
        json={
            "client_id": client_user["id"],
            "franchise_id": 1,
            "product_id": 1,
            "quantity": 1,
            "order_type": "made_to_order",
            "selected_ready_date": "2026-04-10",
        },
    )
    assert created.status_code == 200, created.text
    order_id = created.json()["id"]

    skipped = api_client.patch(
        f"/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {franchisee_token}"},
        json={"status": "in_production"},
    )
    assert skipped.status_code == 400
    assert skipped.json()["detail"] == "Invalid order status transition"


def test_order_code_generated_and_searchable(api_client):
    client_token, client_user = _login(api_client, "client@avishu.com", "demo123")
    franchisee_token, _ = _login(api_client, "franchisee@avishu.com", "demo123")

    first = api_client.post(
        "/orders",
        headers={"Authorization": f"Bearer {client_token}"},
        json={
            "client_id": client_user["id"],
            "franchise_id": 1,
            "product_id": 1,
            "quantity": 1,
            "order_type": "made_to_order",
            "selected_ready_date": "2026-04-10",
        },
    )
    second = api_client.post(
        "/orders",
        headers={"Authorization": f"Bearer {client_token}"},
        json={
            "client_id": client_user["id"],
            "franchise_id": 1,
            "product_id": 1,
            "quantity": 1,
            "order_type": "made_to_order",
            "selected_ready_date": "2026-04-11",
        },
    )

    assert first.status_code == 200, first.text
    assert second.status_code == 200, second.text
    first_code = first.json()["order_code"]
    second_code = second.json()["order_code"]
    assert first_code != second_code
    assert first_code.startswith("AV-")
    assert second_code.startswith("AV-")

    search = api_client.get(
        f"/orders/franchise/1?order_code={first_code}",
        headers={"Authorization": f"Bearer {franchisee_token}"},
    )
    assert search.status_code == 200, search.text
    items = search.json()
    assert len(items) == 1
    assert items[0]["order_code"] == first_code


def test_demo_flow_end_to_end(api_client):
    client_token, client_user = _login(api_client, "client@avishu.com", "demo123")
    franchisee_token, _ = _login(api_client, "franchisee@avishu.com", "demo123")
    manager_token, _ = _login(api_client, "production.manager@avishu.com", "demo123")
    worker_1_token, _ = _login(api_client, "1@gmail.com", "demo123")
    worker_2_token, _ = _login(api_client, "2@gmail.com", "demo123")
    worker_3_token, _ = _login(api_client, "3@gmail.com", "demo123")

    products = api_client.get(
        "/products",
        headers={"Authorization": f"Bearer {client_token}"},
    )
    assert products.status_code == 200, products.text
    product_id = products.json()[0]["id"]

    created_order = api_client.post(
        "/orders",
        headers={"Authorization": f"Bearer {client_token}"},
        json={
            "client_id": client_user["id"],
            "franchise_id": 1,
            "product_id": product_id,
            "quantity": 2,
            "order_type": "made_to_order",
            "selected_ready_date": "2026-04-12",
        },
    )
    assert created_order.status_code == 200, created_order.text
    order = created_order.json()
    assert order["status"] == "placed"
    assert order["order_code"].startswith("AV-")
    order_id = order["id"]

    franchise_orders = api_client.get(
        "/orders/franchise/1",
        headers={"Authorization": f"Bearer {franchisee_token}"},
    )
    assert franchise_orders.status_code == 200, franchise_orders.text
    assert any(item["id"] == order_id for item in franchise_orders.json())

    paid = api_client.patch(
        f"/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {client_token}"},
        json={"status": "paid"},
    )
    assert paid.status_code == 200, paid.text
    assert paid.json()["status"] == "paid"

    accepted = api_client.patch(
        f"/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {franchisee_token}"},
        json={"status": "accepted"},
    )
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["status"] == "accepted"

    in_production = api_client.patch(
        f"/orders/{order_id}/status",
        headers={"Authorization": f"Bearer {franchisee_token}"},
        json={"status": "in_production"},
    )
    assert in_production.status_code == 200, in_production.text
    assert in_production.json()["status"] == "in_production"

    queue = api_client.get(
        "/production/tasks/1",
        headers={"Authorization": f"Bearer {manager_token}"},
    )
    assert queue.status_code == 200, queue.text
    tasks = [item for item in queue.json() if item["order_id"] == order_id]
    assert len(tasks) == 4
    assert all(task["status"] == "queued" for task in tasks)
    assert all(task["priority"] in {"high", "medium", "low"} for task in tasks)

    workers = api_client.get(
        "/production/workers/1",
        headers={"Authorization": f"Bearer {manager_token}"},
    )
    assert workers.status_code == 200, workers.text
    worker_ids_by_email = {item["email"]: item["id"] for item in workers.json()}

    for stage, token, worker_email in [
        ("cutting", worker_1_token, "1@gmail.com"),
        ("sewing", worker_1_token, "1@gmail.com"),
        ("finishing", worker_2_token, "2@gmail.com"),
        ("qc", worker_3_token, "3@gmail.com"),
    ]:
        queue = api_client.get(
            "/production/tasks/1",
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert queue.status_code == 200, queue.text
        task = next(
            item
            for item in queue.json()
            if item["order_id"] == order_id and item["operation_stage"] == stage
        )

        assigned = api_client.patch(
            f"/production/tasks/{task['id']}/assign",
            headers={"Authorization": f"Bearer {manager_token}"},
            json={"worker_id": worker_ids_by_email[worker_email]},
        )
        assert assigned.status_code == 200, assigned.text
        assert assigned.json()["status"] == "assigned"
        assert assigned.json()["order_code"] == order["order_code"]

        my_tasks = api_client.get(
            "/production/tasks/1",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert my_tasks.status_code == 200, my_tasks.text
        assert any(item["id"] == task["id"] for item in my_tasks.json())

        started = api_client.patch(
            f"/production/tasks/{task['id']}/start",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert started.status_code == 200, started.text
        assert started.json()["status"] == "in_progress"

        completed = api_client.patch(
            f"/production/tasks/{task['id']}/complete",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert completed.status_code == 200, completed.text
        assert completed.json()["status"] == "completed"

    client_orders = api_client.get(
        f"/orders/client/{client_user['id']}",
        headers={"Authorization": f"Bearer {client_token}"},
    )
    assert client_orders.status_code == 200, client_orders.text
    final_order = next(item for item in client_orders.json() if item["id"] == order_id)
    assert final_order["status"] == "ready"
    assert final_order["tracking_stage"] == "ready"
    assert final_order["order_code"] == order["order_code"]


def test_manager_can_create_worker_account(api_client):
    manager_token, _ = _login(api_client, "production.manager@avishu.com", "demo123")

    created = api_client.post(
        "/production/workers",
        headers={"Authorization": f"Bearer {manager_token}"},
        json={
            "email": "worker.new@avishu.com",
            "password": "demo123",
            "full_name": "Новый сотрудник",
            "specialization": "sewing",
        },
    )
    assert created.status_code == 200, created.text
    worker = created.json()
    assert worker["role"] == "production"
    assert worker["production_type"] == "worker"
    assert worker["specialization"] == "sewing"

    workers = api_client.get(
        "/production/workers/1",
        headers={"Authorization": f"Bearer {manager_token}"},
    )
    assert workers.status_code == 200, workers.text
    assert any(item["email"] == "worker.new@avishu.com" for item in workers.json())

    worker_token, worker_user = _login(api_client, "worker.new@avishu.com", "demo123")
    assert worker_user["production_type"] == "worker"

    my_tasks = api_client.get(
        "/production/tasks/1",
        headers={"Authorization": f"Bearer {worker_token}"},
    )
    assert my_tasks.status_code == 200, my_tasks.text
