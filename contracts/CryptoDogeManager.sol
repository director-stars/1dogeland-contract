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

    constructor () {
        priceEgg = 9999;
    }

    function addBattlefields(address _address) external onlyOwner {
        require(!battlefields[_address], "Already exist battlefield");
        battlefields[_address] = true;
    }

    function addEvolvers(address _address) external onlyOwner {
        require(!evolvers[_address], "Already exist evolver");
        evolvers[_address] = true;
    }

    function addMarkets(address _address) external onlyOwner {
        require(!markets[_address], "Already exist market");
        markets[_address] = true;
    }

    function addFarmOwners(address _address) external onlyOwner {
        require(!farmOwners[_address], "Already exist farmOwner");
        farmOwners[_address] = true;
    }

    function timesBattle(uint256 level) external view returns (uint256){
        return 0;
    }

    function timeLimitBattle() external view returns (uint256){
        return 0;
    }

    function generation() external view returns (uint256){
        return 0;
    }

    function xBattle() external view returns (uint256){
        return 0;
    }

    function setPriceEgg(uint256 newPrice) external onlyOwner {
        priceEgg = newPrice;
    }

    function divPercent() external view returns (uint256){
        return 0;
    }

    function feeUpgradeGeneration() external view returns (uint256){
        return 0;
    }

    function feeChangeTribe() external view returns (uint256){
        return 0;
    }

    function feeMarketRate() external view returns (uint256){
        return 0;
    }

    function loseRate() external view returns (uint256){
        return 0;
    }

    function feeEvolve() external view returns (uint256){
        return 0;
    }

    function setFeeAddress(address _address) external onlyOwner {
        feeAddress = _address;
    }

}