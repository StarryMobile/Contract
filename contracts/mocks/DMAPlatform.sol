pragma solidity ^0.4.24;

import "./TokenDMA.sol";
import "./NFTokenDMA.sol";
import "./AssetMap.sol";

/**
 * @dev This is an example contract implementation of Token.
 */
contract DMAPlatform {
  using SafeMath for uint256;
  
  // 上线资产表
  AssetMap.Data  approveMap;

  // NFToken合约地址
  address internal token721;
  // ERC20合约地址
  address internal token20;

  enum AssetStatus { Online, SoldOut}

  event SaveApprove(
    address indexed _owner,
    uint256 indexed _tokenId,
    uint256 indexed _value
  );

  event RevokeApprove(
    address indexed _owner,
    uint256 indexed _tokenId,
    uint256 _count
  );

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId,
    uint256  _count,
    uint256  _value
  );

  event IncCnt(
    address  _owner,
    uint256  _cnt
  );
  
  // 所有资产列表
  mapping (address => mapping(uint256 => uint256)) internal allAssets;
  mapping (address => uint256) internal assetCount;

  // 构造函数
  constructor(
    address  _token721,
    address  _token20
  )
    public
  {
    require(_token721 != address(0), "invalid erc721 address");
    require(_token20 != address(0), "invalid erc20 address");
    require(_token721 != _token20, "shoud diffirent between erc721 and erc20");
    token721 = _token721;
    token20 = _token20;
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
    address tokenOwner = NFTokenDMA(token721).ownerOf(_tokenId);
    address approver = NFTokenDMA(token721).getApproved(_tokenId);
    require(approver == address(this), "invalid approve address");
    require(tokenOwner == _owner, "invalid tokenId owner");
    require(tokenOwner == msg.sender, "invalid caller");
    allAssets[_owner][_tokenId] = _value;
    incAssetCnt(_owner);
    emit SaveApprove(_owner, _tokenId, _value);
  }

  /**
   * @dev 保存用户授权信息，支持同类多份资产，资产上线
   * @param _owner     资产所有者
   * @param _tokenId   首个资产编号
   * @param _count     资产数量(至少为1)
   * @param _value     每份资产价值 
   */  
  function saveMultiApprove(
    address _owner,
    uint256 _tokenId,
    uint256 _count,
    uint256 _value
  ) 
    public
  {
    require(_count > 0, "count should more than 0");
    uint256 startId = AssetMap.nextTokenId(approveMap, _owner, _tokenId);
    for (uint256 idx = 0; idx < _count; idx++) {
      uint256 tId = startId.add(idx);
      _saveApprove(_owner, tId, _value);
    }
    AssetMap.update(approveMap, _owner, _tokenId, startId.add(_count));
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
    saveMultiApprove(_owner, _tokenId, 1, _value);   
  }

 /**
   * @dev 获取某类上线资产的最后一个编号
   * @param    _to        资产所有者
   * @param    _tokenId   首个资产编号(作为资产标识)
   */
  function getLatestTokenId(
    address _to,
    uint256 _tokenId
  ) 
    external
    view
    returns (uint256 _tid)
  {
    _tid = AssetMap.getLatestTokenId(approveMap, _to, _tokenId);
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
   * @param _tokenId    首个资产编号
   * @param _count      资产数量(至少1个)
   */ 
  function  revokeApprove(
    uint256 _tokenId,
    uint256 _count
  ) 
    external 
    returns (bool _success) 
  {
    require(_count > 0, "count should more than 0");
    for (uint256 idx = 0; idx < _count; idx++) {
      uint256 tid = _tokenId.add(idx);
      address tokenOwner = NFTokenDMA(token721).ownerOf(tid);
      require(allAssets[tokenOwner][tid] > 0, "asset shoud exist");
      require(tokenOwner == msg.sender, "No permission");
      NFTokenDMA(token721).revokeApprove(tid);      
    }
    deleteApprove(tokenOwner, _tokenId, _count);
    emit RevokeApprove(tokenOwner, _tokenId, _count);
    _success = true;
  }

  /**
   * @dev check total value
   * @param _tokenId  首个资产编号
   * @param _count    资产数量(至少1个)
   */

  function checkTotalValue(
    uint256 _tokenId,
    uint256 _count,
    uint256 _totalValue
  ) 
    internal
    view
  {
    require(_count > 0, "count should more than 0");
    require(_totalValue > 0, "total value should more than 0");
    uint256 _value = 0;
    address tokenOwner = NFTokenDMA(token721).ownerOf(_tokenId);
    for (uint256 idx = 0; idx < _count; idx++) {
      uint256 tid = _tokenId.add(idx);
      require(allAssets[tokenOwner][tid] > 0, "asset shoud exist");
      _value = _value.add(allAssets[tokenOwner][tid]);
    } 
    require(_totalValue >= _value, "invalid total value");
  }

  /**
   * @dev 根据传入信息进行匹配，完成 erc721 token 代币与 DMA 代币的交换
   * @param _tokenId  首个资产编号
   * @param _count    资产数量(至少1个)
   * @param _value    成交总价格
   */ 
  function transfer(
    uint256 _tokenId,
    uint256 _count,
    uint256 _value
  )
    external
    returns (bool _success) 
  {
    require(_count > 0, "count should more than 0");
    checkTotalValue(_tokenId, _count, _value);
    address tokenOwner = NFTokenDMA(token721).ownerOf(_tokenId);
    for (uint256 idx = 0; idx < _count; idx++) {
      uint256 tid = _tokenId.add(idx);
      require(allAssets[tokenOwner][tid] > 0, "asset shoud exist");
      address approver = NFTokenDMA(token721).getApproved(tid);
      require(approver == address(this), "no permission for 721 approve");
      NFTokenDMA(token721).safeTransferFrom(tokenOwner, msg.sender, tid);
    }  
    uint256 dmaApprove = TokenDMA(token20).freezeValue(msg.sender, address(this));
    require(dmaApprove >= _value, "no enough approve");
    TokenDMA(token20).transferFromFreeze(msg.sender, tokenOwner, _value);
    deleteApprove(tokenOwner, _tokenId, _count);
    emit Transfer(tokenOwner, msg.sender, _tokenId, _count, _value);
    _success = true;
  }

  /**
   * @dev delete an approve
   * @param _owner     资产所有者
   * @param _tokenId   首个资产编号
   * @param _count     资产数量(至少1个)
   */
  function deleteApprove(
    address _owner,
    uint256 _tokenId,
    uint256 _count
  )
    internal 
  {
    require(_count > 0, "count shoud more than 0");
    for (uint256 idx = 0; idx < _count; idx++) {
      uint256 tid = _tokenId.add(idx);
      delete allAssets[_owner][tid];
      decAssetCnt(_owner);
    }
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