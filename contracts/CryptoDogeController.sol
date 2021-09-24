// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface ICryptoDogeNFT{
    function layEgg(address receiver, uint8[] memory tribe) external;
    function priceEgg() external returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function evolve(uint256 _tokenId, address _owner, uint256 _dna) external;
    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function getdoger(uint256 _tokenId) external view returns(
        uint256 _generation,
        uint256 _tribe,
        uint256 _exp,
        uint256 _dna,
        uint256 _farmTime,
        uint256 _bornTime
    );
    function exp(uint256 _tokenId, uint256 rewardExp) external;
    function working(uint256 _tokenId, uint256 _time) external;
    function dogerLevel(uint _tokenId) external view returns(uint256);
}

contract CryptoDogeController is Ownable{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Monster{
        string _name;
        uint256 _hp;
        uint256 _successRate;
        uint256 _rewardTokenFrom;
        uint256 _rewardTokenTo;
        uint256 _rewardExpFrom;
        uint256 _rewardExpTo;
    }

    address public cryptoDogeNFT;
    address public token;
    uint256 public cooldownTime = 14400;
    uint256 internal fightRandNonce = 0;
    Monster[4] public monsters;

    mapping (address => uint256) public claimTokenAmount;
    mapping (address => EnumerableSet.UintSet) private ownerTokens;

    event DNASet(uint256 _tokenId, uint256 _dna);
    event Fight(uint256 _tokenId, uint256 _rewardTokenAmount, uint256 _rewardExp, bool _win);

    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        monsters[0]=Monster({
            _name: 'Calaca Skeleton', 
            _hp: 200, 
            _successRate: 80, 
            _rewardTokenFrom: 15, 
            _rewardTokenTo: 20, 
            _rewardExpFrom: 2, 
            _rewardExpTo: 2});
        monsters[1] = Monster({
            _name: 'Plague Zombie', 
            _hp: 250, 
            _successRate: 70, 
            _rewardTokenFrom: 27, 
            _rewardTokenTo: 36, 
            _rewardExpFrom: 6, 
            _rewardExpTo: 6});
        monsters[2] = Monster({
            _name: 'Mudkin Drowner', 
            _hp: 400, 
            _successRate: 50, 
            _rewardTokenFrom: 33, 
            _rewardTokenTo: 44, 
            _rewardExpFrom: 8, 
            _rewardExpTo: 8});
        monsters[3] = Monster({
            _name: 'Deathlord Draugr', 
            _hp: 600, 
            _successRate: 30, 
            _rewardTokenFrom: 39, 
            _rewardTokenTo: 52, 
            _rewardExpFrom: 12, 
            _rewardExpTo: 12});
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function buyEgg(uint8[] memory tribe) public {
        uint256 priceEgg = ICryptoDogeNFT(cryptoDogeNFT).priceEgg();
        IERC20(token).safeTransferFrom(msg.sender, address(this), priceEgg);
        ICryptoDogeNFT(cryptoDogeNFT).layEgg(msg.sender, tribe);
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(msg.sender);
        uint256 lastTokenId = ICryptoDogeNFT(cryptoDogeNFT).tokenOfOwnerByIndex(msg.sender, totalDoges - 1);
        ownerTokens[msg.sender].add(lastTokenId);
        setDNA(lastTokenId);
    }

    function setDNA(uint256 tokenId) public {
        require(ICryptoDogeNFT(cryptoDogeNFT).ownerOf(tokenId) == msg.sender, "not own");
        uint256 randNonce = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(msg.sender);
        uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10**30;
        ICryptoDogeNFT(cryptoDogeNFT).evolve(tokenId, msg.sender, dna);
        emit DNASet(tokenId, dna);
    }

    function fight(uint256 _tokenId, address _owner, uint256 monsterId, bool _final) public{
        require(ICryptoDogeNFT(cryptoDogeNFT).ownerOf(_tokenId) == msg.sender, "not own");
        ICryptoDogeNFT mydoge = ICryptoDogeNFT(cryptoDogeNFT);
        (,,,,uint256 farmTime,) = mydoge.getdoger(_tokenId);
        uint256 level = mydoge.dogerLevel(_tokenId);
        require(farmTime < block.timestamp, 'not available for fighting');
        fightRandNonce++;
        uint256 fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, fightRandNonce))) % 100;
        uint256 _rewardTokenAmount = 0;
        uint256 _rewardExp = 0;

        uint256 updatedAttackVictoryProbability = monsters[monsterId]._successRate + (100 - monsters[monsterId]._successRate) * level / 6;

        if(fightRandResult < updatedAttackVictoryProbability){
            _rewardTokenAmount = monsters[monsterId]._rewardTokenFrom + (fightRandResult % (monsters[monsterId]._rewardTokenTo - monsters[monsterId]._rewardTokenFrom + 1));
            _rewardExp = monsters[monsterId]._rewardExpFrom + (fightRandResult % (monsters[monsterId]._rewardExpTo - monsters[monsterId]._rewardExpFrom + 1));

            claimTokenAmount[_owner] = claimTokenAmount[_owner] + (_rewardTokenAmount * 10**18);
            mydoge.exp(_tokenId, _rewardExp);
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, true);
        }
        else{
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, false);
        }
        uint256 _time = (block.timestamp - farmTime + cooldownTime);
        if(_final)
            mydoge.working(_tokenId, _time);
    }

    function claimToken() public{
        IERC20(token).safeTransfer(msg.sender, claimTokenAmount[msg.sender]);
        claimTokenAmount[msg.sender] = 0;
    }

    function setMonster(uint32 _index, string memory _name, uint256 _hp, uint _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo) public onlyOwner{
        monsters[_index]._name = _name;
        monsters[_index]._hp = _hp;
        monsters[_index]._successRate = _successRate;
        monsters[_index]._rewardTokenFrom = _rewardTokenFrom;
        monsters[_index]._rewardTokenTo = _rewardTokenTo;
        monsters[_index]._rewardExpFrom = _rewardExpFrom;
        monsters[_index]._rewardExpTo = _rewardExpTo;
    }

    // function addMonster(string memory _name, uint256 _hp, uint _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo) public onlyOwner{
    //     monsters[monsterNumber] = Monster({
    //         _name: _name, 
    //         _hp: _hp, 
    //         _successRate: _successRate, 
    //         _rewardTokenFrom: _rewardTokenFrom, 
    //         _rewardTokenTo: _rewardTokenTo, 
    //         _rewardExpFrom: _rewardExpFrom, 
    //         _rewardExpTo: _rewardExpTo});
    //     monsterNumber ++;
    // }
    function withdraw(address _address, uint256 amount) public onlyOwner{
        IERC20(token).safeTransfer(_address, amount);
    }
    function setCooldownTime(uint256 _seconds) public onlyOwner{
        cooldownTime = _seconds;
    }
    function getMonsters() public view returns(Monster[] memory monsters){
        return monsters;
    }
}