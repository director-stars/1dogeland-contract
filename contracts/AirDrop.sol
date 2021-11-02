// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// For test suite
contract AirDrop is Ownable{
    using SafeERC20 for ERC20;
    event WithDraw(address account, uint256 time);
    mapping (address => bool) public contributors;
    mapping (address => uint256) public withdrawDate;
    address public token;
    uint256 public amount;

    constructor(){
        token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        amount = 1250 * 1e18;
    }

    function setToken(address _token) public onlyOwner{
        token = _token;
    }

    function setAmount(uint256 _amount) public onlyOwner{
        amount = _amount;
    }

    function airDrop(address _address) public{
        require(contributors[_address], "not allowed");
        require(withdrawDate[_address] == 0, "already withdrawn");
        ERC20 erc20token = ERC20(token);
        erc20token.safeTransfer(_address, amount);
        withdrawDate[_address] = block.timestamp;
        emit WithDraw(_address, block.timestamp);
    }

    function withdraw(address _address, uint256 _amount) public onlyOwner{
        ERC20 erc20token = ERC20(token);
        erc20token.safeTransfer(_address, _amount);
    }

    function addContributors(address[] memory _contributors) public onlyOwner{
        uint8 i;
        for(i; i < _contributors.length; i ++){
            contributors[_contributors[i]] = true;
            withdrawDate[_contributors[i]] = 0;
        }
    }
}