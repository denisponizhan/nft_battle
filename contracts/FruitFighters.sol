pragma solidity ^0.8.4;

import "./FruitFightersERC721.sol";

contract FruitFighters is FruitFightersERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) FruitFightersERC721(name_, symbol_, baseURI_) {
        // ...
    }

    function changeName(uint256 _tokenId, string memory _name)
        external
        payable
        onlyOwnerOf(_tokenId)
        onlyFreeName(_name)
    {
        require(
            msg.value == newNameFee,
            "FruitFighters: fee is invalid. Please, supply correct fee."
        );

        _ownerWithdrawal += msg.value;
        _changeName(_tokenId, _name);
    }

    function createFancyFruitFighter(string memory _name)
        external
        onlyFreeName(_name)
    {
        _createFruitFighter(_name, 0);
    }

    function createRareFruitFighter(string memory _name)
        external
        payable
        onlyFreeName(_name)
    {
        require(
            msg.value == goldFee || msg.value == dimondFee,
            "FruitFighters: fee is invalid. Please, supply correct fee."
        );

        _ownerWithdrawal += msg.value;
        _createFruitFighter(_name, msg.value);
    }

    function createExclusiveFruitFighter(string memory _name)
        external
        onlyOwner
        onlyFreeName(_name)
    {
        _createExclusiveFruitFighter(_name);
    }

    function enterArena(uint256 _tokenId)
        external
        payable
        onlyOwnerOf(_tokenId)
    {
        require(
            !inArena[_tokenId],
            "FruitFighters: enter arena with fighter already in here."
        );
        require(msg.value >= minBid, "FruitFighters: bid too small.");

        _enterArena(_tokenId);
    }

    function fight(uint256 _tokenId, uint256 _targetId)
        external
        payable
        onlyOwnerOf(_tokenId)
    {
        require(
            _tokenId != _targetId,
            "FruitFighters: fight yourself is impossible."
        );
        require(
            inArena[_targetId],
            "FruitFighters: target fighter is not in arena."
        );
        require(
            msg.value == stackes[_targetId],
            "FruitFighters: supplied bid is not equal target bid."
        );

        _fight(_tokenId, _targetId);
    }

    function withdraw() external returns (bool) {
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

    function ownerWithdraw(uint256 _amount) external onlyOwner returns (bool) {
        if (_amount > 0) {
            _ownerWithdrawal -= _amount;
            if (!payable(owner()).send(_amount)) {
                _ownerWithdrawal += _amount;
                return false;
            }
        }
        return true;
    }

    function getOwnerWithdrawal() public view onlyOwner returns (uint256) {
        return _ownerWithdrawal;
    }

    function setGoldFee(uint256 _fee) external onlyOwner {
        goldFee = _fee;
    }

    function setDimondFee(uint256 _fee) external onlyOwner {
        dimondFee = _fee;
    }

    function setNewNameFee(uint256 _fee) external onlyOwner {
        newNameFee = _fee;
    }

    function setMinBid(uint256 _bid) external onlyOwner {
        minBid = _bid;
    }

    function setFightFee(uint256 _fee) external onlyOwner {
        figthFee = _fee;
    }
}
