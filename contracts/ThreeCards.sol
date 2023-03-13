// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./TableLib.sol";

contract ThreeCard is Ownable {
    IERC20 public token;

    uint256 public pot = 0;
    uint256 public minBet;
    uint256 public maxBet;

    uint256[] private cards;

    address winner;

    uint256 private _idx = 0;
    mapping(uint256 => address) private index;
    mapping(address => Holder) private addressHoldersMap;

    constructor(IERC20 _token, uint256 _minBet, uint256 _maxBet) {
        token = _token;
        minBet = _minBet;
        maxBet = _maxBet;
        TableLib.freshUnbox(cards);
    }

    modifier canBet(uint256 _amount) {
        require(winner == address(0), "game over");
        require(addressHoldersMap[msg.sender].betAmount == 0, "already bet");
        require(
            _amount >= minBet && _amount <= maxBet,
            "bet amount must in range"
        );
        _;
    }

    function buyIn(uint256 _amount) public canBet(_amount) {
        token.transfer(address(this), _amount);
        Holder storage holder = addressHoldersMap[msg.sender];
        /** Add data */
        holder.betAmount += _amount;
        TableLib.pickCards(cards, holder, 3);
        /** Indexing */
        index[_idx] = msg.sender;
        _idx += 1;
        /** Increase pot amount */
        pot += _amount;
    }

    function getBet() public view returns (Holder memory) {
        return addressHoldersMap[msg.sender];
    }

    function showOff() public onlyOwner {
        uint256 max = 0;
        address w;
        for (uint256 i = 0; i < _idx; i++) {
            Holder memory holder = addressHoldersMap[index[i]];
            uint256 sum = 0;
            for (uint256 j = 0; j < holder.cards.length; j++) {
                sum += holder.cards[j];
            }
            sum %= 13;
            if (sum > max) {
                max = sum;
                w = index[i];
            }
        }
        winner = w;
    }

    modifier canWithdrawn() {
        require(msg.sender == winner, "you are loser");
        _;
    }

    function withdrawn() public canWithdrawn {
        token.transferFrom(address(this), msg.sender, pot);
    }
}
