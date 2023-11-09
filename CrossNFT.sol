// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "https://github.com/LayerZero-Labs/LayerZero/blob/main/contracts/interfaces/ILayerZeroEndpoint.sol";
import "https://github.com/LayerZero-Labs/LayerZero/blob/main/contracts/interfaces/ILayerZeroReceiver.sol";

contract OmniChainNFT is Ownable, ERC721, ILayerZeroReceiver  {
    uint256 counter = 0;
    uint256 nextId = 0;
    uint256 MAX = 100;
    uint256 gas = 350000;
    ILayerZeroEndpoint public endpoint;
    mapping(uint256 => bytes) public uaMap;
    
    struct NFTInfo {
        string name;
        string description;
        string imageURI;
    }
    
    // Mapping để lưu thông tin NFT bao gồm hình ảnh
    mapping(uint256 => NFTInfo) public nftInfo;

    event ReceiveNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter,
        string name,
        string description,
        string imageURI
    );

    constructor(
        address _endpoint,
        uint256 startId,
        uint256 _max
    ) ERC721("OmniChainNFT", "OOCCNFT") Ownable(msg.sender) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        nextId = startId;
        MAX = _max;
    }

    function setUaAddress(uint256 _dstId, bytes calldata _uaAddress)
        public
        onlyOwner
    {
        uaMap[_dstId] = _uaAddress;
    }

    function mint(string memory name, string memory description, string memory imageURI) external payable {
        require(nextId + 1 <= MAX, "Exceeds supply");
        nextId += 1;
        _safeMint(msg.sender, nextId);
        counter += 1;
        
        NFTInfo memory info = NFTInfo(name, description, imageURI);
        nftInfo[nextId] = info;
    }

    function crossChain(
        uint16 _dstChainId,
        bytes calldata _destination,
        uint256 tokenId
    ) public payable {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        // burn NFT
        _burn(tokenId);
        counter -= 1;
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gas);

        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= messageFee,
            "Must send enough value to cover messageFee"
        );

        endpoint.send{value: msg.value}(
            _dstChainId,
            _destination,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        require(
            _from.length == uaMap[_srcChainId].length &&
                keccak256(_from) == keccak256(uaMap[_srcChainId]),
            "Call must send from valid user application"
        );
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        (address toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        // mint the tokens
        _safeMint(toAddress, tokenId);
        counter += 1;
        
        // Truyền thông tin NFT trong sự kiện
        NFTInfo memory info = nftInfo[tokenId];
        emit ReceiveNFT(_srcChainId, toAddress, tokenId, counter, info.name, info.description, info.imageURI);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                _payInZRO,
                _adapterParams
            );
    }
}

