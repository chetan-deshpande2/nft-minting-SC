const SIGNING_DOMAIN = "NFT";
const SIGNATURE_VERSION = "1";

class SignHelper {
  constructor({ nft, signer }) {
    this.nft = nft;
    this.signer = signer;
  }

  async createSignature(tokenId, minPrice, tokenURI) {
    const domainData = await this._signingDomain();
    //! define your data tyoes
    const types = {
      Voucher: [
        { name: "tokenId", type: "uint256" },
        { name: "minPrice", type: "uint256" },
        { name: "tokenURI", type: "string" },
      ],
    };
    //* the data to sign / signature will be added to our solidity struct

    const voucher = {
      tokenId,
      minPrice,
      tokenURI,
    };

    //* signer._signTypedData(domain, types, value) =>  returns a raw signature
    const signature = await this.signer._signTypedData(
      domainData,
      types,
      voucher
    );
    return { ...voucher, signature };
  }

  async _signingDomain() {
    if (this.domainData != null) {
      return this.domainData;
    }
    const chainId = await this.nft.getChainID();
    console.log("chainId: " + chainId.toString());
    this.domainData = {
      name: SIGNING_DOMAIN,
      version: SIGNATURE_VERSION,
      verifyingContract: this.nft.address,
      chainId,
    };
    return this.domainData;
  }
}

module.exports = {
  SignHelper,
};
