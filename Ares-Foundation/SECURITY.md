# Security Model - Ares Foundation

Security is the primary directive of the Ares Foundation. The system employs multiple layers of defense to protect treasury assets.

## Major Attack Surfaces

The system identifies several key risks that could threaten security:

-Proposal Spoofing: Unauthorized users attempting to submit fake proposals or forge signatures.

-Reentrancy Attacks: Malicious contracts trying to repeatedly withdraw funds during execution.

-Replay Attacks: Attempting to reuse old signatures to execute actions multiple times.

-Timelock Bypass: Executing proposals before the intended waiting period.

-Merkle Reward Exploits: Claiming rewards multiple times or with invalid proofs.

## How We Mitigate Risks

Ares Foundation implements robust controls to prevent these threats:

-EIP-712 Signature Verification: Only authorized Governors can create proposals.

-ReentrancyGuard: Protects against repeated calls during execution.

-Nonces: Ensure that signatures cannot be reused, preventing replay attacks.

-Timelock Delays: Introduce a waiting period before proposals can be executed, allowing oversight and intervention.

-Merkle Proof Verification: Ensures that only legitimate reward claims are accepted.

## Remaining Risks

Despite the safeguards, some risks remain:

-Compromised Governor Key: If a Governor’s key is stolen, malicious proposals could be approved.

-Guardian Centralization: The Emergency Guardian has the power to cancel proposals. Misuse could block legitimate actions, though funds cannot be withdrawn.

-Smart Contract Bugs: As with any software, undiscovered bugs could create vulnerabilities, highlighting the importance of audits and careful testing.

# Security Controls
### 1. Cryptographic Authorization

All proposals require a valid signature from an authorized Governor.

Bound Signatures: Each signature is tied to this specific contract instance (DOMAIN_SEPARATOR).

Nonces: Prevent signatures from being reused.

Clear Signing Data: Users see structured and understandable data in their wallets before approving.

### 2. Time-Based Defenses

Commit Delay: Prevents proposals from being committed instantly, avoiding sudden changes.

Timelock Delay: Provides a 48-hour window for community members or the Guardian to respond.

Grace Period: Proposals must be executed within 7 days, preventing outdated or irrelevant actions from being executed later.

### 3. Execution Safeguards

Reentrancy Guard: All execution paths are protected against repeated calls.

Value Cap: Limits the maximum impact of any single action (e.g., MAX_ACTION_VALUE = 500,000 ETH).

Action Hashing: The actions executed must match exactly the ones originally signed in the proposal.

4. Emergency Procedures

The Emergency Guardian can cancel any pending or queued proposal if malicious activity is detected.

The Guardian cannot withdraw funds; their role is purely defensive.

# Best Practices for Governors

Use hardware wallets (HSMs) to securely store Governor keys.

Monitor ProposalCreated events on-chain to track new proposals.

Regularly audit the list of authorized Governors to ensure only trusted accounts have access.
