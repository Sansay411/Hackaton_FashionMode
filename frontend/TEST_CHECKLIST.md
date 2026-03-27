# AVISHU Frontend Test Checklist

## Login And Routing

- Login as `client` and land on the client screen
- Login as `franchisee` and land on the franchisee screen
- Login as `production` and land on the production screen
- Logout returns to the login screen

## Client Flow

- Products list loads
- Client can create an order from a product card
- New order appears in client orders list with `placed`
- Client sees status progress update to `accepted`
- Client sees status progress update to `in_production`
- Client sees final status `ready`

## Franchisee Flow

- Franchisee sees the newly created order without manual refresh delay beyond polling
- Franchisee can change `placed` -> `accepted`
- Franchisee can change `accepted` -> `in_production`
- Already `ready` orders are clearly non-actionable

## Production Flow

- Production sees task created for the same franchise
- Task appears as `queued` before production stage
- Task becomes `active` after franchisee sends order to production
- Production can complete the task with the large action button
- Completed task is shown as `completed`

## Realtime And Demo Safety

- Client order updates without app restart
- Franchisee order updates without app restart
- Production task updates without app restart
- Turning off backend causes clean fallback to demo mode
- Demo mode banner is visible when mock mode is active

## Loading Empty Error States

- Login shows loading state while authenticating
- Empty products or empty orders render a clean empty state
- API errors render a retryable error state
- Action buttons disable while a mutation is in progress
