//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NFT is ERC721URIStorage, EIP712, AccessControl {
    using ECDSA for bytes32;

    string private constant SIGNING_DOMAIN = "NFT";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Mint(
        address indexed signer,
        address minter,
        uint256 tokenId,
        string tokenURI
    );

    constructor()
        ERC721("Lazy NFT ", "LFT")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function addMinterRole(address _minter) external {
        require(
            _minter != address(0),
            "Minter Address cannot be zero address."
        );
        _setupRole(MINTER_ROLE, _minter);
    }

    function addSignerRole(address _signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_signer != address(0), "Admin Address cannot be zero address.");
        grantRole(DEFAULT_ADMIN_ROLE, _signer);
    }

    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isSigner(address account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function mintToken(
        address minter,
        uint256 tokenId,
        uint256 minPrice,
        string memory tokenURI,
        bytes memory signature
    ) external payable {
        require(
            hasRole(MINTER_ROLE, minter),
            "Signature invalid or unauthorized"
        );

        address signer = _verify(tokenId, minPrice, tokenURI, signature);

        require(msg.value >= minPrice, "Insufficient funds to mint item");
        _setTokenURI(tokenId, tokenURI);
        _mint(signer, tokenId);
        _transfer(signer, minter, tokenId);
        payable(signer).transfer(minPrice);
        emit Mint(signer, minter, tokenId, tokenURI);
    }

    function check(
        uint256 tokenId,
        uint256 minPrice,
        string memory tokenURI,
        bytes memory signature
    ) external view returns (address) {
        return _verify(tokenId, minPrice, tokenURI, signature);
    }

    function _verify(
        uint256 tokenId,
        uint256 minPrice,
        string memory tokenURI,
        bytes memory _signature
    ) internal view returns (address) {
        bytes32 digest = _hash(tokenId, minPrice, tokenURI);
        return ECDSA.recover(digest, _signature);
    }

    function _hash(
        uint256 tokenId,
        uint256 minPrice,
        string memory tokenURI
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTStruct(uint256 tokenId,uint256 minPrice,string tokenURI)"
                        ),
                        tokenId,
                        minPrice,
                        keccak256(bytes(tokenURI))
                    )
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}
