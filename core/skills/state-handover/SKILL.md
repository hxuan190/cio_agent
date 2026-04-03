---
name: state-handover
description: Standardized workflow to perform memory dumps and context hard-resets, forcing conversation state to disk to save massive tokens.
---
# State Handover (Memory Checkpointing)

## When to Use
- After completing a task phase (e.g. Planning -> Implementation).
- After fixing an exhaustive, token-heavy bug.
- Before switching context to a new domain.

## Protocol
1. **Compile State:** Extract only actionable truth from the conversation. Discard theories and dead-ends.
2. **Write Dump File:** Create or update `.claude/checkpoint.json` with:
   ```json
   {
     "current_phase": "Implementation",
     "completed": ["API setup"],
     "next_action": "Write tests for auth middleware.",
     "critical_context": ["User model uses string UUIDs", "Require JWT auth"]
   }
   ```
3. **Hard Reset Prompt:** Tell the user: "Checkpoint saved. Vui lòng gõ `/compact` hoặc reset session để dọn dẹp RAM, sau đó chúng ta sẽ tiếp tục bước tiếp theo dựa trên `.claude/checkpoint.json`."
