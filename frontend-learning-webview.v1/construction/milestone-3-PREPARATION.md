# Milestone 3 Preparation - Scale Testing

**Date**: 2025-10-14
**Phase**: Construction
**Status**: 준비 중

---

## Milestone 3 Objectives

Based on the successful completion of Milestone 2, Milestone 3 focuses on **scaling the system** to verify it can handle multiple topics and categories efficiently.

### Primary Goals

1. **Scale Testing**: Generate content for multiple topics across different categories
2. **Performance Validation**: Measure and optimize generation speed and resource usage
3. **Quality Consistency**: Ensure 100/100 quality scores across all generated content
4. **System Stability**: Verify no degradation under continuous operation

### Secondary Goals

1. **Automation Enhancement**: Improve batch processing capabilities
2. **Error Recovery**: Test and refine resume/retry mechanisms
3. **Documentation**: Create operational runbooks for production use
4. **Workflow Optimization**: Fix timestamp accuracy and HANDOFF LOG pattern (deferred from Milestone 2)
5. **Agent Prompt Refinement**: Improve 7 agent prompts based on Milestone 2 findings

---

## Prerequisites (Completed in Milestone 2)

✅ Full 7-agent pipeline operational
✅ Work Status Markers enable automatic handoff
✅ Parser tests validate all content sections
✅ Web rendering verified and functional
✅ Bug fixes applied and tested

---

## Issues Deferred from Milestone 2

During Milestone 2 verification, several operational improvements were identified and deferred to Milestone 3. These are not functional bugs (system works correctly) but workflow optimizations.

### Issue #1: Timestamp Accuracy in HANDOFF LOG

**Current Behavior**:
- Agent prompts contain example timestamps (e.g., "2025-10-14 17:00")
- Agents sometimes copy these example times instead of calling actual `date` command
- Results in HANDOFF LOG showing incorrect timestamps (e.g., 17:00 when actual time is 14:17)

**Impact**: Low (cosmetic issue, does not affect content generation or quality)

**Root Cause**:
- Agent prompts in `.claude/agents/*.md` (7 files) provide timestamp format examples
- Agents may use examples directly instead of executing `date` command for current time

**Proposed Solution**:
1. Update all 7 agent prompt files (`.claude/agents/*.md`)
2. Add explicit instruction: "MUST call `date` command to get actual current time"
3. Remove example timestamps or mark them clearly as "EXAMPLE ONLY - DO NOT USE"
4. Add timestamp validation check in handoff logic

**Files to Modify**:
- `.claude/agents/content-initiator.md`
- `.claude/agents/overview-writer.md`
- `.claude/agents/concepts-writer.md`
- `.claude/agents/visualization-writer.md`
- `.claude/agents/practice-writer.md`
- `.claude/agents/quiz-writer.md`
- `.claude/agents/content-validator.md`

**Verification**:
- Generate new content file and check HANDOFF LOG timestamps match actual execution time
- Run batch generation and verify all timestamps are accurate

---

### Issue #2: HANDOFF LOG Accumulation Pattern

**Current Behavior**:
- HANDOFF LOG entries accumulate (WAITING entries are not updated to DONE)
- Results in verbose log with multiple status lines per agent:
  ```
  [WAITING] overview-writer: 대기중 - 2025-10-14 14:00
  [DONE] overview-writer: 완료 - 2025-10-14 14:15
  [WAITING] concepts-writer: 대기중 - 2025-10-14 14:15
  [DONE] concepts-writer: 완료 - 2025-10-14 15:00
  ...
  ```

**Impact**: Low (reduces readability but maintains full history)

**Analysis**:
- Current accumulation pattern is **intentional design** for full history tracking
- However, can be simplified for better readability

**Proposed Solutions** (Choose one):

**Option A: Update Pattern** (Recommended)
- Change WAITING to DONE instead of adding new line
- Maintain compact log with only final states:
  ```
  [DONE] overview-writer: 완료 - 2025-10-14 14:15
  [DONE] concepts-writer: 완료 - 2025-10-14 15:00
  [IN_PROGRESS] visualization-writer: 진행중 - 2025-10-14 15:10
  ```

**Option B: Hybrid Pattern**
- Keep accumulation but compress format:
  ```
  [DONE] overview-writer: 14:00-14:15 (15min)
  [DONE] concepts-writer: 14:15-15:00 (45min)
  ```

**Option C: Keep Current Pattern**
- No changes (maintain full history)
- Add comment explaining intentional design

**Recommendation**: Option A (Update Pattern) for better readability

**Files to Modify**:
- `.claude/handoff-guide.md` (handoff pattern documentation)
- All 7 agent prompts (`.claude/agents/*.md`)

**Verification**:
- Generate new content and verify HANDOFF LOG uses new pattern
- Ensure handoff logic still works correctly with updated pattern

---

### Issue #3: Bugs Fixed in Milestone 2 (For Reference)

These functional bugs were **already fixed** in Milestone 2. Listed here for completeness:

#### Bug #1: Visualization Rendering Failure ✅ FIXED
- **Symptom**: 4 React visualizations showing "준비중" placeholder
- **Root Cause**: Missing component imports in ContentRenderer.tsx
- **Fix Applied**: Added React component rendering logic (ContentRenderer.tsx lines 365-373)
- **Status**: ✅ Verified working

#### Bug #2: Quiz Code Block Parsing Error ✅ FIXED
- **Symptom**: Question 4 lost code content during parsing
- **Root Cause**: Parser assumed question text always comes before code
- **Fix Applied**: Rewrote Question parsing logic (markdownParser.ts lines 854-890)
- **Status**: ✅ Verified working

#### Bug #3: Quiz Section Skipping Bug ✅ FIXED (CRITICAL)
- **Symptom**: 6/10 quiz questions missing options or correctAnswer arrays
- **Root Cause**: Parser index not backing up after Question parsing, causing main loop to skip next section header
- **Fix Applied**: Added `i--` at end of Question parsing (markdownParser.ts line 892)
- **Impact**: Fixed 60% of quiz questions (Q1, Q2, Q7, Q9, Q10)
- **Status**: ✅ Verified working with all 10 questions

---

## Milestone 3 Test Plan

### Phase 1: Small-Scale Batch Test (3-5 Topics)

**Objective**: Verify batch processing works correctly

**Test Topics** (Suggested):
1. `01-what-is-react.md` (Already complete - baseline)
2. `02-jsx-basics.md` (New)
3. `03-components-props.md` (New)
4. `04-state-hooks.md` (New)
5. `05-event-handling.md` (New)

**Success Criteria**:
- All topics generate successfully without manual intervention
- Each topic achieves 100/100 validation score
- Total generation time remains reasonable (<3 hours for 5 topics)
- No resource leaks or system crashes

### Phase 2: Medium-Scale Category Test (Full Category)

**Objective**: Generate entire category (10 topics)

**Test Category**: `react-core-concepts/01-react-basics/` (10 topics)

**Success Criteria**:
- All 10 topics complete successfully
- Average generation time per topic remains consistent
- Quality scores remain at 100/100
- System can run unattended for 5+ hours

### Phase 3: Multi-Category Test (3 Categories)

**Objective**: Verify system scales across multiple categories

**Test Categories**:
1. `react-core-concepts/01-react-basics/` (10 topics)
2. `react-core-concepts/02-state-management/` (10 topics)
3. `react-core-concepts/03-component-lifecycle/` (10 topics)

**Success Criteria**:
- 30 topics complete successfully
- System handles category transitions smoothly
- Total generation time <10 hours
- All parser tests pass for all generated content

---

## Performance Metrics to Track

### Generation Speed
- Lines per minute (current baseline: ~43 lines/min)
- Topics per hour (current baseline: ~1.6 topics/hour)
- Agent execution time per section

### Resource Usage
- CPU utilization
- Memory consumption
- Disk I/O
- API rate limits (Claude API calls)

### Quality Metrics
- Validation scores (target: 100/100 for all topics)
- Parser test pass rate (target: 100%)
- Web rendering success rate (target: 100%)

---

## Risk Assessment

### Identified Risks

1. **API Rate Limits**
   - Risk: Claude API may throttle requests during batch generation
   - Mitigation: Implement rate limiting and exponential backoff

2. **Lock File Conflicts**
   - Risk: Concurrent executions may clash if not properly serialized
   - Mitigation: Enhance lock file management with TTL and cleanup

3. **Quality Degradation**
   - Risk: Quality may drop as agents generate more content
   - Mitigation: Monitor validation scores; pause and review if scores drop

4. **System Resource Exhaustion**
   - Risk: Long-running batch processes may exhaust memory/disk
   - Mitigation: Monitor resources; implement cleanup routines

5. **Agent Context Loss**
   - Risk: Session context may degrade over multiple topics
   - Mitigation: Use fresh sessions per topic; limit session duration

---

## Implementation Approach

### Batch Generation Script

Create `scripts/batch-content-generator.sh` with features:
- Read topic list from category.yaml
- Execute content-generator-v6.sh sequentially for each topic
- Track progress and errors
- Generate summary report
- Implement retry logic for failures

### Monitoring Dashboard

Create simple monitoring script:
- Track active generation processes
- Display real-time metrics (speed, completion %)
- Alert on errors or quality drops
- Log all activities for post-analysis

### Automated Testing

Enhance test suite:
- Batch parser test execution
- Automated web rendering checks
- Quality score aggregation
- Performance regression detection

---

## Success Criteria for Milestone 3

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| Topics Generated | 30+ | Count of completed .md files |
| Quality Score | 100/100 | Average validation score |
| Parser Tests | 100% pass | All 5 tests × 30 topics |
| Web Rendering | 100% success | Visual verification sampling |
| Generation Speed | >40 lines/min | Average across all topics |
| System Uptime | >95% | (successful topics / total attempts) |
| Error Recovery | 100% | All failed topics resume successfully |

---

## Timeline Estimate

- **Phase 1** (5 topics): 2-3 hours
- **Phase 2** (10 topics): 5-6 hours
- **Phase 3** (30 topics): 15-18 hours (can run overnight)
- **Analysis & Documentation**: 2-3 hours

**Total**: 24-30 hours over 2-3 days

---

## Deliverables

1. **Batch Generation Script**: `scripts/batch-content-generator.sh`
2. **30+ Completed Topics**: Full learning content in markdown
3. **Performance Report**: Detailed metrics and analysis
4. **Scale Testing Report**: `milestone-3-VERIFICATION-REPORT.md`
5. **Operational Runbook**: Production deployment guide
6. **Improved Agent Prompts**: 7 updated agent files with timestamp fixes and HANDOFF LOG pattern improvements
7. **Agent Prompt Changelog**: Document all changes made to agent prompts

---

## Next Steps

### Phase 0: Workflow Optimization (Deferred Issues)
1. Fix timestamp accuracy in all 7 agent prompts
2. Improve HANDOFF LOG pattern (choose Option A/B/C)
3. Update `.claude/handoff-guide.md` with new patterns
4. Test changes with single topic generation
5. Document all agent prompt changes

### Phase 1: Batch System Development
1. Create batch generation script
2. Select test topics for Phase 1 (3-5 topics)
3. Execute Phase 1 and analyze results
4. Iterate and improve based on Phase 1 findings

### Phase 2 & 3: Scale Testing
1. Proceed to Phase 2 (10 topics) and Phase 3 (30 topics)
2. Monitor performance and quality metrics
3. Document lessons learned and best practices

---

## Dependencies

- Milestone 2 completion ✅
- Bug-free content-generator-v6.sh ✅
- Stable Claude API access ✅
- Sufficient disk space for 30+ topics (~40MB)
- Time allocation for batch runs (can be overnight)

---

## Notes

- Start with conservative batch size (Phase 1: 3-5 topics)
- Monitor closely for the first batch to catch issues early
- Use git commits to checkpoint progress
- Keep backup of generated content
- Document any new bugs or edge cases discovered

---

**Prepared By**: Claude (AI-DLC Construction Phase)
**Status**: Ready to Begin
**Next Action**: Create batch generation script and select Phase 1 test topics
