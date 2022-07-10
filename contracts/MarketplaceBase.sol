// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./interfaces/IMarketplace.sol";
import "./interfaces/ICollectible.sol";
import "./interfaces/ICollectible1155.sol";

contract MarketplaceBase is
    IMarketplace,
    EIP712Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using ReceiptUtil for ReceiptUtil.Receipt;
    using ReceiptUtil for ReceiptUtil.BulkReceipt;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    IGovernance public immutable admin;

    uint256 public serviceFee;
    uint256 public creatorFeeUB; // creator fee upper bound

    bytes32 public constant VERSION = keccak256("v1");
    bytes32 public constant NAME = keccak256("Marketplace");

    CountersUpgradeable.Counter public nonce;

    modifier onlyManager() {
        if (_msgSender() != admin.manager()) {
            revert MP__Unauthorized();
        }
        _;
    }

    constructor(
        address admin_,
        uint256 serviceFee_,
        uint256 creatorFeeUB_
    ) initializer {
        admin = IGovernance(admin_);
        __initialize(serviceFee_, creatorFeeUB_);
    }

    // 2521470
    function initialize(
        uint256 serviceFee_,
        uint256 creatorFeeUB_ // Pausable() // ReentrancyGuard()
    ) external initializer {
        __initialize(serviceFee_, creatorFeeUB_);
    }

    // receive() external payable {
    //     emit Received(_msgSender(), msg.value, "Received Token");
    // }

    //fallback() external payable {}

    // function kill() external onlyManager {
    //     selfdestruct(payable(IGovernance(admin).treasury()));
    // }

    function multiDelegatecall(bytes[] calldata data)
        external
        payable
        override
        onlyManager
        whenNotPaused
        returns (bytes[] memory results)
    {
        for (uint256 i; i < data.length; ) {
            (bool ok, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!ok) {
                revert MP__ExecutionFailed();
            }
            results[i] = result;
            unchecked {
                ++i;
            }
        }
    }

    function redeem(
        uint256 deadline_,
        ReceiptUtil.Receipt calldata receipt_,
        bytes calldata signature_
    ) external payable override whenNotPaused nonReentrant {
        __processReceipt(
            deadline_,
            _hashTypedDataV4(receipt_.hash()),
            receipt_.header,
            receipt_.payment,
            signature_
        );
        address seller = receipt_.header.seller;
        uint256 tokenId = receipt_.item.tokenId;
        uint256 amount = receipt_.item.amount;
        address nftContract = receipt_.item.nftContract;
        bool minted = ICollectible(nftContract).isMintedBefore(
            seller,
            tokenId,
            amount
        );
        address buyer = receipt_.header.buyer;

        if (!minted) {
            __grantMinterRole(nftContract, buyer);

            (bool ok, ) = nftContract.delegatecall(
                abi.encodeWithSelector(
                    __getFnSelector(
                        "lazyMintSingle(address,uint256,uint256,string)"
                    ),
                    seller,
                    tokenId,
                    amount,
                    receipt_.item.tokenURI
                )
            );
            if (!ok) {
                revert MP__ExecutionFailed();
            }
        }

        ICollectible(nftContract).transferSingle(
            seller,
            buyer,
            amount,
            tokenId
        );

        emit ItemRedeemed(
            nftContract,
            buyer,
            tokenId,
            receipt_.header.paymentToken,
            receipt_.item.unitPrice,
            receipt_.payment.total
        );
    }

    function redeemBulk(
        uint256 deadline_,
        ReceiptUtil.BulkReceipt calldata receipt_,
        bytes calldata signature_
    ) external payable override whenNotPaused nonReentrant {
        __processReceipt(
            deadline_,
            _hashTypedDataV4(receipt_.hash()),
            receipt_.header,
            receipt_.payment,
            signature_
        );

        address buyer = receipt_.header.buyer;
        address seller = receipt_.header.seller;
        address nftContract = receipt_.bulk.nftContract;
        __grantMinterRole(nftContract, buyer);
        __mintUnexist(seller, receipt_.bulk, receipt_.bulk.tokenURIs);

        ICollectible1155(nftContract).transferBatch(
            seller,
            buyer,
            receipt_.bulk.tokenIds,
            receipt_.bulk.amounts
        );

        emit BulkRedeemed(
            nftContract,
            buyer,
            receipt_.bulk.tokenIds,
            receipt_.header.paymentToken,
            receipt_.bulk.unitPrices,
            receipt_.payment.total
        );
    }

    function __processReceipt(
        uint256 deadline_,
        bytes32 hashedReceipt_,
        ReceiptUtil.Header calldata header_,
        ReceiptUtil.Payment calldata payment_,
        bytes calldata signature_
    ) private {
        IGovernance _admin = admin;
        address buyer = header_.buyer;
        address paymentToken = header_.paymentToken;
        __verifyIntegrity(
            payment_.total,
            header_.nonce,
            deadline_,
            header_.ticketExpiration,
            _admin,
            buyer,
            paymentToken
        );
        if (
            ECDSAUpgradeable.recover(hashedReceipt_, signature_) !=
            _admin.verifier()
        ) {
            revert MP__InvalidSignature();
        }
        nonce.increment();

        __transact(paymentToken, buyer, header_.seller, payment_.subTotal);
        __transact(
            paymentToken,
            buyer,
            header_.creatorPayoutAddr,
            payment_.creatorPayout
        );
        __transact(
            paymentToken,
            buyer,
            _admin.treasury(),
            payment_.servicePayout
        );
    }

    function __grantMinterRole(address nftContract_, address buyer_) private {
        IAccessControl governor = IAccessControl(nftContract_);
        if (!governor.hasRole(keccak256("MINTER_ROLE"), buyer_)) {
            governor.grantRole(keccak256("MINTER_ROLE"), buyer_);
        }
    }

    function pause() external override whenNotPaused onlyManager {
        _pause();
    }

    function unpause() external override whenPaused onlyManager {
        _unpause();
    }

    function __transact(
        address paymentToken_,
        address from_,
        address to_,
        uint256 amount_
    ) private {
        if (paymentToken_ == address(0)) {
            (bool ok, ) = payable(to_).call{value: amount_}("");
            if (!ok) {
                revert MP__PaymentFailed();
            }
        } else {
            IERC20Upgradeable(paymentToken_).safeTransferFrom(
                from_,
                to_,
                amount_
            );
        }
    }

    function __mintUnexist(
        address seller_,
        ReceiptUtil.Bulk calldata bulk_,
        string[] calldata tokenURIs_
    ) private {
        uint256 counter;
        uint256[] memory tokensToMint;
        uint256[] memory amountsToMint;
        for (uint256 i; i < bulk_.tokenIds.length; ) {
            bool minted = ICollectible(bulk_.nftContract).isMintedBefore(
                seller_,
                bulk_.tokenIds[i],
                bulk_.amounts[i]
            );

            unchecked {
                if (!minted) {
                    tokensToMint[counter] = bulk_.tokenIds[i];
                    amountsToMint[counter] = bulk_.amounts[i];
                    ++counter;
                }
                ++i;
            }
        }
        (bool ok, ) = bulk_.nftContract.delegatecall(
            abi.encodeWithSelector(
                __getFnSelector(
                    "lazyMintBatch(address,uint256[],uint256[],string)"
                ),
                seller_,
                tokensToMint,
                amountsToMint,
                tokenURIs_
            )
        );
        if (!ok) {
            revert MP__ExecutionFailed();
        }
    }

    function __initialize(uint256 serviceFee_, uint256 creatorFeeUB_) private {
        uint256 upperBound = 2**TokenIdGenerator.FEE_BIT - 1;
        if (serviceFee_ != 0) {
            serviceFee = serviceFee_ % upperBound;
        }
        if (creatorFeeUB_ != 0) {
            creatorFeeUB = creatorFeeUB_ % upperBound;
        }

        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init(
            string(abi.encodePacked(NAME)),
            string(abi.encodePacked(VERSION))
        );
    }

    function __getFnSelector(string memory fnSignature_)
        private
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(bytes(fnSignature_)));
    }

    function __verifyIntegrity(
        uint256 total_,
        uint256 nonce_,
        uint256 deadline_,
        uint256 ticketExpiration_,
        IGovernance admin_,
        address buyer_,
        address paymentToken_
    ) private view {
        if (buyer_ != _msgSender()) {
            revert MP__Unauthorized();
        }
        if (total_ > msg.value) {
            revert MP__InsufficientPayment();
        }
        if (nonce_ != nonce.current()) {
            revert MP__InvalidInput();
        }
        if (!admin_.acceptedPayments(paymentToken_)) {
            revert MP__PaymentUnsuported();
        }
        uint256 _now = block.timestamp;
        if (_now > deadline_ || _now > ticketExpiration_) {
            revert MP__Expired();
        }
    }
}