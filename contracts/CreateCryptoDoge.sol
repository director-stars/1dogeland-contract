// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ICryptoDogeNFT.sol";
import "./ManagerInterface.sol";

contract CreateCryptoDoge is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public cryptoDogeNFT;
    address public token;
    mapping (uint256 => uint256) private classInfo;
    uint256[6] public classes;
    uint256 public uncommonEstate;
    uint256 public rareEstate;
    uint256 public superRareEstate;
    uint256 public epicEstate;
    uint256 public legendaryEstate;
    ManagerInterface manager;
    event DNASet(uint256 _tokenId, uint256 _dna, uint256 _rare, uint256 _classInfo);

    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        classes[0] = 16;
        classes[1] = 7;
        classes[2] = 3;
        classes[3] = 3;
        classes[4] = 2;
        classes[5] = 2;
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function buyEgg(uint8[] memory tribe, address referral) public {
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        manager = ManagerInterface(cryptoDoge.manager());
        require(cryptoDoge.balanceOf(_msgSender()).add(cryptoDoge.orders(_msgSender())).add(tribe.length) <= manager.ownableMaxSize(), "already have enough");
        uint256 totalPriceEgg = cryptoDoge.priceEgg().mul(tribe.length);
        uint256 firstPurchaseTime = cryptoDoge.firstPurchaseTime(_msgSender());
        uint256 referralRate = manager.referralRate();
        uint256 referralRatePercent = manager.referralRatePercent();
        uint256 referralReward = 0;

        if(firstPurchaseTime == 0 && referral != address(0)){
            cryptoDoge.setFirstPurchaseTime(_msgSender(), block.timestamp);
            referralReward = totalPriceEgg.mul(referralRate).div(referralRatePercent);
            IERC20(token).safeTransferFrom(_msgSender(), referral, referralReward);
        }
        IERC20(token).safeTransferFrom(_msgSender(), manager.feeAddress(), totalPriceEgg.sub(referralReward));
        
        cryptoDoge.layEgg(_msgSender(), tribe);
    }

    function setDNA(uint256 tokenId) public {
        require(ICryptoDogeNFT(cryptoDogeNFT).ownerOf(tokenId) == _msgSender(), "not own");
        uint256 randNonce = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(_msgSender());
        uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % 10**30;
        ICryptoDogeNFT(cryptoDogeNFT).evolve(tokenId, _msgSender(), dna);
        uint256 dogeRare = ICryptoDogeNFT(cryptoDogeNFT).getRare(tokenId);
        classInfo[tokenId] = dna % classes[dogeRare.sub(1)];
        emit DNASet(tokenId, dna, dogeRare, classInfo[tokenId]);
    }

    function setClasses(uint256 rare, uint256 classNumber) public {
        classes[rare.sub(1)] = classNumber;
    }

    function getClassInfo(uint256 tokenId) public view returns(uint256){
        return classInfo[tokenId];
    }
}