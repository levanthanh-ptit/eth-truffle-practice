// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library TableLib {
    struct Holder {
        address player;
        uint256[] cards;
        uint256 betAmount;
    }

    function freshUnbox(uint256[] storage cards) public {
        require(cards.length == 0);
        for (uint256 i = 0; i < 52; i++) {
            uint256 cardValue = (i % 13) + 1;
            cards.push(cardValue);
        }
    }

    function pickCards(
        uint256[] storage cardBox,
        Holder storage holder,
        uint256 numOfCard
    ) public {
        for (uint256 i = 0; i < numOfCard; i++) {
            uint256 index = randomUint(cardBox.length);
            holder.cards.push(cardBox[index]);
            cardBox[index] = cardBox[cardBox.length - 1];
            cardBox.pop();
        }
    }

    function randomUint(uint256 maxium) private view returns (uint256) {
        uint256 seed = (block.timestamp + block.difficulty + block.number) %
            100;

        return
            uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), seed))
            ) % (maxium + 1);
    }
}