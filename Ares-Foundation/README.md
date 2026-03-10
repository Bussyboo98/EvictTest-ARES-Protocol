# Ares Foundation

Ares Foundation is a secure, modular treasury and governance system built on Ethereum. It features a multi-stage proposal lifecycle, EIP-712 signature-authorized proposals, and a timelock-protected execution mechanism.

## Core Features

- **Authorized Proposing**: Proposals require a valid EIP-712 signature from an authorized Governor.
- **Multi-Stage Lifecycle**: Proposals progress through `Proposed` -> `Committed` -> `Queued` -> `Executed`.
- **Integrated Timelock**: Mandatory delays between proposal commitment and execution to ensure community oversight.
- **Reward Distribution**: Integrated Merkle-based reward distribution system for efficient token allocations.
- **Emergency Controls**: A dedicated Emergency Guardian can cancel malicious or erroneous proposals.

## Tech Stack

- **Solidity**: ^0.8.20
- **Framework**: [Foundry](https://book.getfoundry.sh/)
- **Libraries**: OpenZeppelin Contracts

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Installation

```bash
git clone <repository-url>
cd Ares-Foundation
forge install
```

### Testing

Run the comprehensive test suite:

```bash
forge test
```

### Deployment

To deploy to a network, set up your environment variables and use the deployment script:

```bash
# Set environment variables
export DEPLOYER_ADDRESS=0x...
export EMERGENCY_GUARDIAN=0x...
export REWARD_TOKEN=0x...

# Run deployment script
forge script script/DeployAresTreasury.s.sol:DeployAresTreasury --rpc-url <your_rpc_url> --broadcast
```

## Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Security Model](SECURITY.md)

## License

MIT
