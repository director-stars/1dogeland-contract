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
    uint256 public feeMarketRatePercent;
    uint256 public feeMarketRate;
    uint256 public feeChangeTribe;
    uint256 public loseRate;
    uint256 public feeEvolve;
    uint256 public ownableMaxSize;
    uint256 public referralRate;
    uint256 public referralRatePercent;

    constructor () {
        feeAddress = address(0x67926b0C4753c42b31289C035F8A656D800cD9e7);
        // priceEgg = 9999000000000000000000;
        priceEgg = 9999;
        feeMarketRate = 5;
        feeMarketRatePercent = 100;
        ownableMaxSize = 5;
        referralRate = 10;
        referralRatePercent = 100;
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

    function feeUpgradeGeneration() public view returns (uint256){
        return 0;
    }

    function setFeeChangeTribe(uint256 _feeChangeTribe) public onlyOwner{
        feeChangeTribe = _feeChangeTribe;
    }

    function setFeeMarketRate(uint256 _feeMarketRate) public onlyOwner{
        assert(_feeMarketRate < feeMarketRatePercent);
        feeMarketRate = _feeMarketRate;
    }

    function setFeeMarketRatePercent(uint256 _feeMarketRatePercent) public onlyOwner {
        assert(_feeMarketRatePercent >= 100);
        feeMarketRatePercent = _feeMarketRatePercent;
    }

    function setOwnableMaxSize(uint256 _ownableMaxSize) public onlyOwner{
        assert(_ownableMaxSize > 0);
        ownableMaxSize = _ownableMaxSize;
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

    function setReferralRate(uint256 _referralRate) public onlyOwner {
        assert(_referralRate < referralRatePercent);
        referralRate = _referralRate;
    }

    function setReferralRatePercent(uint256 _referralRatePercent) public onlyOwner {
        assert(_referralRatePercent >= 100);
        referralRatePercent = _referralRatePercent;
    }
}