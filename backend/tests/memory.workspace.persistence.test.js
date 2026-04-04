const memoryService = require("../src/agents/efficiency_plan/shared/memoryService");
const memoryStore = require("../src/agents/efficiency_plan/shared/memoryStore.redis");
const {
  validIdentity,
  validProvenanceEvent,
} = require("./helpers/memoryFixtures");

describe("memory workspace persistence", () => {
  beforeEach(() => {
    memoryStore.__resetForTests();
  });

  it("persists append-only revisions", async () => {
    await memoryService.writeEvent({
      ...validProvenanceEvent,
      revisionId: "rev-1",
      payload: { x: 1 },
    });

    await memoryService.writeEvent({
      ...validProvenanceEvent,
      revisionId: "rev-2",
      payload: { x: 2 },
    });

    const events = await memoryService.getRecent(validIdentity, { limit: 10 });
    expect(events).toHaveLength(2);
    expect(events[0].revisionId).toBe("rev-1");
    expect(events[1].revisionId).toBe("rev-2");
  });

  it("keeps reads thread scoped", async () => {
    await memoryService.writeEvent({
      ...validProvenanceEvent,
      revisionId: "a",
    });
    await memoryService.writeEvent({
      ...validProvenanceEvent,
      threadId: "thread-2",
      revisionId: "b",
    });

    const t1 = await memoryService.getRecent(validIdentity, { limit: 10 });
    expect(t1).toHaveLength(1);
    expect(t1[0].threadId).toBe("thread-1");
  });
});
