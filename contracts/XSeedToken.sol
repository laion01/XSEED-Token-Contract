// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Capped.sol";
import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./Pancakeswap/IPancakeRouter01.sol";
import "./Pancakeswap/IPancakeFactory.sol";
/**
 * @title XSeedToken
 * @dev Implementation of the XSeedToken
 */
contract XSeedToken is ERC20Capped, ERC20Mintable, ERC20Burnable {
    address constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant factoryAddress = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
    address constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    string constant t_name = "Moon Casino";
    string constant t_symbol = "Moca";
    uint256 constant t_cap = 100000000000000000000000000;
    uint256 constant t_initialBalance = 100000000000000000000000000;
    uint8 constant t_decimals = 18;

    address public dev4_wallet = 0xcb9a1AF13e3F0D90cCc381eB1d1C47a0e502a8E9;
    address public dev1_wallet = 0x281F53E18446510C11843c876D474C1Fc69Bd45e;
    address public marketing_wallet = 0x82DDc6c63a28Cb0FA5723Eb0a865e15f04c4f3c1;
    address public liquidity_fee_wallet = 0xA904c286d58d4f2D6C6Aec323E0A4b231d922Dcc;
    address public pairAddress = 0x0000000000000000000000000000000000000000;

    uint public dev3_fee = 4000000;
    uint public dev1_fee = 1000000;
    uint public marketing_fee = 5000000;
    uint public liquidity_fee = 2000000;
    uint public maximum_amount = 15;
    uint public fee_limit = 1000;
    uint public transaction_fee_decimal = 8;

    uint private initialized = 0;
    mapping (address => bool) public _blackList;

    constructor ()
        ERC20(t_name, t_symbol)
        ERC20Capped(t_cap)
        payable
    {
        _setupDecimals(t_decimals);
        _mint(address(this), t_initialBalance);
        _approve(address(this), routerAddress, t_initialBalance);

        IPancakeFactory pancakeFactory = IPancakeFactory(factoryAddress);
        pairAddress = pancakeFactory.createPair(address(this), WETH);
    }

    function init() external payable {
        if(initialized == 1)
            return ;
        addLiquidity(msg.sender, t_initialBalance);
        initialized = 1;
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyOwner {
        require(maxAmount(account, amount), "Nobody can take more than 15 000 000 xSeed in his wallet.");
        super._mint(account, amount);
    }

    function addLiquidity(
        address owner,
        uint256 tokenAmount
    ) internal {
        IPancakeRouter01 pancakeRouter = IPancakeRouter01(routerAddress);
        // add the liquidity
        pancakeRouter.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp
        );
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }

    /**
     * @dev Function to set transaction fee wallet.
     * @param _wallet wallet address stores Development fee
     */
    function setDevWallet(address _wallet) public onlyOwner {
        dev4_wallet = _wallet;
    }

    /**
     * @dev Function to set transaction fee wallet.
     * @param _wallet wallet address stores Marketing fee
     */
    function setMarketingWallet(address _wallet) public onlyOwner {
        marketing_wallet = _wallet;
    }

    /**
     * @dev Function to add address to _blackList
     * @param black_address is scamer's wallet address
     */
    function addBlackList(address black_address) public onlyOwner {
        _blackList[black_address] = true;
    }

    /**
     * @dev Function to remove address from _blackList
     * @param black_address is scamer's wallet address
     */
    function removeBlackList(address black_address) public onlyOwner {
        _blackList[black_address] = false;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     * Take transaction fee from sender and transfer fee to the transaction fee wallet.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(!_blackList[recipient], "This address is in blacklist!");

        if(sender == address(this) && recipient == pairAddress) {
            super.transferFrom(sender, recipient, amount);
            return true;
        }

        uint dev3_fee_amount = calculateFee(amount, dev3_fee);
        uint dev1_fee_amount = calculateFee(amount, dev1_fee);
        uint marketing_fee_amount = calculateFee(amount, marketing_fee);
        uint liquidity_fee_amount = calculateFee(amount, liquidity_fee);
        uint r_amount = amount - dev3_fee_amount - marketing_fee_amount - dev1_fee_amount;

        if(!(recipient == pairAddress || sender == pairAddress)) {
            liquidity_fee_amount = 0;
            r_amount += dev3_fee_amount;
            dev3_fee_amount = 0;
        }

        if(recipient == dev4_wallet || recipient == dev1_wallet || recipient == marketing_wallet || recipient == liquidity_fee_wallet || recipient == address(this)) {
            super.transferFrom(sender, recipient, amount);
            return true;
        }
        if(sender == dev4_wallet || sender == dev1_wallet || sender == marketing_wallet || sender == liquidity_fee_wallet || sender == address(this)) {
            super.transferFrom(sender, recipient, amount);
            return true;
        }

        r_amount -= liquidity_fee_amount;

        require(maxAmount(recipient, r_amount), "Nobody can take more than 15 000 000 xSeed in his wallet.");

        super.transferFrom(sender, liquidity_fee_wallet, liquidity_fee_amount);
        super.transferFrom(sender, dev4_wallet, dev3_fee_amount);
        super.transferFrom(sender, dev1_wallet, dev1_fee_amount);
        super.transferFrom(sender, marketing_wallet, marketing_fee_amount);
        super.transferFrom(sender, recipient, r_amount);
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!_blackList[recipient], "This address is in blacklist!");

        uint dev3_fee_amount = calculateFee(amount, dev3_fee);
        uint dev1_fee_amount = calculateFee(amount, dev1_fee);
        uint marketing_fee_amount = calculateFee(amount, marketing_fee);
        uint liquidity_fee_amount = calculateFee(amount, liquidity_fee);
        uint r_amount = amount - dev3_fee_amount - dev1_fee_amount - marketing_fee_amount;

        if(!(msg.sender == pairAddress || recipient == pairAddress)) {
            liquidity_fee_amount = 0;
            r_amount += dev3_fee_amount;
            dev3_fee_amount = 0;
        }
        if(recipient == dev4_wallet || recipient == dev1_wallet || recipient == marketing_wallet || recipient == liquidity_fee_wallet || recipient == address(this)) {
            super.transfer(recipient, amount);
            return true;
        }
        if(msg.sender == dev4_wallet || msg.sender == dev1_wallet || msg.sender == marketing_wallet || msg.sender == liquidity_fee_wallet || msg.sender == address(this)) {
            super.transfer(recipient, amount);
            return true;
        }

        r_amount -= liquidity_fee_amount;

        require(maxAmount(recipient, r_amount), "Nobody can take more than 15 000 000 xSeed in his wallet.");

        super.transfer(liquidity_fee_wallet, liquidity_fee_amount);
        super.transfer(dev4_wallet, dev3_fee_amount);
        super.transfer(dev1_wallet, dev1_fee_amount);
        super.transfer(marketing_wallet, marketing_fee_amount);
        super.transfer(recipient, r_amount);
        return true;
    }

    /**
     * @dev Function to set transaction dev fee.
     * @param amount transaction amount
     */
    function calculateFee(uint256 amount, uint256 fee) internal view returns (uint256) {
        return amount * fee / (10 ** transaction_fee_decimal);
    }

    function maxAmount(address account, uint256 amount) internal view returns(bool) {
        if(account == dev4_wallet || account == dev1_wallet || account == marketing_wallet || account == liquidity_fee_wallet || account == address(this))
            return true;
        if(balanceOf(account) + amount < (t_cap * maximum_amount / 100))
            return true;
        return false;
    }

    function checkFee() internal {
        if(balanceOf(address(this)) > calculateFee(t_cap, fee_limit)) {
            uint256 half= balanceOf(address(this))/2;
            uint256 ethAmount = 0;
            if(half <= 0)
                return ;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WETH;
            IPancakeRouter01 pancakeRouter = IPancakeRouter01(routerAddress);
            // add the liquidity
            _approve(address(this), routerAddress, 1e50);
            uint[] memory amounts = pancakeRouter.swapExactTokensForETH(half, 0, path, address(this), block.timestamp);
            ethAmount = amounts[1];

            pancakeRouter.addLiquidityETH{value: ethAmount}(
                address(this),
                half,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                getOwner(),
                block.timestamp
            );
        }
    }
}