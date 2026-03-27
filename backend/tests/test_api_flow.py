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


def test_demo_flow_end_to_end(api_client):
    client_token, client_user = _login(api_client, "client@avishu.com", "demo123")
    franchisee_token, _ = _login(api_client, "franchisee@avishu.com", "demo123")
    production_token, _ = _login(api_client, "production@avishu.com", "demo123")

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
    order_id = order["id"]

    franchise_orders = api_client.get(
        "/orders/franchise/1",
        headers={"Authorization": f"Bearer {franchisee_token}"},
    )
    assert franchise_orders.status_code == 200, franchise_orders.text
    assert any(item["id"] == order_id for item in franchise_orders.json())

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
        headers={"Authorization": f"Bearer {production_token}"},
    )
    assert queue.status_code == 200, queue.text
    task = next(item for item in queue.json() if item["order_id"] == order_id)
    assert task["status"] == "active"

    completed = api_client.patch(
        f"/production/tasks/{task['id']}/complete",
        headers={"Authorization": f"Bearer {production_token}"},
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

