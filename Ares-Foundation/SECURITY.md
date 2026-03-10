# Security Model - Ares Foundation

Security is the primary directive of the Ares Foundation. The system employs multiple layers of defense to protect treasury assets.

## Security Controls

### 1. Cryptographic Authorization
Proposals cannot be created without a valid signature from an authorized Governor. By using EIP-712, we ensure that:
- Signatures are bound to a specific contract instance (via `DOMAIN_SEPARATOR`).
- Signatures cannot be replayed (via nonces).
- Users see clear, structured data when signing in their wallets.

### 2. Time-Based Defenses
- **Commit Delay**: Prevents "flash" proposals from being committed immediately.
- **Timelock Delay**: Provides a 48-hour window for the community to react (or for the Guardian to intervene) before any action is executed.
- **Grace Period**: Proposals expire if not executed within 7 days, preventing "stale" transactions from being executed in a different market context.

### 3. Execution Safeguards
- **Reentrancy Guard**: All execution paths are protected against reentrancy attacks.
- **Value Cap**: A hard-coded `MAX_ACTION_VALUE` (500,000 ETH) limits the maximum impact of any single action.
- **Action Hashing**: The exact actions signed at the proposal stage must match the actions provided at the execution stage.

### 4. Emergency Procedures
In the event of a compromised Governor key or a malicious proposal:
- The **Emergency Guardian** can immediately cancel any pending or queued proposal.
- The Guardian cannot move funds; their role is purely defensive.

## Best Practices for Governors
- Use hardware wallets (HSMs) for Governor keys.
- Monitor the `ProposalCreated` events on-chain.
- Regularly audit the list of authorized Governors.

## Reporting Vulnerabilities
If you discover a security vulnerability, please report it via [security@aresfoundation.io](mailto:security@aresfoundation.io) or via our Bug Bounty program on Immunefi (if applicable). Do not open a public issue for security-related bugs.
