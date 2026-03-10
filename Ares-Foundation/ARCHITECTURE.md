# System Architecture – Ares Foundation

The Ares Foundation architecture is designed for security, modularity, and transparency. Core treasury logic is separated from governance rules and utility modules, making the system easier to audit, maintain, and upgrade. Each component has a well-defined role, ensuring that critical operations, such as fund transfers and proposal execution, are controlled and traceable.

# Component Overview
1. Core: AresTreasury

The AresTreasury contract is the central hub of the system. It holds all funds, manages the proposal lifecycle, and executes approved actions. By interacting with specialized modules, it maintains a clean separation of concerns, preventing logic duplication and minimizing potential attack surfaces.

2. Modules

AuthorizationModule: Responsible for verifying EIP-712 signatures and managing nonces to ensure proposals are authorized and cannot be replayed.

ProposalModule: Handles the storage, hashing, and integrity checks of all proposals submitted to the treasury.

TimelockModule: Implements queuing logic and enforces execution delays, giving the community or emergency guardian time to intervene if necessary.

RewardDistributor: An external contract linked to the treasury, responsible for Merkle-based reward distributions, enabling efficient and verifiable token allocations.

GovernanceGuard: Adds cooldowns and action limits to prevent rapid, repeated changes that could jeopardize system security.

3. Libraries

ProposalCodec: Standardizes hashing of TreasuryAction arrays to ensure consistent proposal identification.

SignatureVerifier: Provides low-level EIP-191/EIP-712 signature recovery utilities.

MerkleClaiming: Verifies Merkle tree proofs efficiently for reward claims.

TimelockQueuing: Supports internal logic for managing execution ETAs and delays.

Proposal Lifecycle

Propose – A user submits a list of TreasuryActions along with a Governor’s EIP-712 signature.

Commit Delay – The proposal enters a pending state for COMMIT_DELAY (e.g., 1 day) before it can be committed.

Commit – A Governor triggers commitment, calculating the final ETA for execution.

Timelock – The proposal waits for TIMELOCK_DELAY (e.g., 2 days) to pass, providing oversight and intervention time.

Execute – Anyone can trigger execution after the ETA, provided it occurs within the GRACE_PERIOD (e.g., 7 days).

Cancel – The proposer or Emergency Guardian can cancel the proposal at any point before execution.

# Permissioning Model

Governors – Authorize proposals, commit them, and manage other governors.

Emergency Guardian – Cancels malicious proposals but cannot authorize or execute them.

Proposer – Submits proposals and may cancel their own proposals.

# Security Boundaries

Treasury funds can only be moved through executed proposals.

Reward claims require valid Merkle proofs.

Emergency Guardian can cancel proposals but cannot withdraw funds directly.

# Trust Assumptions

Governors are trusted to propose and approve valid actions.

Users rely on the Guardian to act only in emergencies.

The system depends on Ethereum network security and the immutability of deployed smart contracts.

