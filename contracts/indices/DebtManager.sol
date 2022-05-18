// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract UserDebtData{
    mapping(address => uint) private debtData;
    mapping(address => bool) private userInSet;
    address[] private users;

    function add(address _addr) external {
        if(inSet[_addr]){
            return false;
        }

        userInSet[_addr] = true;
        users.push(_addr);
    }

    function changeDebt(address account, uint debtAmount, bool isAddition) external {
        if (isAddition) {
            debtData[account] = debtData[account].add(debtAmount);
        }else{
            debtData[account] = debtData[account].sub(debtAmount);
        }

        require(debtData[account] >= 0, "Debt cannot be negative");
    }

    function getUserDebt(address account) external view returns(uint) {
        return debtData[account];
    }

}


contract DebtManager{

    using SafeMath for uint256;
    uint private totalAvailableDebt;
    UserDebtData private debtData = new UserDebtData();
    event DebtChanged(address account, uint debtAmount);

    function getUserDebt(address account) external view returns (uint) {
        return debtData.getUserDebt(account);
    }

    function getTotalDebt() external view returns (uint) {
        return totalAvailableDebt;
    }

    function changeTotalDebt(uint debtAmount, bool isAddition) external {
        if (isAddition) {
            totalAvailableDebt = totalAvailableDebt.add(debtAmount);
        }else{
            totalAvailableDebt = totalAvailableDebt.sub(debtAmount);
        }
    }

    function changeDebt(address account, uint debtAmount, bool isAddition) external {
        debtData.changeDebt(account, debtAmount, isAddition);
        emit DebtChanged(account, debtAmount);
    }

}
