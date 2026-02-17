

# Invocation Boundary

## Status
Draft

---

# 1. Purpose

The Invocation Boundary defines the strict execution perimeter of the system.

It guarantees that every AI execution:
- Is explicitly triggered by a human action
- Is bound to a single Question object
- Produces exactly one Response object
- Has no hidden side effects

The Invocation Boundary exists to prevent autonomous drift.

---

# 2. Definition of Invocation

An Invocation is defined as:

- A single execution attempt
- Triggered by explicit human intent
- Associated with one `NoemaQuestion.id`
- Executed through the Router
- Producing one structured Response

An Invocation MUST:
- Be traceable
- Be logged
- Respect privacy_level
- Respect Router decision

---

# 3. What Is NOT an Invocation

The following are explicitly forbidden:

- Background execution
- Recursive self-invocation
- Auto-triggered execution
- Silent retries
- Spawning new Question objects
- Implicit memory writes

If any of these occur, the boundary has been violated.

---

# 4. Invocation Lifecycle

The system must follow this exact sequence:

Human Action
   ↓
Question Object Created
   ↓
Router Decision
   ↓
Execution (Local or Cloud)
   ↓
Response Object Generated
   ↓
Return to Human

Execution ends here.

There must be no implicit continuation beyond Response generation.

---

# 5. Execution Scope Rules

During an Invocation, the system MAY:

- Select a model (deterministically)
- Execute model inference
- Perform allowed fallback (if defined by Router)
- Produce structured logs

The system MUST NOT:

- Modify system configuration
- Persist memory outside declared path
- Escalate routing silently
- Execute undeclared external calls

---

# 6. State Mutation Policy

State mutation is forbidden unless:

- Explicitly declared in Invocation contract
- Logged
- Traceable to Question ID
- User-visible

Hidden mutation is strictly prohibited.

---

# 7. Deterministic Guarantee

Invocation must behave as a controlled execution unit.

It must:
- Have a single entry point
- Have a single exit point
- Avoid recursive loops
- Avoid self-modification

---

# 8. Logging Requirements

Each Invocation MUST record:

- question_id
- routing_decision
- selected_model
- execution_result
- fallback_usage
- execution_timestamp

Logs must be inspectable by the user.

---

# 9. Boundary Violation Rule

Any feature that introduces autonomous execution, implicit continuation, or hidden side effects
requires an explicit ADR update.

Violation of Invocation Boundary invalidates system compliance with ADR-0000.