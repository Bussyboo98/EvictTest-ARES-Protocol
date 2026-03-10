// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/AresTreasury.sol";
import "../src/modules/RewardDistributor.sol";
import "../src/interface/IAresTreasury.sol";
import "../src/libraries/ProposalCodec.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MockERC20 is IERC20 {
    string public name = "Mock";
    string public symbol = "MCK";
    uint8 public decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(balanceOf[from] >= amount, "balance");
        require(allowance[from][msg.sender] >= amount, "allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract ReentrancyMalicious {
    AresTreasury public treasury;
    TreasuryAction[] public actions;
    bool public entered;

    constructor(AresTreasury _treasury) {
        treasury = _treasury;
    }

    function setActions(TreasuryAction[] calldata _actions) external {
        delete actions;
        for (uint256 i = 0; i < _actions.length; i++) actions.push(_actions[i]);
    }

    function reenter() external {
        if (!entered) {
            entered = true;
            treasury.execute(1, actions);
        }
    }

    receive() external payable {
        
    }
}

contract AresTreasuryTest is Test {
    AresTreasury public treasury;
    RewardDistributor public distributor;
    MockERC20 public token;

    address public gov;
    uint256 public govKey;
    address public proposer;
    uint256 public proposerKey;
    address public attacker;
    uint256 public attackerKey;
    address public guardian;

   function setUp() public {
    govKey = 0xA1;
    gov = vm.addr(govKey);
    proposerKey = 0xA2;
    proposer = vm.addr(proposerKey);
    attackerKey = 0xA3;
    attacker = vm.addr(attackerKey);
    guardian = vm.addr(0xA4);

    address[] memory govs = new address[](1);
    govs[0] = gov;
    treasury = new AresTreasury(govs, guardian);

    token = new MockERC20();
    token.mint(address(treasury), 1_000_000 ether);

    distributor = new RewardDistributor(IERC20(address(token)), address(treasury));

    vm.prank(gov);
    treasury.setRewardDistributor(address(distributor));

    vm.deal(address(treasury), 100 ether);
}

    function _signProposal(
    address proposerAddr,
    uint256 proposerNonce,
    bytes32 actionsHash,
    uint256 deadline
) internal view returns (bytes memory) {
    bytes32 structHash = keccak256(
        abi.encode(
            treasury.PROPOSAL_TYPEHASH(),
            proposerAddr,
            proposerNonce,
            actionsHash,
            deadline
        )
    );

    bytes32 digest = keccak256(
        abi.encodePacked("\x19\x01", treasury.DOMAIN_SEPARATOR(), structHash)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(govKey, digest);
    return abi.encodePacked(r, s, v);
}

    function testProposalLifecycle() public {
        TreasuryAction[] memory actions = new TreasuryAction[](1);
        actions[0] = TreasuryAction({
            actionType: TreasuryActionType.ERC20_TRANSFER,
            target: address(token),
            recipient: proposer,
            value: 100 ether,
            data: ""
        });

        bytes32 actionsHash = ProposalCodec.hashActions(actions);
        bytes memory sig = _signProposal(proposer, 0, actionsHash, block.timestamp + 1 days);

        vm.prank(proposer);
        uint256 pid = treasury.propose(actions, block.timestamp + 1 days, sig);
        assertEq(pid, 1);

        vm.warp(block.timestamp + treasury.COMMIT_DELAY());
        vm.prank(gov);
        treasury.commit(1);

        vm.warp(block.timestamp + treasury.TIMELOCK_DELAY());
        treasury.execute(1, actions);

        assertEq(token.balanceOf(proposer), 100 ether);
    }

    function testInvalidSignatureReverts() public {
    TreasuryAction[] memory actions = new TreasuryAction[](1);
    actions[0] = TreasuryAction({
        actionType: TreasuryActionType.ERC20_TRANSFER,
        target: address(token),
        recipient: proposer,
        value: 1 ether,
        data: ""
    });

    bytes32 actionsHash = ProposalCodec.hashActions(actions);

    bytes32 structHash = keccak256(
        abi.encode(
            treasury.PROPOSAL_TYPEHASH(),
            proposer,
            0,
            actionsHash,
            block.timestamp + 1 days
        )
    );
    bytes32 digest = keccak256(
        abi.encodePacked("\x19\x01", treasury.DOMAIN_SEPARATOR(), structHash)
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(attackerKey, digest);
    bytes memory badSig = abi.encodePacked(r, s, v);

    vm.prank(proposer);
    vm.expectRevert("invalid approver");
    treasury.propose(actions, block.timestamp + 1 days, badSig);
}

    function testPrematureCommitReverts() public {
        TreasuryAction[] memory actions = new TreasuryAction[](1);
        actions[0] = TreasuryAction({
            actionType: TreasuryActionType.ERC20_TRANSFER,
            target: address(token),
            recipient: proposer,
            value: 1 ether,
            data: ""
        });

        bytes32 actionsHash = ProposalCodec.hashActions(actions);
        bytes memory sig = _signProposal(proposer, 0, actionsHash, block.timestamp + 1 days);

        vm.prank(proposer);
        treasury.propose(actions, block.timestamp + 1 days, sig);

        vm.prank(gov);
        vm.expectRevert("commit locked");
        treasury.commit(1);
    }

    function testPrematureExecuteReverts() public {
        TreasuryAction[] memory actions = new TreasuryAction[](1);
        actions[0] = TreasuryAction({
            actionType: TreasuryActionType.ERC20_TRANSFER,
            target: address(token),
            recipient: proposer,
            value: 1 ether,
            data: ""
        });

        bytes32 actionsHash = ProposalCodec.hashActions(actions);
        bytes memory sig = _signProposal(proposer, 0, actionsHash, block.timestamp + 1 days);

        vm.prank(proposer);
        treasury.propose(actions, block.timestamp + 1 days, sig);

        vm.warp(block.timestamp + treasury.COMMIT_DELAY());
        vm.prank(gov);
        treasury.commit(1);

        vm.warp(block.timestamp + treasury.TIMELOCK_DELAY() - 1);
        vm.expectRevert("timelock");
        treasury.execute(1, actions);
    }

    function testReplayNoncePreventsReuse() public {
        TreasuryAction[] memory actions = new TreasuryAction[](1);
        actions[0] = TreasuryAction({
            actionType: TreasuryActionType.ERC20_TRANSFER,
            target: address(token),
            recipient: proposer,
            value: 1 ether,
            data: ""
        });

        bytes32 actionsHash = ProposalCodec.hashActions(actions);
        bytes memory sig = _signProposal(proposer, 0, actionsHash, block.timestamp + 1 days);

        vm.prank(proposer);
        treasury.propose(actions, block.timestamp + 1 days, sig);

        vm.prank(proposer);
        vm.expectRevert("invalid approver");
        treasury.propose(actions, block.timestamp + 1 days, sig);
    }

    function testCancelAndUnauthorizedCancel() public {
        TreasuryAction[] memory actions = new TreasuryAction[](1);
        actions[0] = TreasuryAction({
            actionType: TreasuryActionType.ERC20_TRANSFER,
            target: address(token),
            recipient: proposer,
            value: 1 ether,
            data: ""
        });

        bytes32 actionsHash = ProposalCodec.hashActions(actions);
        bytes memory sig = _signProposal(proposer, 0, actionsHash, block.timestamp + 1 days);

        vm.prank(proposer);
        treasury.propose(actions, block.timestamp + 1 days, sig);
       
        //atacker can't cancel before proposer
        vm.prank(attacker);
        vm.expectRevert("not authorized");
        treasury.cancel(1);

         // proposer cancels
        vm.prank(proposer);
        treasury.cancel(1);

        //  now terminal path
        vm.prank(attacker);
        vm.expectRevert("terminal");
        treasury.cancel(1);
    }

   function testReentrancyGuard() public {
        ReentrancyMalicious evil = new ReentrancyMalicious(treasury);

        TreasuryAction[] memory evilActions = new TreasuryAction[](1);
        evilActions[0] = TreasuryAction({
            actionType: TreasuryActionType.ERC20_TRANSFER,
            target: address(token),
            recipient: proposer,
            value: 1 ether,
            data: ""
        });
        evil.setActions(evilActions);

        TreasuryAction[] memory actions = new TreasuryAction[](1);
        actions[0] = TreasuryAction({
            actionType: TreasuryActionType.CALL,
            target: address(evil),
            recipient: address(0),
            value: 0,
            data: abi.encodeWithSignature("reenter()")
        });

        bytes32 actionsHash = ProposalCodec.hashActions(actions);
        bytes memory sig = _signProposal(proposer, 0, actionsHash, block.timestamp + 1 days);

        vm.prank(proposer);
        treasury.propose(actions, block.timestamp + 1 days, sig);

        vm.warp(block.timestamp + treasury.COMMIT_DELAY());
        vm.prank(gov);
        treasury.commit(1);
        vm.warp(block.timestamp + treasury.TIMELOCK_DELAY());

        vm.expectRevert();
        treasury.execute(1, actions);
    }

    function testRewardClaims() public {
        bytes32 leaf = keccak256(abi.encodePacked(uint256(0), proposer, uint256(10 ether)));
        bytes32 root = leaf;
        vm.prank(address(treasury));
        distributor.pushMerkleRoot(root);

        token.mint(address(distributor), 10 ether);

        vm.prank(proposer);
        distributor.claim(1, 0, 10 ether, new bytes32[](0));
        assertEq(token.balanceOf(proposer), 10 ether);

        vm.prank(proposer);
        vm.expectRevert("already claimed");
        distributor.claim(1, 0, 10 ether, new bytes32[](0));

        vm.prank(proposer);
        vm.expectRevert("invalid proof");
        distributor.claim(1, 1, 1 ether, new bytes32[](0));
    }
}