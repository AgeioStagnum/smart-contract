// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IAgeioController {

  function treasury() external view returns (address);
  function commissionFee() external view returns(uint256 treasuryFee, uint256 burnFee);

  function claimAgtReward(address chef, uint256 _amount) external;
  function swapAgtWithTfuel(uint256 amount) external payable returns (bool);
  function getAgtAmountFromTfuel(uint256 tfuelAmount) external view returns(uint256);
}