// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@uniswap/v2-core/contracts/libraries/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "./interfaces/IAgtToken.sol";

contract AgeioController is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  mapping(address=>bool) public isAgtMasterChef;
  bool    public isSwappable;
  address public treasury;
  uint256 public treasuryFee = 150;
  uint256 public burnFee = 247;
  address public devaddr;    // developer Address.

  // uint256 public commissionFee = 400;             // 4%;
  uint256 public constant MAX_FEE = 1000;         // 10%;

  // Mainnet
  address public thetaswapRouter;
  address public factory;

  IUniswapV2Router02 private _thetaswapRouter;

  address public agtToken;

  modifier onlyAgtMasterChef() {
    require(isAgtMasterChef[_msgSender()], "Error: Invalid request");
    _;
  }

  constructor(address _agtToken, address _devaddr) {
    agtToken = _agtToken;
    treasury = _msgSender();
    isSwappable = false;
    devaddr = _devaddr;
  }

  function addMasterChef(address _chef, bool _isChef) public onlyOwner {
    if (_chef != address(0) && _isContract(_chef)) isAgtMasterChef[_chef] = _isChef;
    emit ChangedAgtMasterChef(_chef, _isChef);
  }

  function changeTreasury(address _treasury) public onlyOwner {
    if ( _treasury != address(0) ) treasury = _treasury;
    emit ChangedTreasury(treasury);
  }
  function changeAgtToken(address _agtToken) public onlyOwner {    
    agtToken = _agtToken;
  }
  function changeFee(uint256 _treasuryFee, uint256 _burnFee) public onlyOwner {
    if (_treasuryFee.add(_burnFee) <= MAX_FEE) {
      treasuryFee = _treasuryFee;
      burnFee = _burnFee;
    }
    emit ChangedFee(treasuryFee, burnFee);
  }
  function commission() public view returns (uint256) {
    return treasuryFee.add(burnFee);
  }
  function commissionFee() public view returns(uint256, uint256) {
    return (treasuryFee, burnFee);
  }
  function dev(address _devAddress) public {
    require(_msgSender() == devaddr, "dev: wut?");
    devaddr = _devAddress;
  }

  function initialize(address thetaswapRouter_) public onlyOwner {
    thetaswapRouter = thetaswapRouter_;

    _thetaswapRouter = IUniswapV2Router02(thetaswapRouter_);
    factory = _thetaswapRouter.factory();
    isSwappable = true;
  }
  function claimAgtReward(address account, uint256 amount) public onlyAgtMasterChef {
    uint256 _amount = amount > IERC20(agtToken).balanceOf(address(this)) ? IERC20(agtToken).balanceOf(address(this)) : amount;
    IERC20(agtToken).safeTransfer(account, _amount);
    IERC20(agtToken).safeTransfer(devaddr, _amount.div(20));  //5% to developer
  }
  function claimTfuelReward() public onlyOwner {
    safeTransferTfuel(_msgSender(), address(this).balance);
  }

  function swapAgtWithTfuel(uint256 amount) public payable returns (bool) {
    if (msg.value == 0) return false;
    if (isSwappable) {
      _swapTfuelForTokens(msg.value, agtToken);
    }
    else {
      safeTransferTfuel(treasury, msg.value);
    }
    return true;
  }
  function estTfuelAmount(uint256 agtAmount) public view returns(uint256) {
    address[] memory path = new address[](2);
    path[0] = agtToken;
    path[1] = _thetaswapRouter.WETH();
    uint256[] memory ret = _thetaswapRouter.getAmountsOut(agtAmount, path);
    return ret[1];
  }
  function estAgtAmount(uint256 tfuelAmount) public view returns(uint256) {
    address[] memory path = new address[](2);
    path[0] = _thetaswapRouter.WETH();
    path[1] = agtToken;
    uint256[] memory ret = _thetaswapRouter.getAmountsOut(tfuelAmount, path);
    return ret[1];
  }

  function getAgtAmountFromTfuel(uint256 tfuelAmount) public view returns(uint256) {
    address pairAddress = IUniswapV2Factory(factory).getPair(_thetaswapRouter.WETH(), agtToken);
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
    //decimals
    return tfuelAmount.mul(reserve0).div(reserve1);
  }

  function safeTransferTfuel(address to, uint256 value) internal {
    (bool success, ) = to.call{gas: 23000, value: value}("");
    require(success, 'TransferHelper: TFUEL_TRANSFER_FAILED');
  }

  receive() external payable {}

  // swaps Tfuel on the contract for Tokens
  function _swapTfuelForTokens(uint256 tfuelAmount, address forTokenAddress) internal {
    address[] memory path = new address[](2);
    path[0] = _thetaswapRouter.WETH();
    path[1] = forTokenAddress;

    _thetaswapRouter.swapExactETHForTokens{value: tfuelAmount}(
      0,
      path,
      address(this),
      block.timestamp
    );
  }
  /**
    * @notice Checks if address is a contract
    * @dev It prevents contract from being targetted
    */
  function _isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  function closeAgeio() public onlyOwner {
    IERC20(agtToken).transfer(_msgSender(), IERC20(agtToken).balanceOf(address(this)));
    safeTransferTfuel(_msgSender(), address(this).balance);
  }

  event ChangedAgtMasterChef(address chef, bool isChef);
  event ChangedTreasury(address treasury);
  event ChangedFee(uint256 treasuryFee, uint256 burnFee);
}