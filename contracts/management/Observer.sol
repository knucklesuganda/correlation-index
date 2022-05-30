// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseProduct.sol";


contract Observer is Ownable{

    event ProductAdded(address product, string productType);
    event ProductDeleted(address product);

    struct ProductInfo{
        address productAddress;
        string productType;
    }

    ProductInfo[] private products;

    function addProduct(address productAddress, string memory productType) external onlyOwner {
        products.push(ProductInfo(productAddress, productType));
        emit ProductAdded(productAddress, productType);
    }

    function removeProduct(address productAddress) external onlyOwner{

        for (uint256 index = 0; index < products.length; index++) {
            if (products[index].productAddress == productAddress) {

                for (uint i = index; i < products.length-1; i++){
                    products[i] = products[i+1];
                }

                products.pop();
                emit ProductDeleted(productAddress);
                break;
            }
        }

    }

    function checkProductExists(address productAddress) public view returns (bool) {
        for (uint256 index = 0; index < products.length; index++) {
            if (products[index].productAddress == productAddress) {
                return true;
            }
        }

        return false;
    }

    function getProducts() external view returns (ProductInfo[] memory){
        return products;
    }

    function getProductByIndex(uint index) external view returns(ProductInfo memory){
        return products[index];
    }

}
