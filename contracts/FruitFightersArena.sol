pragma solidity ^0.8.4;

import "./FruitFightersCore.sol";

contract FruitFightersArena is FruitFightersCore {
    uint256 public minBid = 5000000000000000; // 0.005 eth
    uint256 public figthFee = 1000000000000000; // 0.001 eth

    mapping(uint256 => bool) public inArena;
    mapping(uint256 => uint256) public stackes;
    mapping(address => uint256) public pendingVictoryRewards;

    event NewWinner(
        uint256 indexed id,
        address indexed owner,
        uint256 indexed victoryReward
    );

    function _enterArena(uint256 _tokenId) internal {
        stackes[_tokenId] = msg.value;
        inArena[_tokenId] = true;
    }

    function _fight(uint256 _tokenId, uint256 _targetId) internal {
        uint256 rand = _randByMod(100000);
        uint256 reward = stackes[_targetId] + msg.value - figthFee;

        _ownerWithdrawal += figthFee;
        stackes[_targetId] = 0;
        inArena[_targetId] = false;

        FruitFighter storage f1 = _fruitFighters[_tokenId];
        FruitFighter storage f2 = _fruitFighters[_targetId];

        uint16[2] memory traits;
        bool isTraitsReversed = false;

        if (
            f1.power + f1.endurance + f1.speed <
            f2.power + f2.endurance + f2.speed
        ) {
            traits = [
                uint16(f1.power + f1.endurance + f1.speed),
                uint16(f2.power + f2.endurance + f2.speed)
            ];
            isTraitsReversed = false;
        } else {
            traits = [
                uint16(f2.power + f2.endurance + f2.speed),
                uint16(f1.power + f1.endurance + f1.speed)
            ];
            isTraitsReversed = true;
        }

        for (uint8 i = 0; i < traits.length; i++) {
            traits[i] = (i == 0) ? traits[i] : traits[i] + traits[i - 1];
        }

        uint16 drawnNumber = uint16(rand % traits[traits.length - 1]);
        uint8 winner = 0;

        for (uint8 i = 0; i < traits.length; i++) {
            if ((winner == 0) && (drawnNumber <= traits[i])) {
                winner = i + 1;
            }
        }

        if (!isTraitsReversed) {
            if (winner == 1) {
                f1.winCount++;
                pendingVictoryRewards[_fruitFighterToOwner[_tokenId]] += reward;
                emit NewWinner(
                    _tokenId,
                    _fruitFighterToOwner[_tokenId],
                    reward
                );
            } else {
                f2.winCount++;
                pendingVictoryRewards[
                    _fruitFighterToOwner[_targetId]
                ] += reward;
                emit NewWinner(
                    _targetId,
                    _fruitFighterToOwner[_targetId],
                    reward
                );
            }
        } else {
            if (winner == 1) {
                f2.winCount++;
                pendingVictoryRewards[
                    _fruitFighterToOwner[_targetId]
                ] += reward;
                emit NewWinner(
                    _targetId,
                    _fruitFighterToOwner[_targetId],
                    reward
                );
            } else {
                f1.winCount++;
                pendingVictoryRewards[_fruitFighterToOwner[_tokenId]] += reward;
                emit NewWinner(
                    _tokenId,
                    _fruitFighterToOwner[_tokenId],
                    reward
                );
            }
        }

        f1.fightCount++;
        f2.fightCount++;
    }
}
