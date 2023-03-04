// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TableLib.sol";

contract CardGame {
    IERC20 public token;

    uint256 public pot = 0;
    uint256 public minBet;
    uint256 public maxBet;

    mapping(address => TableLib.Holder) private addressHoldersMap;

    constructor(
        IERC20 _token,
        uint256 _minBet,
        uint256 _maxBet
    ) {
        token = _token;
        minBet = _minBet;
        maxBet = _maxBet;
    }

    modifier canBet() {}

    function buyIn(uint256 _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
        addressHoldersMap[msg.sender].betAmount += _amount;
        pot += _amount;
    }
}
