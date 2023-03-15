// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./TableLib.sol";

contract ThreeCards {
    using TableLib for *;

    struct GameData {
        address dealer;
        IERC20 token;
        uint256 pot;
        uint256 minBet;
        uint256 maxBet;
        address[] winners;
    }

    struct Game {
        address dealer;
        IERC20 token;
        uint256 pot;
        uint256 wonAmount;
        uint256 minBet;
        uint256 maxBet;
        uint256[] cards;
        address[] winners;
        address[] holderIdxs;
        mapping(address => Holder) addressHolders;
    }

    uint256 private gameIdx = 1;
    mapping(uint256 => Game) private games;

    event GameCreated(uint256 gameId, address dealer);

    modifier gameExists(uint256 _gameId) {
        require(_gameId < gameIdx, "game not found");
        _;
    }

    modifier canBet(uint256 _gameId, uint256 _amount) {
        Game storage game = games[_gameId];
        require(game.winners.length == 0, "game over");
        require(game.addressHolders[msg.sender].betAmount == 0, "already bet");
        require(
            _amount >= game.minBet && _amount <= game.maxBet,
            "bet amount must in range"
        );
        _;
    }

    modifier onlyDealer(uint256 _gameId) {
        Game storage game = games[_gameId];
        require(game.dealer == msg.sender, "cannot show off");
        _;
    }

    function initGame(IERC20 _token, uint256 _minBet, uint256 _maxBet) public {
        /** Take current idx */
        uint256 gameId = gameIdx;
        /** Set data */
        Game storage game = games[gameId];
        game.dealer = msg.sender;
        game.token = _token;
        game.minBet = _minBet;
        game.maxBet = _maxBet;
        TableLib.freshUnbox(game.cards);
        /** increase idx */
        gameIdx += 1;
        /** emit event */
        emit GameCreated(gameId, game.dealer);
    }

    function buyIn(
        uint256 _gameId,
        uint256 _amount
    ) public gameExists(_gameId) canBet(_gameId, _amount) {
        Game storage game = games[_gameId];
        game.token.transferFrom(msg.sender, address(this), _amount);
        Holder storage holder = game.addressHolders[msg.sender];
        /** Add data */
        holder.betAmount += _amount;
        TableLib.pickCards(game.cards, holder, 3);
        /** Indexing */
        game.holderIdxs.push(msg.sender);
        /** Increase pot amount */
        game.pot += _amount;
    }

    function getGameData(
        uint256 _gameId
    ) public view gameExists(_gameId) returns (GameData memory) {
        Game storage game = games[_gameId];
        return
            GameData({
                dealer: game.dealer,
                token: game.token,
                pot: game.pot,
                minBet: game.minBet,
                maxBet: game.maxBet,
                winners: game.winners
            });
    }

    function getBet(
        uint256 _gameId
    ) public view gameExists(_gameId) returns (Holder memory) {
        Game storage game = games[_gameId];
        return game.addressHolders[msg.sender];
    }

    function showOff(
        uint256 _gameId
    ) public gameExists(_gameId) onlyDealer(_gameId) {
        Game storage game = games[_gameId];
        uint256 max = 0;
        uint256[] memory pointsIdxs = new uint256[](game.holderIdxs.length);
        for (uint256 i = 0; i < game.holderIdxs.length; i++) {
            Holder memory holder = game.addressHolders[game.holderIdxs[i]];
            /** Calculate sum */
            uint256 sum = 0;
            for (uint256 j = 0; j < holder.cards.length; j++) {
                if (holder.cards[j] > 10) {
                    sum += 10;
                } else {
                    sum += holder.cards[j];
                }
            }
            sum %= 10;
            /** temporaly store its */
            pointsIdxs[i] = sum;
            /** check the max */
            if (sum > max) {
                max = sum;
            }
        }
        /** filter winners */
        for (uint i = 0; i < game.holderIdxs.length; i++) {
            if (pointsIdxs[i] == max) {
                game.winners.push(game.holderIdxs[i]);
            }
        }
        game.wonAmount = game.pot / game.winners.length;
    }

    modifier canWithdraw(uint256 _gameId) {
        Game storage game = games[_gameId];
        bool isWinner = false;
        for (uint i = 0; i < game.winners.length; i++) {
            if (game.winners[i] == msg.sender) {
                isWinner = true;
                break;
            }
        }
        require(isWinner, "you are loser");
        _;
    }

    function withdraw(
        uint256 _gameId
    ) public gameExists(_gameId) canWithdraw(_gameId) {
        Game storage game = games[_gameId];
        game.token.transfer(msg.sender, game.wonAmount);
    }
}
