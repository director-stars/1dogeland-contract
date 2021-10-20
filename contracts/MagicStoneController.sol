// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ICryptoDogeNFT.sol";
import "./ManagerInterface.sol";
import "./IMagicStoneNFT.sol";

interface IcryptoDogeController{
    function monsters(uint256 _index) external view returns(uint256 _hp, uint256 _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo);
    function randFightNumberFrom() external view returns(uint256);
    function randFightNumberTo() external view returns(uint256);
    function battleTime(uint256 _tokenId) external view returns(uint256);
    function cooldownTime() external view returns(uint256);
}

contract MagicStoneController is Ownable{
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
    address public cryptoDogeController;
    address public magicStoneNFT;
    ManagerInterface manager;

    // uint256 public cooldownTime = 14400;
    uint256 internal fightRandNonce = 0;
    uint256 public nftMaxSize = 1000;

    mapping (uint256 => uint256) public battleTime;
    mapping (uint256 => uint256) public setStoneTime;
    mapping (uint256 => uint256) public dogeStoneInfo;
    mapping (uint256 => uint256) public stoneDogeInfo;
    mapping (uint256 => uint256) public autoFightMonsterInfo;
    event SetAutoFight(uint256 _tokenId, uint256 _monsterId);
    event Fight(uint256 _tokenId, uint256 _totalRewardAmount, uint256 _totalRewardExp, uint256 _winNumber, uint256 _fightNumber);

    constructor (){
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        magicStoneNFT = address(0x5968f5E2672331484e009FD24abE421948e35Dfc);
        cryptoDogeController = address(0x5968f5E2672331484e009FD24abE421948e35Dfc);
    }

    receive() external payable {}

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function setMagicStoneNFT(address _magicStoneNFT) public onlyOwner{
        magicStoneNFT = _magicStoneNFT;
    }

    function setCryptoDogeController(address _cryptoDogeController) public onlyOwner{
        cryptoDogeController = _cryptoDogeController;
    }

    function setNftMaxSize(uint256 _nftMaxSize) public onlyOwner{
        nftMaxSize = _nftMaxSize;
    }

    function buyStone() external payable{
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        IMagicStoneNFT magicStone = IMagicStoneNFT(magicStoneNFT);
        require(magicStone.totalSupply() <= nftMaxSize, "Sold Out");
        manager = ManagerInterface(cryptoDoge.manager());
        uint256 price = magicStone.priceStone();
        require(msg.value >= price, "MAGICSTONENFT: confirmOffer: deposited BNB is less than NFT price." );
        (bool success,) = payable(manager.feeAddress()).call{value: price}("");
        require(success, "Failed to send BNB");
        magicStone.createStone(_msgSender());
    }
    function setAutoFight(uint256 _dogeId,uint256 _stoneId, uint256 _monsterId) public {
        ICryptoDogeNFT dogeNFT = ICryptoDogeNFT(cryptoDogeNFT);
        IMagicStoneNFT stoneNFT = IMagicStoneNFT(magicStoneNFT);
        require(dogeNFT.ownerOf(_dogeId) == _msgSender(), 'not owner of doge');
        require(stoneNFT.ownerOf(_stoneId) == _msgSender(), 'not owner of stone');
        require(stoneDogeInfo[_stoneId] == 0, 'already set stone');
        dogeStoneInfo[_dogeId] = _stoneId;
        setStoneTime[_stoneId] = block.timestamp;
        autoFightMonsterInfo[_stoneId] = _monsterId;
        stoneDogeInfo[_stoneId] = _dogeId;
        emit SetAutoFight(_dogeId, _monsterId);
    }

    function unsetAutoFight(uint256 _dogeId) public {
        // IMagicStoneNFT stoneNFT = IMagicStoneNFT(magicStoneNFT);
        ICryptoDogeNFT dogeNFT = ICryptoDogeNFT(cryptoDogeNFT);
        require(dogeNFT.ownerOf(_dogeId) == _msgSender(), 'not owner of doge');
        uint256 _stoneId = dogeStoneInfo[_dogeId];
        setStoneTime[_stoneId] = 0;
        stoneDogeInfo[_stoneId] = 0;
        dogeStoneInfo[_dogeId] = 0;
    }

    function getAutoFightResults(uint256 _dogeId) public {
        ICryptoDogeNFT dogeNFT = ICryptoDogeNFT(cryptoDogeNFT);
        uint256 _stoneId = dogeStoneInfo[_dogeId];
        uint256 setTime = setStoneTime[_stoneId];
        require(dogeNFT.ownerOf(_dogeId) == _msgSender(), 'not owner of doge');
        require(setTime != 0, 'not set autoFight');
    
        (uint256 fightNumber, uint256 winNumber, uint256 totalRewardAmount, uint256 totalRewardExp) = battleResult(_dogeId);
        // uint256 newAmount = dogeNFT.getClaimTokenAmount(_msgSender()) + (totalRewardAmount * 10**18);
        dogeNFT.updateClaimTokenAmount(_msgSender(), dogeNFT.getClaimTokenAmount(_msgSender()) + (totalRewardAmount * 10**18));
        if(totalRewardExp > 0)
            dogeNFT.exp(_dogeId, totalRewardExp);
        battleTime[_dogeId] = block.timestamp;
        emit Fight(_dogeId, totalRewardAmount, totalRewardExp, winNumber, fightNumber);

    }
    function battleResult(uint256 _dogeId) private returns(uint256 fightNumber, uint256 winNumber, uint256 totalRewardAmount, uint256 totalRewardExp){
        ICryptoDogeNFT dogeNFT = ICryptoDogeNFT(cryptoDogeNFT);
        IcryptoDogeController dogeController = IcryptoDogeController(cryptoDogeController);
        Monster memory monster;
        {
            uint256 monsterId = autoFightMonsterInfo[_dogeId];
            (uint256 _hp, uint256 _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo) = dogeController.monsters(monsterId);

            monster = Monster({
                _hp: _hp, 
                _successRate: _successRate, 
                _rewardTokenFrom: _rewardTokenFrom, 
                _rewardTokenTo: _rewardTokenTo, 
                _rewardExpFrom: _rewardExpFrom, 
                _rewardExpTo: _rewardExpTo}
            );
        }
        uint256 setTime = setStoneTime[dogeStoneInfo[_dogeId]];
        if(dogeController.battleTime(_dogeId) > battleTime[_dogeId]){
            battleTime[_dogeId] = dogeController.battleTime(_dogeId);
        }
        
        uint256 lastBattleTime = battleTime[_dogeId];
        uint256 i = 0;
        uint256 level = dogeNFT.dogerLevel(_dogeId);
        uint256 rare = dogeNFT.getRare(_dogeId);
        uint256 randFigntInfo = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), dogeNFT.balanceOf(_msgSender()))));
        uint256 fightRandResult = 0;
        if(block.timestamp - setTime < dogeController.cooldownTime()){
            if(lastBattleTime == 0)
                fightNumber = 10;
        }
        else{
            if(lastBattleTime == 0)
                lastBattleTime = setTime;
            uint256 turns = (block.timestamp - lastBattleTime).div(dogeController.cooldownTime());
            uint256 totalFightNumber = 0;
            for(; i < turns; i ++){
                totalFightNumber.add(randFigntInfo % (dogeController.randFightNumberTo() - dogeController.randFightNumberFrom() + 1) + dogeController.randFightNumberFrom());
            }
            fightNumber = totalFightNumber;
        }
        uint256 updatedAttackVictoryProbability = 0;
        for(i = 0 ; i < fightNumber; i ++){
            fightRandNonce ++;
            fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), fightRandNonce))) % 100;
            updatedAttackVictoryProbability = monster._successRate + (100 - monster._successRate) * level * rare / 6 / 6 / 2;

            if(fightRandResult < updatedAttackVictoryProbability){
                totalRewardAmount += monster._rewardTokenFrom + (fightRandResult % (monster._rewardTokenTo - monster._rewardTokenFrom + 1));
                totalRewardExp += monster._rewardExpFrom + (fightRandResult % (monster._rewardExpTo - monster._rewardExpFrom + 1));
                winNumber ++;                
            }
        }
        return (fightNumber, winNumber, totalRewardAmount, totalRewardExp);
    }
}