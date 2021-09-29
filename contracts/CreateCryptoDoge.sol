// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./ICryptoDogeNFT.sol";

contract CreateCryptoDoge is Ownable{
    using SafeERC20 for IERC20;
    // using EnumerableSet for EnumerableSet.UintSet;

    address public cryptoDogeNFT;
    address public token;
    mapping (uint256 => uint256) private classInfo;
    uint256[6] public classes;
    uint256 public uncommonEstate;
    uint256 public rareEstate;
    uint256 public superRareEstate;
    uint256 public epicEstate;
    uint256 public legendaryEstate;
    event DNASet(uint256 _tokenId, uint256 _dna, uint256 _rare, uint256 _classInfo);

    constructor (){
        // token = address(0x4A8D2D2ee71c65bC837997e79a45ee9bbd360d45);
        token = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        cryptoDogeNFT = address(0x100B112CC0328dB0746b4eE039803e4fDB96C34d);
        // ICryptoDogeNFT(cryptoDogeNFT).setApprovalForAll(cryptoDogeNFT, true);
        classes[0] = 16;
        classes[1] = 7;
        classes[2] = 3;
        classes[3] = 3;
        classes[4] = 2;
        classes[5] = 2;
    }

    function setCryptoDogeNFT(address _nftAddress) public onlyOwner{
        cryptoDogeNFT = _nftAddress;
        // ICryptoDogeNFT(cryptoDogeNFT).setApprovalForAll(cryptoDogeNFT, true);
    }

    function buyEgg(uint8[] memory tribe) public {
        uint256 priceEgg = ICryptoDogeNFT(cryptoDogeNFT).priceEgg();
        IERC20(token).safeTransferFrom(msg.sender, address(this), priceEgg);
        ICryptoDogeNFT(cryptoDogeNFT).layEgg(msg.sender, tribe);
        uint256 totalDoges = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(msg.sender);
        uint256 lastTokenId = ICryptoDogeNFT(cryptoDogeNFT).tokenOfOwnerByIndex(msg.sender, totalDoges - 1);
    }

    function setDNA(uint256 tokenId) public {
        require(ICryptoDogeNFT(cryptoDogeNFT).ownerOf(tokenId) == msg.sender, "not own");
        uint256 randNonce = ICryptoDogeNFT(cryptoDogeNFT).balanceOf(msg.sender);
        uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10**30;
        ICryptoDogeNFT(cryptoDogeNFT).evolve(tokenId, msg.sender, dna);
        uint256 dogeRare = ICryptoDogeNFT(cryptoDogeNFT).getRare(tokenId);
        classInfo[tokenId] = dna % classes[dogeRare-1];
        emit DNASet(tokenId, dna, dogeRare, classInfo[tokenId]);
    }

    function setClasses(uint256 rare, uint256 classNumber) public {
        classes[rare-1] = classNumber;
    }

    function getClassInfo(uint256 tokenId) public view returns(uint256){
        return classInfo[tokenId];
    }
}