// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IWThetaToken {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  function claimReward() external;
  function balanceInfo(address account) external view returns(uint256 amount, uint256 rewardDebt, uint256 totalCap);
  function earned(address account) external view returns(uint256);
  function balanceInAllAMM() external view returns(uint256);
  function totalSupplyInAllAMM() external view returns(uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}