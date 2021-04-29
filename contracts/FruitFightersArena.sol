pragma solidity ^0.8.4;

import "./FruitFightersFactory.sol";

contract FruitFightersArena is FruitFightersFactory {
    uint256 minBid = 5000000000000000; // 0.005 eth
    uint256 figthFee = 1000000000000000; // 0.001 eth

    mapping(uint256 => bool) public inArena;
    mapping(uint256 => uint256) public stackes;
    mapping(address => uint256) public pendingVictoryRewards;

    event NewWinner(
        uint256 indexed id,
        address indexed owner,
        uint256 indexed victoryReward
    );

    function enterArena(uint256 _tokenId)
        external
        payable
        onlyOwnerOf(_tokenId)
    {
        require(!inArena[_tokenId], "Fighter already here.");
        require(
            msg.value >= minBid,
            "Sorry, but you sent less than the minimum fighting bid."
        );
        stackes[_tokenId] = msg.value;
        inArena[_tokenId] = true;
    }

    function fight(uint256 _tokenId, uint256 _targetId)
        external
        payable
        onlyOwnerOf(_tokenId)
    {
        require(_tokenId != _targetId, "Sorry, but you can't beat yourself.");
        require(inArena[_targetId], "Target fighter is not in arena.");
        require(
            msg.value == stackes[_targetId],
            "Please provide an equal fighting bid."
        );

        uint256 rand = _randByMod(100000);
        uint256 reward = stackes[_targetId] + msg.value - figthFee;

        ownerFee += figthFee;
        stackes[_targetId] = 0;
        inArena[_targetId] = false;

        FruitFighter storage f1 = fruitFighters[_tokenId];
        FruitFighter storage f2 = fruitFighters[_targetId];

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

    function withdraw() public returns (bool) {
        uint256 amount = pendingVictoryRewards[_msgSender()];
        if (amount > 0) {
            pendingVictoryRewards[_msgSender()] = 0;
            if (!payable(_msgSender()).send(amount)) {
                pendingVictoryRewards[_msgSender()] = amount;
                return false;
            }
        }
        return true;
    }

    function ownerWithdraw(uint256 _amount) public onlyOwner returns (bool) {
        if (_amount > 0) {
            ownerFee -= _amount;
            if (!payable(owner()).send(_amount)) {
                ownerFee += _amount;
                return false;
            }
        }
        return true;
    }

    function getOwnerFee() public view onlyOwner returns (uint256) {
        return ownerFee;
    }
}
