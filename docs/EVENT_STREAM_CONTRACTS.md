# Event Stream Contracts & Buffering

## Stream Contracts
1. **FIFO Guarantee**: Events emitted sequentially retain strict first-in-first-out order.
2. **Buffering Policies**:
   - `Snapshots`: `.bufferingNewest(5)` - Guarantees UI and consumers always observe fresh state without blocking producers.
   - `High-Frequency Events`: `.bufferingNewest(50)` / `.bufferingNewest(100)` for sensor packets and workout samples.
   - `Critical Notifications`: `.bufferingNewest(20)` for turn cues, off-route warnings, and climb alerts.
3. **Multi-Subscriber Independence**: Handled via `AsyncEventChannel`, preventing single-continuation hijacking when multiple components subscribe to domain snapshots.
