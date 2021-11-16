// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IBentoBoxMinimal.sol";
import "./BoringBatchable.sol";

contract HelloBentoBox is BoringBatchable {
    struct Deposits {
        address user;
        address token;
        uint256 depositedShares;
        uint256 amount;
    }

    IBentoBoxMinimal public immutable bentoBox;

    address public owner;

    uint256 public totalDeposits;

    mapping(uint256 => Deposits) public deposits;

    constructor(IBentoBoxMinimal _bentoBox) {
        owner = msg.sender;
        bentoBox = _bentoBox;
        _bentoBox.registerProtocol();
    }
    
    // TODO: add vrs back in
    function setBentoBoxApproval(
        address user,
        bool approved
    ) external {
        bentoBox.setMasterContractApproval(
            user,
            address(this),
            approved
        );
    }

    function depositToHelloBentoBox(
        address token,
        uint256 amount,
        bool fromBentoBox
    ) external returns (uint256 depositedShares) {
        if (fromBentoBox) {
            depositedShares = bentoBox.toShare(token, amount, false);
            bentoBox.transfer(
                token,
                msg.sender,
                address(this),
                depositedShares
            );
        } else {
            (, depositedShares) = bentoBox.deposit(
                token,
                msg.sender,
                address(this),
                amount,
                0
            );
        }

        deposits[totalDeposits] = Deposits({
            user: msg.sender,
            token: token,
            depositedShares: depositedShares,
            amount: amount
        });

        totalDeposits += 1;
    }

    function withdrawFromHelloBentoBox(
        uint256 depositId,
        uint256 amount,
        bool toBentoBox
    ) external returns (uint256 sharesWithdrawn) {
        Deposits storage deposit = deposits[depositId];
        require(msg.sender == deposit.user, "user not onwer of deposit");
        sharesWithdrawn = bentoBox.toShare(deposit.token, amount, false);
        require(
            sharesWithdrawn <= deposit.depositedShares,
            "withdraw more than available"
        );
        
        deposit.depositedShares -= sharesWithdrawn;

        if (toBentoBox) {
            bentoBox.transfer(
                deposit.token,
                address(this),
                deposit.user,
                sharesWithdrawn
            );
        } else {
            bentoBox.withdraw(
                deposit.token,
                address(this),
                deposit.user,
                0,
                sharesWithdrawn
            );
        }
    }
}
