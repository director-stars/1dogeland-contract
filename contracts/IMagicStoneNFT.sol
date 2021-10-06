// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IMagicStoneNFT{
    function createStone(address receiver) external;
    function priceStone() external view returns (uint256);
    function burn(uint256 _tokenId, address _address) external;
    function ownerOf(uint256 _tokenId) external view returns(address);
}