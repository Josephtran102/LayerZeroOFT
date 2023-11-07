// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import "https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
    // LayerZero Goerli
    //   lzChainId:10121 lzEndpoint:0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23
    //   contract: 
    // LayerZero Mumbai
    //   lzChainId:10109 lzEndpoint:0xf69186dfBa60DdB133E91E9A4B5673624293d8F8
    //   contract: 
*/

contract ZROCrossChainToken is NonblockingLzApp, ERC20 {
    uint16 destChainId;
    
    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) ERC20("Test Cross Chain Token", "LZC") Ownable(msg.sender) {
        if (_lzEndpoint == 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23) destChainId = 10109;
        if (_lzEndpoint == 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8) destChainId = 10121;
        if (block.chainid == 5) { // Only mint initial supply on Goerli
            _mint(msg.sender, 1_000_000 * 10 ** decimals());
        }
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
       (address toAddress, uint amount) = abi.decode(_payload, (address,uint));
       _mint(toAddress, amount);
    }

    function bridge(uint _amount) public payable {
        _burn(msg.sender, _amount);
        bytes memory payload = abi.encode(msg.sender, _amount);
        _lzSend(destChainId, payload, payable(msg.sender), address(0x0), bytes(""), msg.value);
    }

    function trustAddress(address _otherContract) public onlyOwner {
        trustedRemoteLookup[destChainId] = abi.encodePacked(_otherContract, address(this));   
    }
}
