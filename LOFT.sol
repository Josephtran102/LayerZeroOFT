// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    // https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses
    Goerli          lzEndpointAddress = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23
    chainId: 10121  deploymentAddress = 
    Mumbai          lzEndpointAddress = 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8
    chainId: 10109  deploymentAddress = 
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "https://github.com/LayerZero-Labs/solidity-examples/blob/b68756ea77866d3731a480f80ed10bb9d6d7bf40/contracts/token/oft/v1/OFTCore.sol";
import "https://github.com/LayerZero-Labs/solidity-examples/blob/b68756ea77866d3731a480f80ed10bb9d6d7bf40/contracts/token/oft/v1/interfaces/IOFT.sol";

contract LayerZeroOFT is OFTCore, ERC20, IOFT {
    address constant lzEndpointAddress = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23;

    constructor() ERC20("LayerZeroOFT", "LZOFT") OFTCore(lzEndpointAddress) Ownable(msg.sender) {
        if (block.chainid == 5) { // Only mint initial supply on Goerli
            _mint(msg.sender, 1_000_000 * 10 ** decimals());
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OFTCore, IERC165) returns (bool) {
        return interfaceId == type(IOFT).interfaceId || interfaceId == type(IERC20).interfaceId || super.supportsInterface(interfaceId);
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _amount) internal virtual override returns(uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(uint16, address _toAddress, uint _amount) internal virtual override returns(uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }
}
