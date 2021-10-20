// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IMagicStoneNFT{
    function createStone(address receiver) external;
    function priceStone() external view returns (uint256);
    function burn(uint256 _tokenId, address _address) external;
    function ownerOf(uint256 _tokenId) external view returns(address);
    function balanceOf(address _address) external view returns(uint256);
    function tokenOfOwnerByIndex(address _address, uint256 _index) external view returns(uint256);
    function totalSupply() external view returns(uint256);
}