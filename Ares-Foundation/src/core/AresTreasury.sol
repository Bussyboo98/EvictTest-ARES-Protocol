// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IAresTreasury.sol";
import "../libraries/ProposalCodec.sol";
import "../modules/RewardDistributor.sol";


contract AresTreasury is IAresTreasury, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PROPOSAL_TYPEHASH =
        keccak256("Proposal(address proposer,uint256 nonce,bytes32 actionsHash,uint256 deadline)");

    uint256 public constant COMMIT_DELAY = 1 days;
    uint256 public constant TIMELOCK_DELAY = 2 days;
    uint256 public constant GRACE_PERIOD = 7 days;
    uint256 public constant MAX_ACTION_VALUE = 500_000 ether;

    mapping(address => bool) public governors;
    mapping(address => uint256) public nonces;
    mapping(uint256 => ProposalData) public proposals;
    mapping(bytes32 => bool) public queuedTx;

    uint256 public proposalCount;
    RewardDistributionModule public rewardDistributor;
    address public emergencyGuardian;

    event GovernorAdded(address indexed account);
    event GovernorRemoved(address indexed account);

    struct ProposalData {
        address proposer;
        bytes32 actionsHash;
        uint256 committedAt;
        uint256 eta;
        bool committed;
        bool queued;
        bool executed;
        bool cancelled;
    }

    event EmergencyGuardianChanged(address indexed guardian);
    event RewardDistributorSet(address indexed distributor);

    constructor(address[] memory initialGovernors, address _emergencyGuardian) {
        require(initialGovernors.length > 0, "Needs at least one governor");
        for (uint256 i = 0; i < initialGovernors.length; i++) {
            governors[initialGovernors[i]] = true;
            emit GovernorAdded(initialGovernors[i]);
        }
        require(_emergencyGuardian != address(0), "guardian zero");
        emergencyGuardian = _emergencyGuardian;
        emit EmergencyGuardianChanged(_emergencyGuardian);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("ARES Treasury")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    modifier onlyGovernor() {
        require(governors[msg.sender], "Not governor");
        _;
    }

    modifier onlyGovernorOrGuardian() {
        require(governors[msg.sender] || msg.sender == emergencyGuardian, "Not authorized");
        _;
    }

    function setRewardDistributor(address distributor) external onlyGovernor {
        require(distributor != address(0), "zero distributor");
        rewardDistributor = RewardDistributionModule(distributor);
        emit RewardDistributorSet(distributor);
    }

    function setEmergencyGuardian(address guardian) external onlyGovernor {
        require(guardian != address(0), "zero guardian");
        emergencyGuardian = guardian;
        emit EmergencyGuardianChanged(guardian);
    }

    function addGovernor(address account) external onlyGovernor {
        governors[account] = true;
        emit GovernorAdded(account);
    }

    function removeGovernor(address account) external onlyGovernor {
        governors[account] = false;
        emit GovernorRemoved(account);
    }

    function propose(
        TreasuryAction[] calldata actions,
        uint256 deadline,
        bytes calldata approverSignature
    ) external override returns (uint256 proposalId) {
        require(actions.length > 0, "actions empty");
        require(block.timestamp <= deadline, "deadline passed");

        bytes32 actionsHash = ProposalCodec.hashActions(actions);
        uint256 nonce = nonces[msg.sender];

        bytes32 structHash = keccak256(
            abi.encode(
                PROPOSAL_TYPEHASH,
                msg.sender,
                nonce,
                actionsHash,
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = digest.recover(approverSignature);
        require(governors[signer], "invalid approver");

        nonces[msg.sender] = nonce + 1;
        proposalCount += 1;
        proposalId = proposalCount;

        proposals[proposalId] = ProposalData({
            proposer: msg.sender,
            actionsHash: actionsHash,
            committedAt: block.timestamp + COMMIT_DELAY,
            eta: 0,
            committed: false,
            queued: false,
            executed: false,
            cancelled: false
        });

        emit ProposalCreated(proposalId, msg.sender);
    }

   

    function queue(uint256 proposalId) external override onlyGovernor {
        ProposalData storage p = proposals[proposalId];
        require(p.committed, "not committed");
        require(!p.queued, "already queued");
        require(!p.cancelled, "cancelled");

        p.eta = block.timestamp + TIMELOCK_DELAY;
        p.queued = true;

        bytes32 txId = keccak256(abi.encodePacked(proposalId, p.actionsHash, p.eta));
        queuedTx[txId] = true;

        emit ProposalQueued(proposalId, p.eta);
    }

    

    function commit(uint256 proposalId) external override onlyGovernor {
        ProposalData storage p = proposals[proposalId];
        require(!p.cancelled, "cancelled");
        require(!p.committed, "already committed");
        require(block.timestamp >= p.committedAt, "commit locked");

        p.committed = true;
         p.eta = block.timestamp + TIMELOCK_DELAY;
        p.queued = true;

        bytes32 txId = keccak256(abi.encodePacked(proposalId, p.actionsHash, p.eta));
        queuedTx[txId] = true;

        emit ProposalCommitted(proposalId);
        emit ProposalQueued(proposalId, p.eta);
    }

    function execute(uint256 proposalId, TreasuryAction[] calldata actions)
        external
        payable
        override
        nonReentrant
    {
        ProposalData storage p = proposals[proposalId];
        require(p.queued && !p.executed && !p.cancelled, "invalid state");
        require(block.timestamp >= p.eta, "timelock");
        require(block.timestamp <= p.eta + GRACE_PERIOD, "expired");
        require(ProposalCodec.hashActions(actions) == p.actionsHash, "action mismatch");

        bytes32 txId = keccak256(abi.encodePacked(proposalId, p.actionsHash, p.eta));
        require(queuedTx[txId], "not queued");
        queuedTx[txId] = false;

        p.executed = true;
        _executeActions(actions);

        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) external override {
        ProposalData storage p = proposals[proposalId];
        require(!p.executed && !p.cancelled, "terminal");
        require(msg.sender == p.proposer || governors[msg.sender], "not authorized");
        p.cancelled = true;

        if (p.queued) {
            bytes32 txId = keccak256(abi.encodePacked(proposalId, p.actionsHash, p.eta));
            queuedTx[txId] = false;
        }

        emit ProposalCancelled(proposalId);
    }

    function getProposal(uint256 proposalId)
        external
        view
        override
        returns (Proposal memory)
    {
        ProposalData storage p = proposals[proposalId];
        return Proposal({
            proposer: p.proposer,
            executeAfter: p.eta,
            executed: p.executed,
            cancelled: p.cancelled
        });
    }

    function _executeActions(TreasuryAction[] calldata actions) internal {
        for (uint256 i = 0; i < actions.length; i++) {
            TreasuryAction calldata a = actions[i];
            require(a.value <= MAX_ACTION_VALUE, "value cap");

            if (a.actionType == TreasuryActionType.ETH_TRANSFER) {
                require(a.target == address(0), "eth target");
                (bool ok, ) = a.recipient.call{value: a.value}("");
                require(ok, "eth transfer failed");
            } else if (a.actionType == TreasuryActionType.ERC20_TRANSFER) {
                IERC20(a.target).transfer(a.recipient, a.value);
            } else if (a.actionType == TreasuryActionType.CALL) {
                (bool ok, ) = a.target.call{value: a.value}(a.data);
                require(ok, "call failed");
            } else if (a.actionType == TreasuryActionType.UPGRADE) {
                (bool ok, ) = a.target.call{value: a.value}(a.data);
                require(ok, "upgrade failed");
            } else {
            (bool ok, bytes memory data) = a.target.call{value: a.value}(a.data);
            if (!ok) {
                if (data.length > 0) {
                    assembly {
                        revert(add(data, 32), mload(data))
                    }
                } else {
                    revert("call failed");
                }
            }
        }
    }
    }
}