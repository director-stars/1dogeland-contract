// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoDogeManager is Ownable{
    using SafeMath for uint256;
    using Address for address;

    mapping (address => bool) public evolvers;
    mapping (address => bool) public markets;
    mapping (address => bool) public farmOwners;
    mapping (address => bool) public battlefields;

    uint256 public priceEgg;
    address public feeAddress;
    uint256 public divPercent;
    uint256 public feeMarketRate;
    uint256 public feeChangeTribe;
    uint256 public loseRate;
    uint256 public feeEvolve;

    constructor () {
        feeAddress = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        priceEgg = 9999000000000000000000;
        // priceEgg = 9999;
        divPercent = 100;
        feeMarketRate = 5;
    }

    function addBattlefields(address _address) public onlyOwner {
        require(!battlefields[_address], "Already exist battlefield");
        battlefields[_address] = true;
    }

    function addEvolvers(address _address) public onlyOwner {
        require(!evolvers[_address], "Already exist evolver");
        evolvers[_address] = true;
    }

    function addMarkets(address _address) public onlyOwner {
        require(!markets[_address], "Already exist market");
        markets[_address] = true;
    }

    function addFarmOwners(address _address) public onlyOwner {
        require(!farmOwners[_address], "Already exist farmOwner");
        farmOwners[_address] = true;
    }

    function timesBattle(uint256 level) public view returns (uint256){
        return 0;
    }

    function timeLimitBattle() public view returns (uint256){
        return 0;
    }

    function generation() public view returns (uint256){
        return 0;
    }

    function xBattle() public view returns (uint256){
        return 0;
    }

    function setPriceEgg(uint256 newPrice) public onlyOwner {
        priceEgg = newPrice;
    }

    function setDivPercent(uint256 _divPercent) public onlyOwner {
        divPercent = _divPercent;
    }

    function feeUpgradeGeneration() public view returns (uint256){
        return 0;
    }

    function setFeeChangeTribe(uint256 _feeChangeTribe) public onlyOwner{
        feeChangeTribe = _feeChangeTribe;
    }

    function setFeeMarketRate(uint256 _feeMarketRate) public onlyOwner{
        feeMarketRate = _feeMarketRate;
    }

    function setLoseRate(uint256 _loseRate) public onlyOwner {
        loseRate = _loseRate;
    }

    function setFeeEvolve(uint256 _feeEvolve) public onlyOwner {
        feeEvolve = _feeEvolve;
    }

    function setFeeAddress(address _address) public onlyOwner {
        feeAddress = _address;
    }

}