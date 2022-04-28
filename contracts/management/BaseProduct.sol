// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


abstract contract Product is Ownable{

    bool internal isLocked;
    address public buyTokenAddress;
    uint8 internal productFee;
    uint internal productFeeTotal;
    uint internal indexPriceAdjustment;

    event ProductBuy(address account, uint buyTokenAmount, uint indexTokenAmount);
    event ProductSell(address account, uint buyTokenAmount, uint indexTokenAmount);

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
        uint productFeeAmount = (amount / productFeeTotal) * productFee;
        uint realAmount = amount - productFeeAmount;
        return (productFeeAmount, realAmount);
    }

    function getFee() external view returns(uint, uint){
        return (productFee, productFeeTotal);
    }

}
