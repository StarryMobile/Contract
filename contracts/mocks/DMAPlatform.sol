pragma solidity ^0.4.24;

import "./TokenDMA.sol";
import "./NFTokenDMA.sol";
import "./TokenUtil.sol";

/**
 * @dev This is an example contract implementation of Token.
 */
contract DMAPlatform {
  using SafeMath for uint256;

  using TokenUtil for uint256;

 
  // NFToken合约地址
  address internal token721;
  // ERC20合约地址
  address internal token20;
  
  //平台收款地址 
  address internal platformAddress;
  //一手收取费用
  uint256 internal  firstExpenses;
  //二手收取费用
  uint256 internal secondExpenses;
  

  enum AssetStatus { Online, SoldOut}

  event SaveApprove(
    address indexed _owner,
    uint256 indexed _tokenId,
    uint256 indexed _value
  );

  event RevokeApprove(
    address indexed _owner,
    uint256 indexed _tokenId
  );

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256[] _array,
    uint256  _value
  );

  event IncCnt(
    address  _owner,
    uint256  _cnt
  );

  // 所有资产列表
  mapping (address => mapping(uint256 => uint256)) internal allAssets;
  mapping (address => uint256) internal assetCount;
  //tokenid转卖次数   
  mapping (uint256 =>  uint256) internal transferCount;

  // 构造函数
  constructor(
    address  _token721,
    address  _token20,
    address _platformAddress,
    uint256 _firstExpenses,
   uint256 _secondExpenses
  )
    public
  {
    require(_token721 != address(0), "invalid erc721 address");
    require(_token20 != address(0), "invalid erc20 address");
    require(_token721 != _token20, "shoud diffirent between erc721 and erc20");
    token721 = _token721;
    token20 = _token20;
    platformAddress=_platformAddress;
    firstExpenses=_firstExpenses;
    secondExpenses=_secondExpenses;
  }

  /**
   * @dev 保存授权信息
   * @param _tokenId      首个资产编号
   * @param _owner        资产所有者
   * @param _value        资产价值
   */
  function _saveApprove(
    address _owner,
    uint256 _tokenId,
    uint256 _value
  )
    internal
  {
    require(_owner != address(0), "invalid owner address");
    require(_value > 0, "value could more than 0");
    require(_tokenId > 0, "tokenId should more than 0");
    address tokenOwner = NFTokenDMA(token721).ownerOf(_tokenId);
    address approver = NFTokenDMA(token721).getApproved(_tokenId);
    bool isTransfer = NFTokenDMA(token721).getIsTransfer(_tokenId);
    require(isTransfer == true, "Assert can't be transfer");
    require(approver == address(this), "invalid approve address");
    require(tokenOwner == _owner, "invalid tokenId owner");
    require(tokenOwner == msg.sender, "invalid caller");
    allAssets[_owner][_tokenId] = _value;
    incAssetCnt(_owner);
    emit SaveApprove(_owner, _tokenId, _value);
  }

  /**
   *  @dev 以数组方式指定上线资产
   * @param _owner     资产所有者
   * @param _tokenArr   首个资产编号
   * @param _value     每份资产价值
   */
  function saveApproveWithArray(
    address     _owner,
    uint256[]   _tokenArr,
    uint256     _value
  )
    public
  {
    for (uint256 idx = 0; idx < _tokenArr.length; idx++) {
      _saveApprove(_owner, _tokenArr[idx], _value);
    }
  }


  /**
   * @dev  保存用户授权信息，资产上线
   * @param _owner     资产所有者
   * @param _tokenId   首个资产编号
   * @param _value     每份资产价值
   */
  function saveApprove(
    address _owner,
    uint256 _tokenId,
    uint256 _value
  )
    external
  {
       _saveApprove(_owner, _tokenId, _value);
  }

 


  /**
   * @dev 获取用户的授权信息
   * @param _tokenId    资产编号
   */
  function getApproveinfo(
    uint256 _tokenId
  )
    external
    view
    returns (address _owner, uint256 _tId, uint256 _value)
  {
    _owner = NFTokenDMA(token721).ownerOf(_tokenId);
    _value = allAssets[_owner][_tokenId];
    _tId = _tokenId;
  }

  /**
   * @dev 删除授权信息
   * @param _tokenArr    资产编号数组
   */
  function  revokeApprovesWithArray(
    uint256[] _tokenArr
  )
    public
  {
    for (uint256 idx = 0; idx < _tokenArr.length; idx++) {
       uint256 tid = _tokenArr[idx];
       address tokenOwner = NFTokenDMA(token721).ownerOf(tid);
       revokeApprove(tid);
    }
    deleteApproveWithArray(tokenOwner, _tokenArr);
  }

  /**
   * @dev 删除授权信息
   * @param _tokenId    首个资产编号
   */
  function  revokeApprove(
    uint256 _tokenId
  )
    public
  {
      address tokenOwner = NFTokenDMA(token721).ownerOf(_tokenId);
      require(allAssets[tokenOwner][_tokenId] > 0, "asset shoud exist");
      require(tokenOwner == msg.sender, "No permission");
      NFTokenDMA(token721).revokeApprove(_tokenId);
      emit RevokeApprove(tokenOwner, _tokenId);
  }

 

 

 

  /**
   * @dev 以指定数组进行交易
   * @param   _array      等交易资产数组
   * @param   _value      交易总金额
   */
  function transferWithArray(
    address     _owner,
    uint256[]   _array,
    uint256     _value
  )
    public
  {
    require(_array.length > 0, "array should not be empty");
   
    
    uint256 _firstValue = 0;
    uint256 _secondValue = 0;
    
    for (uint256 idx = 0; idx < _array.length; idx++) {
      uint256 tid = _array[idx];
      address tokenOwner = NFTokenDMA(token721).ownerOf(tid);
      require(tokenOwner == _owner, "assert owner is not matched.");
      require(allAssets[tokenOwner][tid] > 0, "asset shoud exist");
      address approver = NFTokenDMA(token721).getApproved(tid);
      require(approver == address(this), "no permission for 721 approve");
      NFTokenDMA(token721).safeTransferFrom(tokenOwner, msg.sender, tid);
      
    
      if(transferCount[tid]>0){
        _secondValue = _secondValue.add(allAssets[tokenOwner][tid]);
        
      }else{
        _firstValue =  _firstValue.add(allAssets[tokenOwner][tid]);
      }
      
      transferCount[tid]=  transferCount[tid].add(1);
      
    }
    
    
    uint256 _firstExpensesValue=0;
    
    uint256 _secondExpensesValue=0;
    
    if(_firstValue>0){
        _firstExpensesValue=_firstValue.mul(firstExpenses);
        _firstExpensesValue=_firstExpensesValue.div(1000);
    }
    
    if(_secondValue>0){
        _secondExpensesValue=_secondValue.mul(secondExpenses);
        _secondExpensesValue=_secondExpensesValue.div(1000);
    }
    
    uint256 dmaApprove = TokenDMA(token20).allowance(msg.sender, address(this));
    require(dmaApprove >= _value, "no enough approve");
    
    uint256 _totalValues= _firstValue.add(_secondValue);
    require(dmaApprove >= _totalValues, "no enough approve");
   
    
     
    
    uint256 _platformValue=_firstExpensesValue.add(_secondExpensesValue);
  
    uint256 _sendValue=_totalValues.sub(_platformValue);
    
    TokenDMA(token20).transferFrom(msg.sender, platformAddress, _platformValue);
    TokenDMA(token20).transferFrom(msg.sender, tokenOwner, _sendValue);
   
    deleteApproveWithArray(_owner, _array);
    
   // emit Transfer(_owner, msg.sender, _array, _sendValue);
  
   
  }

  /**
   * @dev 根据传入信息进行匹配，完成 erc721 token 代币与 DMA 代币的交换
   * @param _tokenId  首个资产编号
   * @param _value    成交总价格
   */
  function transfer(
    address _owner,
    uint256 _tokenId,
    uint256 _value
  )
    external
  {
  
    uint256[] memory r = _tokenId.convert(1);
    transferWithArray(_owner, r, _value);
  }

  /**
   * @dev delete an approve
   * @param _owner     资产所有者
   * @param _array     资产数组
   */
  function deleteApproveWithArray(
    address   _owner,
    uint256[] _array
  )
    internal
  {
    for (uint256 idx = 0; idx < _array.length; idx++) {
      uint256 tid = _array[idx];
      deleteApprove(_owner,tid);
    }
  }

 function deleteApprove(
    address   _owner,
    uint256 _tokenId
  )
    internal
  {
      delete allAssets[_owner][_tokenId];
      decAssetCnt(_owner);
    
  }


  /**
   * get the count of asset for a user
   */

  function getAssetCnt(
    address _owner
  )
    external
    view
    returns (uint256 _cnt)
  {
    _cnt = assetCount[_owner];
  }

  /**
   * increase the count of assets for a user
   */
  function incAssetCnt(
    address _owner
  )
    internal
  {
    assetCount[_owner] = assetCount[_owner].add(1);
    emit IncCnt(_owner, assetCount[_owner]);
  }

  /**
   * decrease the count of assets for a user.
   */
  function decAssetCnt(
    address _owner
  )
    internal
  {
    assert(assetCount[_owner] > 0);
    assetCount[_owner] = assetCount[_owner].sub(1);
  }
}