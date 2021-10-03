// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ICryptoDogeNFT.sol";

contract CryptoDogeController is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Monster{
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
    mapping (address => uint256) public battleTime;

    event Fight(uint256 _tokenId, uint256 _rewardTokenAmount, uint256 _rewardExp, bool _win);

    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        monsters[0]=Monster({
            _hp: 200, 
            _successRate: 80, 
            _rewardTokenFrom: 15, 
            _rewardTokenTo: 20, 
            _rewardExpFrom: 2, 
            _rewardExpTo: 2});
        monsters[1] = Monster({
            _hp: 250, 
            _successRate: 70, 
            _rewardTokenFrom: 27, 
            _rewardTokenTo: 36, 
            _rewardExpFrom: 6, 
            _rewardExpTo: 6});
        monsters[2] = Monster({
            _hp: 400, 
            _successRate: 50, 
            _rewardTokenFrom: 33, 
            _rewardTokenTo: 44, 
            _rewardExpFrom: 8, 
            _rewardExpTo: 8});
        monsters[3] = Monster({
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

    function fight(uint256 _tokenId, address _owner, uint256 monsterId, bool _final) public{
        require(ICryptoDogeNFT(cryptoDogeNFT).ownerOf(_tokenId) == msg.sender, "not own");
        require(battleTime[_owner] < block.timestamp, 'not available for fighting');
        ICryptoDogeNFT mydoge = ICryptoDogeNFT(cryptoDogeNFT);
        uint256 level = mydoge.dogerLevel(_tokenId);
        uint256 rare = mydoge.getRare(_tokenId);
        
        fightRandNonce++;
        uint256 fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, fightRandNonce))) % 100;
        uint256 _rewardTokenAmount = 0;
        uint256 _rewardExp = 0;

        uint256 updatedAttackVictoryProbability = monsters[monsterId]._successRate + (90 - monsters[monsterId]._successRate) * level * rare / 6 / 6;

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
        if(_final){
            battleTime[_owner] = block.timestamp + cooldownTime;
        }
    }

    function claimToken() public{
        IERC20(token).safeTransfer(msg.sender, claimTokenAmount[msg.sender]);
        claimTokenAmount[msg.sender] = 0;
    }

    function setMonster(uint32 _index, uint256 _hp, uint _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo) public onlyOwner{
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