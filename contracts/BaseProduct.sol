// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


abstract contract Product is Ownable{

    uint8 internal indexFee;
    uint internal indexFeeTotal;

    bool internal isLocked;
    uint internal indexPriceAdjustment;
    address public buyTokenAddress;

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

    function buy(uint amount) virtual external;
    function sell(uint amount) virtual external;
    function getPrice() virtual public view returns(uint);

    function calculateFee(uint amount) internal view returns(uint, uint){
        uint indexFeeAmount = (amount / indexFeeTotal) * indexFee;
        uint realAmount = amount - indexFeeAmount;
        return (indexFeeAmount, realAmount);
    }

    function retrieveFees() external onlyOwner{
        IERC20 buyToken = IERC20(buyTokenAddress);
        buyToken.transfer(owner(), buyToken.balanceOf(address(this)));
    }

}
