// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


abstract contract Product is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public constant buyTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint8 internal productFee = 5;
    uint internal productFeeTotal = 100;
    bool internal isSettlement;

    event ProductBought(address account, uint buyTokenAmount, uint indexTokenAmount);
    event ProductSold(address account, uint buyTokenAmount, uint indexTokenAmount);

    modifier checkSettlement{
        require(!isSettlement, "Product is being settled, try again later");
        _;
    }

    function beginSettlement() virtual external onlyOwner { isSettlement = true; }
    function endSettlement() virtual external onlyOwner { isSettlement = false; }
    function isSettlementActive() external view returns(bool) { return isSettlement; }

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
        return (productFeeAmount, amount.sub(productFeeAmount));
    }

    function changeFee(uint8 _fee, uint _feeTotal) external onlyOwner {
        productFee = _fee;
        productFeeTotal = _feeTotal;
    }

    function getFee() external view returns(uint, uint){
        return (productFee, productFeeTotal);
    }

}
