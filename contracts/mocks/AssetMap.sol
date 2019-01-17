pragma solidity ^0.4.24;

import "../math/SafeMath.sol";

library AssetMap {
  using SafeMath for uint256;

  struct Data {
    mapping (address => mapping (uint256 => uint256)) assetMapping;
  }

  /**
   * @dev 记录某人拥有同类资产的最后一个资产编号, 用于合并同类资产情况
   * @param  _self       资产记录表
   * @param  _owner      资产所有者
   * @param  _tokenId    资产编号(以此做为资产比较标记)
   * @param  _latestTokenId   该类资产最后一个资产编号
   */
  function update(
    Data storage _self,
    address _owner,
    uint256 _tokenId,
    uint256 _latestTokenId
  )
    internal
  {
    _self.assetMapping[_owner][_tokenId] = _latestTokenId;
  }

  /**
   * @dev 获取某人某种资产的最后一个资产编号
   * @param    _self     资产记录表
   * @param  _owner      资产所有者
   * @param  _tokenId    资产编号(以此做为资产比较标记)
   */
  function getLatestTokenId(
    Data storage _self,
    address _owner,
    uint256 _tokenId
  )
    internal
    view
    returns (uint256 _tid)
  {
    _tid = _self.assetMapping[_owner][_tokenId];
  }


  /**
   * @dev 获取某类资产最后一个资产编号
   * @param    _self     资产记录表
   * @param    _to    资产所有者
   * @param    _tokenId  某类资产的首个资产编号
   */
  function nextTokenId(
    Data storage _self,
    address _to,
    uint256 _tokenId
  )
    internal
    view
    returns (uint256 _tid)
  {
    uint256 latestTokenId = _self.assetMapping[_to][_tokenId];
    if (latestTokenId != 0) {
      _tid = latestTokenId;
    } else {
      _tid = _tokenId;
    }
  }
}