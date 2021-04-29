pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FruitFightersFactory is Ownable {
    enum TokenTypes {FANCY, GOLD, DIAMOND, EXCLUSIVE}

    uint256 goldFee = 100000000000000000; // 0.1 eth
    uint256 dimondFee = 500000000000000000; // 0.5 eth
    uint256 newNameFee = 10000000000000000; // 0.01 eth
    uint256 ownerFee = 0;

    struct FruitFighter {
        TokenTypes tokenType;
        string name;
        uint32 fightCount;
        uint32 winCount;
        uint8 power;
        uint8 endurance;
        uint8 speed;
    }

    FruitFighter[] public fruitFighters;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _fruitFighterToOwner;

    // Mapping owner address to token count
    mapping(address => uint256) internal _ownerFruitFighterCount;

    // Mapping keccak256(abi.encodePacked(_name)) to true or false. FruitFightersFactory allows only unique name per token
    mapping(bytes32 => bool) private _usedNames;

    event NewFruitFighter(
        uint256 indexed id,
        TokenTypes indexed tokenType,
        string name,
        uint8 power,
        uint8 endurance,
        uint8 speed
    );

    event NewFruitFighterName(uint256 indexed id, string name);

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(
            _msgSender() == _fruitFighterToOwner[_tokenId],
            "Surry, but you are not an owner of this token."
        );
        _;
    }

    function isNameFree(string memory _name) public view returns (bool) {
        return !_usedNames[keccak256(abi.encodePacked(_name))];
    }

    function changeName(uint256 _tokenId, string memory _name)
        external
        payable
        onlyOwnerOf(_tokenId)
    {
        require(msg.value == newNameFee, "Please supply new name fee.");
        require(isNameFree(_name), "This name already in used.");
        ownerFee += msg.value;
        _usedNames[keccak256(abi.encodePacked(_name))] = true;
        FruitFighter storage fighter = fruitFighters[_tokenId];
        _usedNames[keccak256(abi.encodePacked(fighter.name))] = false;
        fighter.name = _name;
        emit NewFruitFighterName(_tokenId, fighter.name);
    }

    // Use provable API for random
    // =================
    //

    uint256 randNonce = 0;

    function _randByMod(uint256 _modulus) internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, _msgSender(), randNonce)
                )
            ) % _modulus;
    }

    //=================

    function getFighterFeatures(uint256 _supplyFee)
        private
        returns (
            TokenTypes tokenType,
            uint8 power,
            uint8 endurance,
            uint8 speed
        )
    {
        uint32 rand = uint32(_randByMod(1000000));
        uint32 chance;

        if (_supplyFee == dimondFee) {
            chance = 2;
        } else if (_supplyFee == goldFee) {
            chance = 9;
        } else if (_supplyFee == 0) {
            chance = 9999;
        }

        uint256 k = rand % chance;

        if (k == 0) {
            return (
                TokenTypes.DIAMOND,
                uint8(
                    (uint256(
                        keccak256(abi.encodePacked(rand, block.timestamp))
                    ) % 90) + 110 // from 110 to 199
                ),
                uint8(
                    (uint256(keccak256(abi.encodePacked(rand, _msgSender()))) %
                        90) + 110 // from 110 to 199
                ),
                uint8(
                    (uint256(keccak256(abi.encodePacked(rand, k))) % 90) + 110
                ) // from 110 to 199
            );
        } else if (k > 0 && k < 10) {
            return (
                TokenTypes.GOLD,
                uint8(
                    (uint256(
                        keccak256(abi.encodePacked(rand, block.timestamp))
                    ) % 70) + 50 // from 50 to 119
                ),
                uint8(
                    (uint256(keccak256(abi.encodePacked(rand, _msgSender()))) %
                        70) + 50 // from 50 to 119
                ),
                uint8((uint256(keccak256(abi.encodePacked(rand, k))) % 70) + 50) // from 50 to 119
            );
        } else {
            return (
                TokenTypes.FANCY,
                uint8(
                    (uint256(
                        keccak256(abi.encodePacked(rand, block.timestamp))
                    ) % 50) + 10 // from 10 to 59
                ),
                uint8(
                    (uint256(keccak256(abi.encodePacked(rand, _msgSender()))) %
                        50) + 10 // from 10 to 59
                ),
                uint8((uint256(keccak256(abi.encodePacked(rand, k))) % 50) + 10) // from 10 to 59
            );
        }
    }

    function _createFruitFighter(string memory _name, uint256 _supplyFee)
        private
    {
        _usedNames[keccak256(abi.encodePacked(_name))] = true;

        (TokenTypes tokenType, uint8 power, uint8 endurance, uint8 speed) =
            getFighterFeatures(_supplyFee);

        fruitFighters.push(
            FruitFighter(tokenType, _name, 0, 0, power, endurance, speed)
        );

        uint256 id = fruitFighters.length - 1;

        _fruitFighterToOwner[id] = _msgSender();
        _ownerFruitFighterCount[_msgSender()]++;

        emit NewFruitFighter(id, tokenType, _name, power, endurance, speed);
    }

    function createFancyFruitFighter(string memory _name) public {
        require(isNameFree(_name), "This name already in used.");

        _createFruitFighter(_name, 0);
    }

    function createRareFruitFighter(string memory _name) public payable {
        require(isNameFree(_name), "This name already in used.");
        require(
            msg.value == goldFee || msg.value == dimondFee,
            "Please supply correct fee."
        );

        ownerFee += msg.value;
        _createFruitFighter(_name, msg.value);
    }

    function createExclusiveFruitFighter(string memory _name) public onlyOwner {
        require(isNameFree(_name), "This name already in used.");
        _usedNames[keccak256(abi.encodePacked(_name))] = true;

        uint8 power =
            uint8(
                (uint256(keccak256(abi.encodePacked(_name, block.timestamp))) %
                    56) + 200 // from 200 to 255
            );

        uint8 endurance =
            uint8(
                (uint256(keccak256(abi.encodePacked(_name, owner()))) % 56) +
                    200 // from 200 to 255
            );

        uint8 speed =
            uint8(
                (uint256(keccak256(abi.encodePacked(_name, uint8(0)))) % 56) +
                    200
            ); // from 200 to 255

        fruitFighters.push(
            FruitFighter(
                TokenTypes.EXCLUSIVE,
                _name,
                0,
                0,
                power,
                endurance,
                speed
            )
        );

        uint256 id = fruitFighters.length - 1;

        _fruitFighterToOwner[id] = _msgSender();
        _ownerFruitFighterCount[_msgSender()]++;

        emit NewFruitFighter(
            id,
            TokenTypes.EXCLUSIVE,
            _name,
            power,
            endurance,
            speed
        );
    }
}
