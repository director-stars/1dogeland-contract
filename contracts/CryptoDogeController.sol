// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface ICryptoDogeNFT{
    function layEgg(address receiver, uint8[] memory tribe) external;
    function priceEgg() external returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function evolve(uint256 _tokenId, address _owner, uint256 _dna) external;
    function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function getdoger(uint256 _tokenId) external view returns(
        uint256 generation,
        uint256 tribe,
        uint256 exp,
        uint256 dna,
        uint256 farmTime,
        uint256 bornTime
    );
    function exp(uint256 _tokenId, uint256 rewardExp) external;
    function working(uint256 _tokenId, uint256 _time) external;
    function dogerLevel(uint _tokenId) external view returns(uint256);
}

contract CryptoDogeController is Ownable{
    using SafeERC20 for IERC20;
    address public cryptoDogeNFT;
    address public token;
    uint256 public cooldownTime = 1 days;
    uint256 internal fightRandNonce = 0;
    uint32[4] public victoryProbability;
    uint32[4] public rewardTokenAmount;
    uint32[4] public rewardExp;

    mapping (address => uint256) public claimTokenAmount;

    event DNASet(uint256 dna);
    event Fight(uint256 _tokenId, bool _win);

    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        victoryProbability = [90, 75, 60,45];
        rewardTokenAmount = [100, 180, 220, 260];
        rewardExp = [2, 6, 8, 12];
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
        setDNA(lastTokenId);
    }

    function setDNA(uint256 tokenId) internal {
        uint256 randNonce = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(msg.sender);
        uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10**30;
        ICryptoDogeNFT(cryptoDogeNFT).evolve(tokenId, msg.sender, dna);
        emit DNASet(dna);
    }

    function fight(uint256 _tokenId, address _owner, uint256 attackVictoryProbability) public{
        require(ICryptoDogeNFT(cryptoDogeNFT).ownerOf(_tokenId) == msg.sender, "not own");
        ICryptoDogeNFT mydoge = ICryptoDogeNFT(cryptoDogeNFT);
        (,,,,uint256 farmTime,) = mydoge.getdoger(_tokenId);
        uint256 level = mydoge.dogerLevel(_tokenId);
        require(farmTime < block.timestamp, 'not available for fighting');
        fightRandNonce++;
        uint256 fightRandResult = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, fightRandNonce))) % 100;
        uint256 _rewardTokenAmount = 0;
        uint256 _rewardExp = 0;

        uint256 updatedAttackVictoryProbability = attackVictoryProbability + (100 - attackVictoryProbability) * level / 6;

        if(fightRandResult < updatedAttackVictoryProbability){
            if(attackVictoryProbability == victoryProbability[0]){
                _rewardTokenAmount = rewardTokenAmount[0];
                _rewardExp = rewardExp[0];
            }
            else if(attackVictoryProbability == victoryProbability[1]){
                _rewardTokenAmount = rewardTokenAmount[1];
                _rewardExp = rewardExp[1];
            }
            else if(attackVictoryProbability == victoryProbability[2]){
                _rewardTokenAmount = rewardTokenAmount[2];
                _rewardExp = rewardExp[2];
            }
            else if(attackVictoryProbability == victoryProbability[3]){
                _rewardTokenAmount = rewardTokenAmount[3];
                _rewardExp = rewardExp[3];
            }
            claimTokenAmount[_owner] = claimTokenAmount[_owner] + (_rewardTokenAmount * 10**18);
            mydoge.exp(_tokenId, _rewardExp);
            emit Fight(_tokenId, true);
        }
        else{
            emit Fight(_tokenId, false);
        }
        uint256 _time = (block.timestamp - farmTime + cooldownTime);
        mydoge.working(_tokenId, _time);
    }

    function claimToken() public{
        IERC20(token).safeTransfer(msg.sender, claimTokenAmount[msg.sender]);
        claimTokenAmount[msg.sender] = 0;
    }

    function setVictoryProbability(uint32 _probability1, uint32 _probability2, uint32 _probability3, uint32 _probability4) public onlyOwner{
        victoryProbability = [_probability1, _probability2, _probability3, _probability4];
    }
    function setRewardTokenAmount(uint32 rewardTokenAmount1, uint32 rewardTokenAmount2, uint32 rewardTokenAmount3, uint32 rewardTokenAmount4) public onlyOwner{
        rewardTokenAmount = [rewardTokenAmount1, rewardTokenAmount2, rewardTokenAmount3, rewardTokenAmount4];
    }
    function setRewardExp(uint32 rewardExp1, uint32 rewardExp2, uint32 rewardExp3, uint32 rewardExp4) public onlyOwner{
        rewardExp = [rewardExp1, rewardExp2, rewardExp3, rewardExp4];
    }
    function withdraw(address _address, uint256 amount) public onlyOwner{
        IERC20(token).safeTransfer(_address, amount);
    }
    function setCooldownTime(uint256 _seconds) public onlyOwner{
        cooldownTime = _seconds;
    }
}