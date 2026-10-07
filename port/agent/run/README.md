# Run records of the code-only run (written by the integrator)

- `PLAN.md`: the exact plan of the run. The integrator writes it before any worker starts (prompt A of
  [../PROMPTS.md](../PROMPTS.md)) and keeps the state of every work package current in it. It holds:
  - the run facts;
  - one row per work package, with its items in commit order;
  - the waves of worker slots;
  - coordination, merge order and escalation;
  - the open questions.
- This directory belongs to the area `port-integrate` (AREAS.md). It is not locked; workers do not write here.
