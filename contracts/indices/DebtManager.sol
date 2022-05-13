// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";


contract DebtManager{

    using SafeMath for uint256;
    uint private totalAvailableDebt;
    mapping(address => uint) private usersDebt;
    event DebtChanged(address account, uint debtAmount);

    function getUserDebt(address account) external view returns (uint) {
        return usersDebt[account];
    }

    function getTotalDebt() external view returns (uint) {
        return totalAvailableDebt;
    }

    function changeDebt(address account, uint debtAmount, bool isAddition) external {
        if (isAddition) {
            usersDebt[account] = usersDebt[account].add(debtAmount);
            totalAvailableDebt = totalAvailableDebt.add(debtAmount);
        }else{
            usersDebt[account] = usersDebt[account].sub(debtAmount);
            totalAvailableDebt = totalAvailableDebt.sub(debtAmount);
        }

        require(usersDebt[account] >= 0, "Debt cannot be negative");
        emit DebtChanged(account, debtAmount);
    }

}
