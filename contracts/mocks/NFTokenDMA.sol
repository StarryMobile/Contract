pragma solidity ^0.4.24;

import "../tokens/NFTokenMetadata.sol";
import "../tokens/NFTokenEnumerable.sol";
import "../ownership/Ownable.sol";
import "./AssetMap.sol";

/**
 * @dev This is an example contract implementation of NFToken with enumerable and metadata
 * extensions.
 */
contract NFTokenDMA is
  NFTokenEnumerable,
  NFTokenMetadata,
  Ownable
{
  using AssetMap for AssetMap.Data;
  // 资产表
  AssetMap.Data assetMap;

  /**
   * @dev token status map
   */
  mapping (address => mapping (uint256 => uint256)) statusMap;

  /**
   * @dev token user map
   */
  mapping (address => mapping (uint256 => string))  userMap;

  /**
   * @dev Contract constructor.
   * @param _name A descriptive name for a collection of NFTs.
   * @param _symbol An abbreviated name for NFTokens.
   * @param _metadata A metadata url for NFTokens.
   */
  constructor(
    string _name,
    string _symbol,
    string _metadata
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
    metadata = _metadata;
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */

  function _mint(
    address _to,
    uint256 _tokenId,
    string _uri
  )
    internal
    onlyOwner
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }

  /**
   * @dev 生成一份资产，内部调用生成多份同类资产方法
   * @param    _tokenId   首个资产编号(作为资产标识)
   * @param    _uri       资产数据网址
   */
  function mint(
    address _to,
    uint256 _tokenId,
    string _uri
  )
    external
    onlyOwner
  {
    mintMulti(_to, _tokenId, 1, _uri);
  }

  /**
   * @dev 生成多份同类资产
   * @param    _to        资产所有者
   * @param    _tokenId   首个资产编号(作为资产标识)
   * @param    _count     资产数量
   * @param    _uri       资产数据网址
   */
  function mintMulti(
    address _to,
    uint256 _tokenId,
    uint256 _count,
    string _uri
  )
    public
    onlyOwner
  {
    require(_tokenId > 0, "tokenId should over 0");
    require(_count > 0, "Count number should over 0");
    uint256 startId = assetMap.nextTokenId(_to, _tokenId);
    for (uint256 idx = 0; idx < _count; idx++) {
      _mint(_to, startId.add(idx), _uri);
    }
    assetMap.update(_to, _tokenId, startId.add(_count));
  }

  /**
   * @dev 获取资产的最后一个编号
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
    _tid = assetMap.getLatestTokenId(_to, _tokenId);
  }

  /**
   * @dev Removes a NFT from owner.
   * @param _owner Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function burn(
    address _owner,
    uint256 _tokenId
  )
    external
    onlyOwner
  {
    super._burn(_owner, _tokenId);
  }

  function checkUri(
     uint256 _tokenId
  )
     external
     view
     returns (string)
  {
     return idToUri[_tokenId];
  }

  /**
   * @dev set token staus
   */
  function setStatus(
    address _owner,
    uint256 _tokenId,
    uint256 _status
  )
    external
  {
    statusMap[_owner][_tokenId] = _status;
  }

  /**
   * @dev set token user
   */
  function setUser(
    address _owner,
    uint256 _tokenId,
    string  _user
  )
    external
  {
    userMap[_owner][_tokenId] = _user;
  }


  /**
   * @dev get token staus
   */
  function getStatus(
    address _owner,
    uint256 _tokenId
  )
    external
    view
    returns (uint256 _status)
  {
    _status = statusMap[_owner][_tokenId];
  }

  /**
   * @dev get token user
   */
  function getUser(
    address _owner,
    uint256 _tokenId
  )
    external
    view
    returns (string _user)
  {
    _user = userMap[_owner][_tokenId];
  }
}
