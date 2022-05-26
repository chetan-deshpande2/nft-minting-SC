//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "hardhat/console.sol";

contract NFT is EIP712, AccessControl, ERC721URIStorage {
    using ECDSA for bytes32;

    string private constant SIGNING_DOMAIN = "NFT";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct Voucher {
        address signer;
        uint256 tokenId;
        uint256 minPrice;
        string tokenURI;
        bytes signature;
    }

    event Mint(
        address indexed signer,
        address minter,
        uint256 tokenId,
        uint256 minPrice,
        string tokenURI,
        bytes signature
    );

    constructor()
        ERC721("Lazy NFT ", "LFT")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function addSignerRole(address _signer) external {
        require(
            _signer != address(0),
            "Minter Address cannot be zero address."
        );
        _setupRole(MINTER_ROLE, _signer);
    }

    function isSigner(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function mintToken(address minter, Voucher calldata voucher)
        external
        payable
        returns (uint256)
    {
        address signer = _verify(voucher);
        require(signer != minter, "You can not purchase your own token");
        require(isSigner(signer) == false, "Invalid Signature");
        require(
            msg.value >= voucher.minPrice,
            "Insufficient funds to mint item"
        );

        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.tokenURI);
        _transfer(signer, minter, voucher.tokenId);

        if (msg.value > voucher.minPrice) {
            payable(msg.sender).transfer(msg.value - voucher.minPrice);
        }
        payable(signer).transfer(voucher.minPrice);

        emit Mint(
            signer,
            minter,
            voucher.tokenId,
            voucher.minPrice,
            voucher.tokenURI,
            voucher.signature
        );

        return voucher.tokenId;
    }

    function check(Voucher calldata voucher) external view returns (address) {
        return _verify(voucher);
    }

    // returns signer address
    function _verify(Voucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _hash(Voucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 tokenId,uint256 minPrice,string tokenURI)"
                        ),
                        voucher.tokenId,
                        voucher.minPrice,
                        keccak256(bytes(voucher.tokenURI))
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
