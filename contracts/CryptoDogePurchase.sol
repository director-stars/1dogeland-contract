// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./ICryptoDogeNFT.sol";

contract CryptoDogePurchase is Ownable{
    using EnumerableSet for EnumerableSet.UintSet;

    address public cryptoDogeNFT;
    address public cryptoDogeController;
    address[] public referees;
    mapping(uint256 => address) private buyers;
    mapping(address => bool) private buyerStatus;
    mapping(address => EnumerableSet.UintSet) private referral_history;

    struct BuyerInfo{
        address[] _buyer;
        uint256[] _purchaseTime;
    }

    struct Referral{
        address _referee;
        uint256 _numberOfReferrals;
    }

    constructor (){
        // cryptoDogeNFT = address(0x643a211d36B745864D89EBc1913140CEDA7d1323);
        // cryptoDogeController = address(0x7EDC9Be9F07457Fd755D9b8e78e7B84E67F8f05e);
        cryptoDogeNFT = address(0xE4de8D81dE25353E7959e901c279f083e1BD44C4);
        cryptoDogeController = address(0xCFd9e11f17F05cBf922327da50f82d53AA148d65);
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
    }

    function setCryptoDogeController(address _controllerAddress) public onlyOwner{
        cryptoDogeController = _controllerAddress;
    }

    function setBuyerStatus(address referral) public {
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        uint256 firstPurchaseTime = cryptoDoge.firstPurchaseTime(_msgSender());
        if(firstPurchaseTime == 0 && referral != address(0)){
            buyerStatus[_msgSender()] = true;
        }
    }

    function setReferrals(address referral) public {
        ICryptoDogeNFT cryptoDoge = ICryptoDogeNFT(cryptoDogeNFT);
        uint256 firstPurchaseTime = cryptoDoge.firstPurchaseTime(_msgSender());
        if(firstPurchaseTime != 0 && referral != address(0) && buyerStatus[_msgSender()]){
            referees.push(_msgSender());
            referral_history[_msgSender()].add(block.timestamp);
            buyers[block.timestamp] = _msgSender();
        }
        buyerStatus[_msgSender()] = false;
    }

    function getReferrals(uint256 from, uint256 to) public view returns(Referral[] memory) {

        uint256 availableReferrals = 0;
        bool available;

        for(uint256 i; i < referees.length; i ++){
            available = false;

            for(uint256 j; j < referral_history[referees[i]].length(); j ++){
                uint256 purchaseTime = referral_history[referees[i]].at(j);

                if(purchaseTime >= from && purchaseTime < to){
                    available = true;
                }                
            }

            if(available){
                availableReferrals ++;
            }
        }

        Referral[] memory referralList = new Referral[](availableReferrals);
        uint256 index = 0;

        for(uint256 i; i < referees.length; i ++){
            uint256 numberOfReferrals = 0;

            for(uint256 j; j < referral_history[referees[i]].length(); j ++){
                uint256 purchaseTime = referral_history[referees[i]].at(j);

                if(purchaseTime >= from && purchaseTime < to){
                    numberOfReferrals ++;
                }
            }

            if(numberOfReferrals > 0){
                referralList[index]._referee = referees[i];
                referralList[index]._numberOfReferrals = numberOfReferrals;
                index ++;
            }
        }

        return referralList;
    }

    function getBuyerInfo(address referral, uint256 from, uint256 to) public view returns(BuyerInfo memory){

        uint256 numberOfReferrals = 0;

        for(uint256 i; i < referral_history[referral].length(); i ++){
            uint256 purchaseTime = referral_history[referral].at(i);

            if(purchaseTime >= from && purchaseTime < to){
                numberOfReferrals ++;
            }
        }

        address[] memory _buyer = new address[](numberOfReferrals);
        uint256[] memory _purchaseTime = new uint256[](numberOfReferrals);
        uint256 index = 0;

        for(uint256 i; i < referral_history[referral].length(); i ++){
            uint256 purchaseTime = referral_history[referral].at(i);

            if(purchaseTime >= from && purchaseTime < to){
                _buyer[index] = buyers[purchaseTime];
                _purchaseTime[index] = purchaseTime;
                index ++;
            }
        }

        return BuyerInfo(_buyer, _purchaseTime);
    }
}