# User Acceptance Testing: RAGfish / Noema

**Version**: 1.0  
**Date**: 2026-02-05  
**Status**: Canonical  
**Type**: Operational Procedure

---

## 1. Purpose

This document defines **what must be manually verified by humans before any production release**.

It complements `docs/validation/VALIDATION.md`, which explains **why** human validation is necessary.

This document is:
- A concrete checklist
- An operational procedure
- A release gate

This document is **not**:
- A test automation guide
- A QA process manual
- A bug tracking workflow

---

## 2. Scope

User Acceptance Testing (UAT) in RAGfish / Noema verifies:

1. **Functional Correctness**: Does the system do what it claims to do?
2. **Intent Alignment**: Does the system behavior match user expectations?
3. **Constitutional Compliance**: Does the system respect architectural constraints?
4. **Safety**: Does the system avoid unacceptable failures?

UAT occurs **after** all automated tests pass, **before** production deployment.

---

## 3. UAT Principles

### 3.1 UAT is Human-Only

**Rule**:
> UAT cannot be automated. UAT requires human judgment of semantic correctness, intent alignment, and value trade-offs.

**Rationale**:
- Machines can verify syntax and structure
- Only humans can verify meaning and appropriateness
- (See `docs/validation/VALIDATION.md` Section 3 for detailed justification)

---

### 3.2 UAT is Independent

**Rule**:
> The human performing UAT must not be the primary implementer of the change being tested.

**Rationale**:
- Implementers have cognitive bias
- Independent review catches blind spots
- Accountability requires separation of roles

**Exception**:
- In single-person projects, UAT must be performed after a cooling-off period (minimum 24 hours after implementation)

---

### 3.3 UAT is Adversarial

**Rule**:
> UAT includes deliberate attempts to break the system, not just verification of expected behavior.

**Rationale**:
- Real-world usage includes unexpected inputs
- Adversarial thinking reveals edge cases
- Systems fail at boundaries, not in the middle

**Examples**:
- Test with malformed inputs
- Test with resource exhaustion
- Test with contradictory constraints
- Test with ambiguous user intent

---

### 3.4 UAT is Documented

**Rule**:
> UAT results must be recorded with human identity, timestamp, and reasoning.

**Rationale**:
- Accountability requires traceability
- Future reviewers need context
- Patterns of failure inform design improvements

**Required Documentation**:
- Who performed UAT (human identity)
- When UAT was performed (timestamp)
- What scenarios were tested
- What issues were found (if any)
- Why release was approved or blocked

---

## 4. Pre-Release UAT Checklist

Before any production release, a human validator must complete the following checklist.

**Every item requires a Yes answer. If any item is No, release is blocked.**

---

### 4.1 Client Layer UAT

#### 4.1.1 Routing Decisions

- [ ] **I have manually tested routing decisions for at least 5 representative scenarios**
  - Scenarios must include: local-only, cloud-only, hybrid, privacy-sensitive, cost-sensitive

- [ ] **I have verified that routing respects user privacy preferences**
  - Test: Configure privacy policy to "local-only", verify no data is sent to cloud

- [ ] **I have verified that routing respects user cost constraints**
  - Test: Configure cost limit, verify execution stops when limit is approached

- [ ] **I have tested routing with ambiguous or contradictory constraints**
  - Test: Request low-latency + local-only (contradictory), verify reasonable fallback

- [ ] **I have reviewed routing logs and found no unexpected decisions**

**Validator Notes** (required):
```
Describe what you tested and what you observed.
```

---

#### 4.1.2 Privacy Enforcement

- [ ] **I have verified that privacy-sensitive data remains local when policy requires it**
  - Test: Mark data as private, attempt cloud execution, verify rejection

- [ ] **I have verified that privacy settings are user-visible and user-controllable**
  - Test: Change privacy settings in UI, verify immediate effect

- [ ] **I have tested privacy enforcement under resource pressure**
  - Test: Simulate local resource exhaustion, verify no automatic cloud fallback for private data

**Validator Notes** (required):
```
Describe privacy scenarios tested and outcomes.
```

---

#### 4.1.3 User Interface Correctness

- [ ] **I have verified that the UI correctly represents system state**
  - Test: Perform actions, verify UI updates reflect actual state

- [ ] **I have verified that error messages are accurate and actionable**
  - Test: Trigger errors, verify messages explain what happened and what to do

- [ ] **I have tested UI responsiveness under load**
  - Test: Perform multiple rapid actions, verify UI remains responsive

**Validator Notes** (required):
```
Describe UI scenarios tested.
```

---

### 4.2 Execution Layer UAT

#### 4.2.1 Constraint Enforcement

- [ ] **I have manually verified that execution respects timeout constraints**
  - Test: Set short timeout, verify execution stops within limit

- [ ] **I have manually verified that execution respects memory constraints**
  - Test: Set memory limit, verify execution does not exceed limit

- [ ] **I have manually verified that execution respects cost constraints**
  - Test: Set cost limit, verify execution stops when limit is reached

- [ ] **I have tested constraint enforcement under adversarial inputs**
  - Test: Submit requests designed to circumvent constraints, verify enforcement holds

**Validator Notes** (required):
```
Describe constraint scenarios tested and enforcement outcomes.
```

---

#### 4.2.2 Autonomous Behavior Prevention

- [ ] **I have verified that execution does not autonomously retry failed requests**
  - Test: Trigger execution failure, verify no automatic retry without client instruction

- [ ] **I have verified that execution does not autonomously escalate or delegate tasks**
  - Test: Submit complex task, verify no autonomous decomposition or sub-task creation

- [ ] **I have verified that execution does not autonomously relax constraints**
  - Test: Submit request near constraint boundary, verify no creative reinterpretation

**Validator Notes** (required):
```
Describe autonomous behavior tests and outcomes.
```

---

#### 4.2.3 Error Handling

- [ ] **I have verified that execution errors are correctly reported to client**
  - Test: Trigger various error types, verify accurate error messages

- [ ] **I have verified that errors do not leak sensitive information**
  - Test: Review error messages for unintended data disclosure

- [ ] **I have tested error handling under partial failure scenarios**
  - Test: Simulate multi-step execution with mid-stream failure, verify clean abort

**Validator Notes** (required):
```
Describe error scenarios tested.
```

---

### 4.3 Knowledge Layer UAT

#### 4.3.1 RAGpack Semantic Correctness

- [ ] **I have manually reviewed RAGpack content against original source material**
  - Requirement: Review at least 10% of chunks or 50 chunks, whichever is smaller

- [ ] **I have verified that chunk boundaries preserve semantic meaning**
  - Test: Review chunk splits, verify no meaning distortion at boundaries

- [ ] **I have verified that metadata is factually correct**
  - Test: Check source attribution, timestamps, author information

- [ ] **I have tested RAGpack with adversarial queries**
  - Test: Submit queries designed to retrieve inappropriate or misleading content

**Validator Notes** (required):
```
Describe RAGpack content reviewed and any issues found.
```

---

#### 4.3.2 RAGpack Structure Integrity

- [ ] **I have verified that RAGpack structure is valid**
  - Test: Load RAGpack, verify no parsing errors

- [ ] **I have verified that embeddings have correct dimensions**
  - Test: Check embedding metadata, verify consistency

- [ ] **I have verified that RAGpack contains no executable code**
  - Test: Scan RAGpack contents, verify only data (no scripts, binaries)

**Validator Notes** (required):
```
Describe structure validation performed.
```

---

#### 4.3.3 Retrieval Quality

- [ ] **I have tested retrieval with at least 10 representative queries**
  - Requirement: Queries must span different topics and difficulty levels

- [ ] **I have verified that retrieved chunks are relevant to queries**
  - Test: Review top-k results, verify semantic relevance

- [ ] **I have verified that retrieval does not miss critical information**
  - Test: Submit queries where correct answer is known, verify correct chunks are retrieved

**Validator Notes** (required):
```
Describe retrieval quality observations.
```

---

### 4.4 Integration UAT

#### 4.4.1 End-to-End Scenarios

- [ ] **I have manually tested at least 5 end-to-end user scenarios**
  - Requirement: Scenarios must cover common use cases and edge cases

- [ ] **I have verified that system behavior aligns with user intent**
  - Test: For each scenario, confirm output serves user goals

- [ ] **I have tested cross-layer integration**
  - Test: Verify client → execution → knowledge flows correctly

**Validator Notes** (required):
```
Describe end-to-end scenarios tested and outcomes.
```

---

#### 4.4.2 Performance & Stability

- [ ] **I have reviewed performance metrics**
  - Requirement: No critical regressions (>20% latency increase or >20% cost increase)

- [ ] **I have tested system stability under sustained load**
  - Test: Run extended scenario (minimum 10 minutes), verify no crashes or leaks

- [ ] **I have verified graceful degradation under resource pressure**
  - Test: Simulate resource constraints, verify acceptable fallback behavior

**Validator Notes** (required):
```
Describe performance and stability observations.
```

---

#### 4.4.3 Regression Prevention

- [ ] **I have reviewed all automated test results**
  - Requirement: All automated tests pass

- [ ] **I have investigated any test failures or flakes**
  - Requirement: Understand root cause of any non-passing tests

- [ ] **I have verified that this release does not break existing functionality**
  - Test: Perform smoke tests of previously working features

**Validator Notes** (required):
```
Describe regression testing performed.
```

---

### 4.5 Constitutional Compliance

#### 4.5.1 Architecture Constitution Alignment

- [ ] **I have verified that routing authority remains client-side**
  - Test: Confirm execution layer does not make routing decisions

- [ ] **I have verified that execution layer remains a constrained executor**
  - Test: Confirm no autonomous goal-setting or decision-making

- [ ] **I have verified that knowledge layer remains passive**
  - Test: Confirm RAGpack contains no behavior or logic

**Validator Notes** (required):
```
Describe constitutional compliance verification.
```

---

#### 4.5.2 ADR Compliance

- [ ] **I have reviewed all applicable ADRs**
  - Requirement: List ADRs reviewed

- [ ] **I have verified that this release does not violate any ADR**
  - Test: Cross-check changes against ADR constraints

**ADRs Reviewed** (required):
```
List ADR numbers and titles reviewed.
```

---

## 5. UAT Sign-Off

### 5.1 Validator Declaration

By signing off on this UAT, I certify that:

1. I have personally performed all checklist items marked Yes
2. I have documented my testing process and findings
3. I understand the implications of this release
4. I accept accountability for this validation

**Any false certification is a violation of project governance.**

---

### 5.2 Sign-Off Template

```
Release: [Version/Tag]
Date: [YYYY-MM-DD]
Validator: [Full Name]
Role: [Title/Responsibility]

Summary:
[Brief description of what was tested and key findings]

Blockers Found: [Yes/No]
[If Yes, describe blockers and resolution]

Recommendation: [APPROVE / BLOCK]

Signature: [Validator Name]
Timestamp: [ISO 8601 timestamp]
```

---

### 5.3 Approval Authority

**Client Layer Changes**:
- Validator: Client team member (not primary implementer)
- Approver: Client product owner

**Execution Layer Changes**:
- Validator: Execution team member (not primary implementer)
- Approver: System architect

**Knowledge Layer Changes**:
- Validator: Knowledge curator (not primary contributor)
- Approver: Knowledge domain owner

**Cross-Layer Changes**:
- Validator: Independent reviewer from any team
- Approver: System architect

**Constitutional Changes** (ADRs, ARCHITECTURE.md):
- Validator: All layer owners
- Approver: System architect (unanimous consent required)

---

## 6. UAT Failure Handling

### 6.1 When UAT Fails

If any checklist item is No, or if validator recommends BLOCK:

1. **Immediate**: Release is blocked
2. **Within 24 hours**: Root cause analysis begins
3. **Within 7 days**: Corrective action plan created
4. **Before retry**: Corrective actions implemented and verified

---

### 6.2 Acceptable Reasons to Block

- Functional defect discovered
- Intent misalignment identified
- Constitutional violation found
- Safety concern raised
- Insufficient testing coverage
- Validator lacks confidence

**No justification needed to block. Confidence is mandatory for approval.**

---

### 6.3 Unacceptable Reasons to Approve

- "Automated tests passed" (necessary but not sufficient)
- "Looks good to me" (vague, no evidence of testing)
- "Probably fine" (uncertainty is grounds for blocking)
- "Already behind schedule" (schedule pressure does not override validation)

**If in doubt, block. Accountability requires certainty.**

---

## 7. UAT for Hotfixes

### 7.1 Expedited UAT

Critical hotfixes (security vulnerabilities, data loss bugs) may use expedited UAT:

**Allowed**:
- Reduced scenario coverage (focus on changed area)
- Same-day validation (no cooling-off period)
- Parallel automated testing and UAT

**Not Allowed**:
- Skipping UAT entirely
- Automated approval
- Implementer self-validation (unless unavoidable)

---

### 7.2 Minimum Hotfix UAT

For expedited hotfixes, validator must verify:

- [ ] Hotfix resolves the critical issue
- [ ] Hotfix does not introduce new critical issues
- [ ] Hotfix respects architectural constraints
- [ ] Hotfix can be safely rolled back if needed

**Full UAT must occur within 48 hours of hotfix deployment.**

---

## 8. UAT Continuous Improvement

### 8.1 Post-Release Review

Within 14 days of any production release:

1. **Review UAT effectiveness**
   - Did UAT catch issues that automated tests missed?
   - Did any issues escape UAT and reach production?

2. **Update UAT checklist if needed**
   - Add items for newly discovered failure modes
   - Remove items proven redundant with automation

3. **Update VALIDATION.md if philosophical gaps found**

---

### 8.2 UAT Metrics (Optional)

Projects may track:
- UAT time per release (baseline vs actual)
- UAT block rate (percentage of releases blocked)
- Escape rate (issues found in production despite UAT)

**Metrics are informative, not punitive.**

The goal is to improve validation quality, not to pressure validators to approve faster.

---

## 9. Relationship to Other Documents

### 9.1 VALIDATION.md

- **VALIDATION.md**: Explains **why** human validation is necessary (philosophy)
- **UAT.md**: Defines **what** humans must validate (procedure)

**Read VALIDATION.md first to understand rationale, then use UAT.md for execution.**

---

### 9.2 OPERATIONS.md

- **OPERATIONS.md**: Defines operational governance across all phases
- **UAT.md**: Focuses specifically on pre-release validation

**UAT is a subset of Operations.**

---

### 9.3 ADRs

- **ADRs**: Define architectural decisions and constraints
- **UAT.md**: Verifies that releases comply with ADRs

**UAT enforces ADRs at release time.**

---

## 10. Non-Negotiable Rules

### 10.1 No Human Verification, No Release

> If UAT checklist is not completed with human sign-off, release does not occur.

**No exceptions.**

---

### 10.2 AI May Assist, But Never Approve

> AI tools may prepare UAT reports, flag issues, or summarize results, but final approval is exclusively human.

**No exceptions.**

---

### 10.3 Validator Independence

> The validator must not be the primary implementer of the change being validated.

**Exception**: Single-person projects with mandatory cooling-off period.

---

### 10.4 Documentation is Mandatory

> UAT sign-off must include human identity, timestamp, and reasoning.

**No exceptions.**

---

## 11. Consequences of UAT Bypass

If production deployment occurs without completed UAT:

**Immediate**:
- Deployment is rolled back (Critical severity incident)
- Incident review is triggered
- Responsible parties are identified

**Structural**:
- Deployment process is audited
- Technical controls are added to prevent bypass
- UAT checklist is reviewed for gaps

**Governance**:
- If bypass was intentional: Disciplinary action (project-specific)
- If bypass was accidental: Process improvement (non-punitive)

**This is about preserving human accountability, not assigning blame.**

---

## 12. Document Metadata

**Authority**: System Architect  
**Enforcement**: All layer owners + Release managers  
**Review Frequency**: After every Critical incident, minimum quarterly  
**Last Reviewed**: 2026-02-05  
**Next Review**: 2026-05-05  

**This document is non-negotiable.**

---

## 13. Appendix: UAT Scenario Templates

### 13.1 Client Routing Scenario Template

```
Scenario: [Brief description]
User Intent: [What user is trying to achieve]
Constraints: [Privacy, cost, latency requirements]
Expected Routing: [Local/Cloud/Hybrid]
Actual Routing: [What actually happened]
Verdict: [PASS/FAIL]
Notes: [Observations]
```

---

### 13.2 Execution Constraint Scenario Template

```
Scenario: [Brief description]
Constraint Type: [Timeout/Memory/Cost]
Constraint Value: [Specific limit]
Test Input: [What was submitted]
Expected Behavior: [Stop at limit]
Actual Behavior: [What actually happened]
Verdict: [PASS/FAIL]
Notes: [Observations]
```

---

### 13.3 RAGpack Quality Scenario Template

```
Scenario: [Brief description]
Query: [What was asked]
Expected Chunks: [What should be retrieved]
Actual Chunks: [What was retrieved]
Semantic Quality: [1-5 scale]
Verdict: [PASS/FAIL]
Notes: [Observations]
```

---

## 14. References

- **Validation Philosophy**: `docs/validation/VALIDATION.md`
- **Operations Manual**: `docs/OPERATIONS.md`
- **Architecture Constitution**: `docs/architect/ARCHITECTURE.md`
- **ADR-0004**: Architecture Constitution Introduction
- **ADR-0005**: Client-side Routing as a First-Class Architectural Principle

---

**END OF DOCUMENT**
