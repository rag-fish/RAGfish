# Authority Model
Version: 1.0.0
Status: Locked

Defines authority hierarchy.

---

## Levels

1. SYSTEM
2. USER
3. AGENT
4. MODEL

---

## Hierarchy

SYSTEM
└── USER
└── AGENT
└── MODEL

---

## Rules

- Lower authority cannot override higher authority.
- Model cannot self-elevate authority.
- Agent must verify user intent before execution.

---

## Verification Procedure

1. Validate user role.
2. Confirm constraint compatibility.
3. Log authority chain.