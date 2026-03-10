# System Architecture - Ares Foundation

The Ares Foundation architecture is designed for security, modularity, and transparency. It separates core treasury logic from governance rules and utility modules.

## Component Overview

### 1. Core: AresTreasury
The central hub of the system. It holds the funds and manages the proposal state machine. It inherits from several modules to maintain a clean separation of concerns.

### 2. Modules
- **AuthorizationModule**: Handles EIP-712 signature verification and nonce management.
- **ProposalModule**: Manages the storage and hashing of proposal data.
- **TimelockModule**: Implements the queuing logic and execution delays.
- **RewardDistributor**: An external contract (linked to the Treasury) that manages Merkle-based reward claims.
- **GovernanceGuard**: Provides cooldowns and action limits to prevent governance exhaustion.

### 3. Libraries
- **ProposalCodec**: Standardized hashing for `TreasuryAction` arrays.
- **SignatureVerifyer**: Low-level EIP-191/EIP-712 recovery utilities.
- **MerkleClaiming**: Efficient bit-mapped Merkle tree verification.
- **TimelockQueuing**: Internal logic for managing execution ETAs.

## Proposal Lifecycle

1. **Propose**: A user submits a list of `TreasuryAction`s along with a Governor's EIP-712 signature.
2. **Commit Delay**: The proposal enters a "pending" state for `COMMIT_DELAY` (1 day).
3. **Commit**: A Governor triggers the commitment. This calculates the final `ETA` for execution.
4. **Timelock**: The proposal must wait for the `TIMELOCK_DELAY` (2 days) to pass.
5. **Execute**: Anyone can trigger execution if the `ETA` has passed and the proposal is within its `GRACE_PERIOD` (7 days).
6. **Cancel**: The proposer or a Governor/Guardian can cancel the proposal at any time before execution.

## Permissioning Model

- **Governors**: Can authorize proposals, commit proposals, and add/remove other governors.
- **Emergency Guardian**: Has the power to cancel proposals but cannot authorize or execute them.
- **Proposer**: The account that submits the proposal; can cancel their own proposal.
