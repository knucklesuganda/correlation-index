// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './Token.sol';


contract Index is Token {
    uint256 constant private MAX_UINT256 = 2 ** 256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    uint256 public totalFunds;
    mapping(address => uint256) public investors;
    uint256 private minimalFundAddition = 1000000000000000;
    address private owner;
    string[] public tokens = ["WBTC", "ETH", "BNB", "MANA", "HBAR"];

    uint256 public totalSupply;
    string public name = "Correlation Index";
    string public symbol = "CI";
    uint8 public decimals = 18;

    constructor(uint256 _initialAmount) {
        balances[msg.sender] = _initialAmount;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value, "token balance is lower than the value requested");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 allowedTransfer = allowed[_from][msg.sender];
        require(
            balances[_from] >= _value && allowedTransfer >= _value,
            "token balance or allowance is lower than amount requested"
        );
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowedTransfer < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function getPrice() public pure returns (uint256) {
        return 100;
    }

    function addFunds() public payable {
        require(msg.value > minimalFundAddition, "You must send funds");
        totalFunds += msg.value;
        investors[msg.sender] += msg.value;
    }

    function getTotalPrice() public payable returns(uint256){
        return totalFunds * getPrice();
    }

}