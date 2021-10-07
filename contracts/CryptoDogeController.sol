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
    address public magicStoneNFT;

    mapping (uint256 => uint256) private classInfo;
    uint256[6] public classes;
    uint256 public uncommonEstate;
    uint256 public rareEstate;
    uint256 public superRareEstate;
    uint256 public epicEstate;
    uint256 public legendaryEstate;
    ManagerInterface manager;
    event DNASet(uint256 _tokenId, uint256 _dna, uint256 _rare, uint256 _classInfo);

    uint256 public cooldownTime = 14400;
    uint256 internal fightRandNonce = 0;
    Monster[4] public monsters;

    mapping (address => uint256) public claimTokenAmount;
    mapping (uint256 => uint256) public battleTime;

    uint256 public randFightNumberFrom = 5;
    uint256 public randFightNumberTo = 10;
    mapping (uint256 => uint256) public setStoneTime;
    mapping (uint256 => uint256) public autoFightMonsterInfo;
    event SetAutoFight(uint256 _tokenId, uint256 _monsterId);
    event Fight(uint256 _tokenId, uint256 _totalRewardAmount, uint256 _totalRewardExp, uint256 _winNumber, uint256 _fightNumber);

    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        magicStoneNFT = address(0x5968f5E2672331484e009FD24abE421948e35Dfc);
        classes[0] = 16;
        classes[1] = 7;
        classes[2] = 3;
        classes[3] = 3;
        classes[4] = 2;
        classes[5] = 2;  

        monsters[0] = Monster({
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

    function setMagicStoneNFT(address _magicStoneNFT) public onlyOwner{
        magicStoneNFT = _magicStoneNFT;
    }

    function buyDoge(uint8[] memory tribe, address referral) public {
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        manager = ManagerInterface(cryptoDoge.manager());
        require(cryptoDoge.totalSupply() <= manager.nftMaxSize(), "Sold Out");
        require(cryptoDoge.balanceOf(_msgSender()).add(cryptoDoge.orders(_msgSender())).add(tribe.length) <= manager.ownableMaxSize(), "already have enough");
        uint256 totalPriceDoge = cryptoDoge.priceDoge().mul(tribe.length);
        uint256 firstPurchaseTime = cryptoDoge.firstPurchaseTime(_msgSender());
        uint256 referralRate = manager.referralRate();
        uint256 referralRatePercent = manager.referralRatePercent();
        uint256 referralReward = 0;

        if(firstPurchaseTime == 0 && referral != address(0)){
            cryptoDoge.setFirstPurchaseTime(_msgSender(), block.timestamp);
            referralReward = totalPriceDoge.mul(referralRate).div(referralRatePercent);
            IERC20(token).safeTransferFrom(_msgSender(), referral, referralReward);
        }
        IERC20(token).safeTransferFrom(_msgSender(), manager.feeAddress(), totalPriceDoge.sub(referralReward));
        
        cryptoDoge.layDoge(_msgSender(), tribe);
    }

    function setDNA(uint256 tokenId) public {
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        require(cryptoDoge.ownerOf(tokenId) == _msgSender(), "not own");

        uint256 randNonce = cryptoDoge.balanceOf(_msgSender());
        uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % 10**30;
        cryptoDoge.evolve(tokenId, _msgSender(), dna);

        uint256 dogeRare = cryptoDoge.getRare(tokenId);
        classInfo[tokenId] = dna % classes[dogeRare.sub(1)];
        emit DNASet(tokenId, dna, dogeRare, classInfo[tokenId]);
    }

    function setClasses(uint256 rare, uint256 classNumber) public {
        classes[rare.sub(1)] = classNumber;
    }

    function getClassInfo(uint256 tokenId) public view returns(uint256){
        return classInfo[tokenId];
    }

    function fight(uint256 _tokenId, address _owner, uint256 monsterId, bool _final) public{
        ICryptoDogeNFT mydoge = ICryptoDogeNFT(cryptoDogeNFT);
        require(mydoge.ownerOf(_tokenId) == _msgSender(), "not own");
        require(battleTime[_tokenId] < block.timestamp, 'not available for fighting');
        
        uint256 level = mydoge.dogerLevel(_tokenId);
        uint256 rare = mydoge.getRare(_tokenId);
        
        fightRandNonce++;
        uint256 fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), fightRandNonce))) % 100;
        uint256 _rewardTokenAmount = 0;
        uint256 _rewardExp = 0;

        uint256 updatedAttackVictoryProbability = monsters[monsterId]._successRate + (90 - monsters[monsterId]._successRate) * level * rare / 6 / 6;

        if(fightRandResult < updatedAttackVictoryProbability){
            _rewardTokenAmount = monsters[monsterId]._rewardTokenFrom + (fightRandResult % (monsters[monsterId]._rewardTokenTo - monsters[monsterId]._rewardTokenFrom + 1));
            _rewardExp = monsters[monsterId]._rewardExpFrom + (fightRandResult % (monsters[monsterId]._rewardExpTo - monsters[monsterId]._rewardExpFrom + 1));

            claimTokenAmount[_owner] = claimTokenAmount[_owner] + (_rewardTokenAmount * 10**18);
            mydoge.exp(_tokenId, _rewardExp);
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, 1, 1);
        }
        else{
            emit Fight(_tokenId, _rewardTokenAmount, _rewardExp, 0, 1);
        }
        if(_final){
            battleTime[_tokenId] = block.timestamp + cooldownTime;
        }
    }

    function claimToken() public{
        IERC20(token).safeTransfer(_msgSender(), claimTokenAmount[_msgSender()]);
        claimTokenAmount[_msgSender()] = 0;
    }

    function setMonster(uint32 _index, uint256 _hp, uint _successRate, uint256 _rewardTokenFrom, uint256 _rewardTokenTo, uint256 _rewardExpFrom, uint256 _rewardExpTo) public onlyOwner{
        assert(_rewardTokenTo >=_rewardTokenFrom);
        assert(_rewardExpTo >=_rewardExpFrom);
        monsters[_index]._hp = _hp;
        monsters[_index]._successRate = _successRate;
        monsters[_index]._rewardTokenFrom = _rewardTokenFrom;
        monsters[_index]._rewardTokenTo = _rewardTokenTo;
        monsters[_index]._rewardExpFrom = _rewardExpFrom;
        monsters[_index]._rewardExpTo = _rewardExpTo;
    }

    function setRandFightNumber(uint256 _randFightNumberFrom, uint256 _randFightNumberTo) public{
        assert(_randFightNumberTo >= randFightNumberFrom);
        randFightNumberFrom = _randFightNumberFrom;
        randFightNumberTo = _randFightNumberTo;
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
    function buyStone() public {
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        IMagicStoneNFT magicStone = IMagicStoneNFT(magicStoneNFT);
        manager = ManagerInterface(cryptoDoge.manager());
        uint256 price = magicStone.priceStone();
        IERC20(token).safeTransferFrom(_msgSender(), manager.feeAddress(), price);
        magicStone.createStone(_msgSender());
    }
    function setAutoFight(uint256 _dogeId, uint256 _monsterId) public {
        ICryptoDogeNFT dogeNFT = ICryptoDogeNFT(cryptoDogeNFT);
        IMagicStoneNFT stoneNFT = IMagicStoneNFT(magicStoneNFT);
        require(dogeNFT.ownerOf(_dogeId) == _msgSender(), 'not owner of doge');
        uint256 stoneBalance = stoneNFT.balanceOf(_msgSender());
        require(stoneBalance > 0, 'not have stone');
        uint256 _stoneId = stoneNFT.tokenOfOwnerByIndex(_msgSender(), stoneBalance - 1);
        setStoneTime[_dogeId] = block.timestamp;
        autoFightMonsterInfo[_dogeId] = _monsterId;
        stoneNFT.burn(_stoneId, _msgSender());
        emit SetAutoFight(_dogeId, _monsterId);
    }

    function unsetAutoFight(uint256 _dogeId) public {
        ICryptoDogeNFT dogeNFT = ICryptoDogeNFT(cryptoDogeNFT);
        require(dogeNFT.ownerOf(_dogeId) == _msgSender(), 'not owner of doge');
        setStoneTime[_dogeId] = 0;
    }

    function getAutoFightResults(uint256 _dogeId) public{
        ICryptoDogeNFT dogeNFT = ICryptoDogeNFT(cryptoDogeNFT);
        require(dogeNFT.ownerOf(_dogeId) == _msgSender(), 'not owner of doge');
        require(setStoneTime[_dogeId] != 0, 'not set autoFight');
        uint256 lastBattleTime = battleTime[_dogeId];
        uint256 fightNumber = 0;
        uint256 winNumber = 0;
        uint256 totalRewardAmount = 0;
        uint256 totalRewardExp = 0;
        uint256 randFigntInfo = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), dogeNFT.balanceOf(_msgSender()))));
        uint256 i = 0;
        uint256 monsterId = autoFightMonsterInfo[_dogeId];
        uint256 level = dogeNFT.dogerLevel(_dogeId);
        uint256 rare = dogeNFT.getRare(_dogeId);
        uint256 fightRandResult = 0;
        if(block.timestamp - setStoneTime[_dogeId] < cooldownTime){
            fightNumber = 10;
        }
        else{
            if(lastBattleTime == 0)
                lastBattleTime = setStoneTime[_dogeId];
            uint256 turns = (block.timestamp - lastBattleTime).div(cooldownTime);
            for(; i < turns; i ++){
                fightNumber.add(randFigntInfo % (randFightNumberTo - randFightNumberFrom + 1) + randFightNumberFrom);
            }
        }
        for(i = 0 ; i < fightNumber; i ++){
            fightRandNonce ++;
            fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), fightRandNonce))) % 100;
            uint256 updatedAttackVictoryProbability = monsters[monsterId]._successRate + (90 - monsters[monsterId]._successRate) * level * rare / 6 / 6;

            if(fightRandResult < updatedAttackVictoryProbability){
                totalRewardAmount += monsters[monsterId]._rewardTokenFrom + (fightRandResult % (monsters[monsterId]._rewardTokenTo - monsters[monsterId]._rewardTokenFrom + 1));
                totalRewardExp += monsters[monsterId]._rewardExpFrom + (fightRandResult % (monsters[monsterId]._rewardExpTo - monsters[monsterId]._rewardExpFrom + 1));
                winNumber ++;                
            }
        }
        claimTokenAmount[_msgSender()] = claimTokenAmount[_msgSender()] + (totalRewardAmount * 10**18);
        dogeNFT.exp(_dogeId, totalRewardExp);
        emit Fight(_dogeId, totalRewardAmount, totalRewardExp, winNumber, fightNumber);
        battleTime[_dogeId] = block.timestamp + cooldownTime;
    }
}