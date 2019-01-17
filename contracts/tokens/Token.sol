pragma solidity ^0.4.24;

import "../math/SafeMath.sol";
import "../ownership/Ownable.sol";
import "./ERC20.sol";

/**
 * @title ERC20 standard token implementation.
 * @dev Standard ERC20 token. This contract follows the implementation at https://goo.gl/mLbAPJ.
 */
contract Token is
  ERC20,
  Ownable
{
  using SafeMath for uint256;

  /**
   * Token name.
   */
  string internal tokenName;

  /**
   * Token symbol.
   */
  string internal tokenSymbol;

  /**
   * Number of decimals.
   */
  uint8 internal tokenDecimals;

  /**
   * Total supply of tokens.
   */
  uint256 internal tokenTotalSupply;

  /**
   * allow kill the contract itself
   */
  bool internal isBurn;

  /**
   * Balance information map.
   */
  mapping (address => uint256) internal balances;

  /**
   * Token allowance mapping.
   */
  mapping (address => mapping (address => uint256)) internal allowed;

 
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  /**
   * @dev Trigger on any successful call to approve(address _spender, uint256 _value).
   */
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

 

  /**
   * @dev Trigger on any successful call to revokeApprove(address _spender, uint256 _value).
   */
  event RevokeApprove(
    address indexed _owner,
    address indexed _spender,
    uint256 indexed _amount
  );
  
  
   /**
   * @dev Trigger on any successful call to burn(address _spender, uint256 _value).
   */
  event Burn(address indexed burner, uint256 value);
  
  

  /**
   * @dev Returns the name of the token.
   */
  function name()
    external
    view
    returns (string _name)
  {
    _name = tokenName;
  }

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol()
    external
    view
    returns (string _symbol)
  {
    _symbol = tokenSymbol;
  }

  /**
   * @dev Returns the number of decimals the token uses.
   */
  function decimals()
    external
    view
    returns (uint8 _decimals)
  {
    _decimals = tokenDecimals;
  }

  /**
   * @dev Returns the total token supply.
   */
  function totalSupply()
    external
    view
    returns (uint256 _totalSupply)
  {
    _totalSupply = tokenTotalSupply;
  }

  /**
   * @dev Returns the account balance of another account with address _owner.
   * @param _owner The address from which the balance will be retrieved.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256 _balance)
  {
    _balance = balances[_owner];
  }

  /**
   * @dev Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. The
   * function SHOULD throw if the _from account balance does not have enough tokens to spend.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   */
  function transfer(
    address _to,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    _success = true;
  }

  /**
   * @dev Allows _spender to withdraw from your account multiple times, up to the _value amount. If
   * this function is called again it overwrites the current allowance with _value.
   * @param _spender The address of the account able to transfer the tokens.
   * @param _value The amount of tokens to be approved for transfer.
   */
  function approve(
    address _spender,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require(_value <= balances[msg.sender], "approve value could not more than balance");
    
    allowed[msg.sender][_spender] =allowed[msg.sender][_spender].add(_value) ;

    emit Approval(msg.sender, _spender, _value);
    _success = true;
  }

 

  /**
   * @dev  解除授权，由被授权者调用
   * @param  _owner   授权者
   * @param  _amount  授权额度
   */
  function revokeApprove(
    address _owner,
    uint256 _amount
  )
    external
  {
    require(_owner != address(0), "owner address invalid");
    require(_amount >= 0 && _amount <= allowed[msg.sender][_owner], "invalid amount");

    allowed[msg.sender][_owner]=allowed[msg.sender][_owner].sub(_amount);
 
    emit RevokeApprove( msg.sender,_owner, _amount);
  }

 

  /**
   * @dev Returns the amount which _spender is still allowed to withdraw from _owner.
   * @param _owner The address of the account owning tokens.
   * @param _spender The address of the account able to transfer the tokens.
   */
  function allowance(
    address _owner,
    address _spender
  )
    external
    view
    returns (uint256 _remaining)
  {
    _remaining = allowed[_owner][_spender];
  }

  /**
   * @dev Transfers _value amount of tokens from address _from to address _to, and MUST fire the
   * Transfer event.
   * @param _from The address of the sender.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);
    _success = true;
  }

  /**
   * @dev kill contract itself
   */
  function kill
  (

  )
    external
    onlyOwner
  {
    require(isBurn == true, "contract can't be kill by ifself");
    selfdestruct(owner);
  }

  /**
   * @dev add issue to someone
   * @param   _target  the target address to issue
   * @param   _amount  the issue amount
   */
  function addIssue(
    address _target,
    uint256 _amount
  )
    external
    onlyOwner
  {
    require(_amount > 0, "issue amount should more than 0");
    tokenTotalSupply = tokenTotalSupply.add(_amount);
    balances[_target] = balances[_target].add(_amount);
  }
  
   /**
    * @dev 销毁特定数量代币.
    * @param _value 销毁数量.
    */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        tokenTotalSupply = tokenTotalSupply.sub(_value);
        emit  Burn(burner, _value);
    }


}
