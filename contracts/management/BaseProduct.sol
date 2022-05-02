// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


abstract contract Product is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    bool public isLocked;
    address public buyTokenAddress;
    uint8 internal productFee;
    uint internal productFeeTotal;
    uint internal indexPriceAdjustment;

    event ProductBought(address account, uint buyTokenAmount, uint indexTokenAmount);
    event ProductSold(address account, uint buyTokenAmount, uint indexTokenAmount);

    modifier checkUnlocked{
        require(!isLocked, "Product is locked");
        _;
    }

    function name() virtual external pure returns(string memory);
    function symbol() virtual external pure returns(string memory);
    function shortDescription() virtual external pure returns(string memory);
    function longDescription() virtual external pure returns(string memory);
    function getTotalLockedValue() virtual external view returns(uint);
    function image() virtual external pure returns(string memory);

    function buy(uint amount) virtual external;
    function sell(uint amount) virtual external;
    function getPrice() virtual public view returns(uint);

    function calculateFee(uint amount) public view returns(uint, uint){
        uint productFeeAmount = amount.div(productFeeTotal).mul(productFee);
        uint realAmount = amount.sub(productFeeAmount);
        return (productFeeAmount, realAmount);
    }

    function getFee() external view returns(uint, uint){
        return (productFee, productFeeTotal);
    }

}
