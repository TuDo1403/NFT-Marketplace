// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/ITritonExchange.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/ICollectible.sol";
import "./interfaces/ICollectible721.sol";
import "./interfaces/ICollectible1155.sol";
import "./interfaces/IRoyaltyManager.sol";
import "./interfaces/IWETH.sol";

import {OrderTypes} from "./libraries/OrderTypes.sol";
import "./libraries/SignatureChecker.sol";

import {Context} from "node_modules/@openzeppelin/contracts/utils/Context.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Exchange logic
 * @author Dat Nguyen (datndt@inspirelab.io)
 * @dev Core functions of Triton Marketplace
 */

contract TritonExchange is ITritonExchange, Context {
    using SafeERC20 for IERC20;

    address public protocolFeeRecipient;
    address public immutable WETH;

    mapping(address => uint256) private _userMinOrderNonce; /**Nonce < minNonce => Orders[Nonce] invalid */
    mapping(address => mapping(uint256 => bool))
        private _isUserOrderNonceExecutedOrCancelled; /**Avoid reentrancy */

    IRotaltyManager private immutable _royaltyManager;

    bytes32 public immutable DOMAIN_SEPARATOR;

    /**
     * @notice Constructor
     * @param royaltyManagerAddress_ Address of royalty fee manager
     * @param protocolFeeRecipient_ Address of protocol fee reciever
     * @param _WETH Address of WETH
     */
    constructor(
        // address _strategyAddress,
        address royaltyManagerAddress_,
        address protocolFeeRecipient_,
        address _WETH
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x1f070a15913b695b5748a71c769189fbeb66e695162d7439ce20ea38464609d2, // keccak256("TritonExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );
        protocolFeeRecipient = protocolFeeRecipient_;
        _royaltyManager = IRotaltyManager(royaltyManagerAddress_);

        WETH = _WETH;
    }

    /**
     * @notice Match order with taker bid using ETH and WETH
     * @param takerBid Taker Bid (buyer)
     * @param makerAsk Maker Ask (seller)
     */
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable override {
        require(
            (makerAsk.isOrderAsk) && (!takerBid.isOrderAsk),
            "TritonExchange: Wrong sides"
        );
        require(
            makerAsk.currency == WETH,
            "TritonExchange: Currency must be WETH"
        );
        require(
            msg.sender == takerBid.taker,
            "TritonExchange: Taker must be the sender"
        );

        // If not enough ETH to cover the price, use WETH
        if (takerBid.price > msg.value) {
            IERC20(WETH).safeTransferFrom(
                msg.sender,
                address(this),
                (takerBid.price - msg.value)
            );
        } else {
            require(
                takerBid.price == msg.value,
                "TritonExchange: Msg.value too high"
            );
        }

        // Wrap ETH sent to this contract
        IWETH(WETH).deposit{value: msg.value}();

        // Check the maker ask order
        bytes32 askHash = OrderTypes.hash(makerAsk);
        _validateOrder(makerAsk, askHash);

        // Retrieve execution parameters
        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IStrategy(
            makerAsk.strategy
        ).canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "TritonExchange: Execution invalid");

        // Update maker ask order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][
            makerAsk.nonce
        ] = true;

        // Execution part 1/2
        _transferFeesAndFundsWithWETH(
            makerAsk.strategy,
            makerAsk.nftAddress,
            tokenId,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        // Execution part 2/2
        _transferNonFungibleToken(
            makerAsk.nftAddress,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            amount
        );
    }

    /**
     * @notice Match order with taker ask
     * @param takerAsk make offer
     * @param makerBid NFT owner
     */
    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external payable override {
        require(
            takerAsk.isOrderAsk && !makerBid.isOrderAsk,
            "TritonExchange: Wrong side!"
        );
        require(
            _msgSender() == takerAsk.taker,
            "TritonExchange: Taker must be sender!"
        );
        require(
            msg.value == makerBid.price,
            "TritonExchange: ms.value must be equal to order price!"
        );

        bytes32 askHash = OrderTypes.hash(makerBid);
        _validateOrder(makerBid, askHash);

        // Update maker bid order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerBid.signer][
            makerBid.nonce
        ] = true;

        // Check the maker bid order
        bytes32 bidHash = OrderTypes.hash(makerBid);
        _validateOrder(makerBid, bidHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IStrategy(
            makerBid.strategy
        ).canExecuteTakerAsk(takerAsk, makerBid);

        require(isExecutionValid, "Strategy: Execution invalid");

        _transferFeesAndFunds(
            makerBid.strategy,
            makerBid.nftAddress,
            tokenId,
            makerBid.currency,
            msg.sender,
            makerBid.signer,
            takerAsk.price,
            makerBid.minPercentageToAsk
        );

        _transferNonFungibleToken(
            makerBid.nftAddress,
            makerBid.signer,
            takerAsk.taker,
            tokenId,
            makerBid.amount
        );
    }

    /**
     * @notice Match order with taker bid
     * @param takerBid Buyer
     * @param makerAsk Seller
     */
    function matchAskWithTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable override {
        require(
            takerBid.isOrderAsk && !makerAsk.isOrderAsk,
            "TritonExchange: Wrong side!"
        );
        require(
            _msgSender() == takerBid.taker,
            "TritonExchange: Taker must be sender!"
        );
        require(
            msg.value == makerAsk.price,
            "TritonExchange: ms.value must be equal to order price!"
        );

        bytes32 askHash = OrderTypes.hash(makerAsk);
        _validateOrder(makerAsk, askHash);

        // Update maker bid order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][
            makerAsk.nonce
        ] = true;

        // Check the maker bid order
        bytes32 bidHash = OrderTypes.hash(makerAsk);
        _validateOrder(makerAsk, bidHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IStrategy(
            makerAsk.strategy
        ).canExecuteTakerAsk(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: Execution invalid");

        _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.nftAddress,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        _transferNonFungibleToken(
            makerAsk.nftAddress,
            makerAsk.signer,
            takerBid.taker,
            tokenId,
            makerAsk.amount
        );
    }

    /**
     * @notice Transfer fees & funds with weth
     * @param strategy Execution strategy
     * @param nftAddress Address of nftAddress
     * @param tokenId Token Id of NFT
     * @param to Address of reciever
     * @param amount Amount of NFT
     * @param minPercentageToAsk Protect seller
     */
    function _transferFeesAndFundsWithWETH(
        address strategy,
        address nftAddress,
        uint256 tokenId,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = amount;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = (IStrategy(strategy).viewProtocolFee() *
                finalSellerAmount) / 10000;

            // Check if the protocol fee is different than 0 for this strategy
            if (
                (protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)
            ) {
                IERC20(WETH).safeTransfer(
                    protocolFeeRecipient,
                    protocolFeeAmount
                );
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {
            (
                address royaltyFeeRecipient,
                uint256 royaltyFeeAmount
            ) = _royaltyManager.calculateRoyaltyFeeAndGetRecipient(
                    nftAddress,
                    amount
                );

            // Check if there is a royalty fee and that it is different to 0
            if (
                (royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)
            ) {
                IERC20(WETH).safeTransfer(
                    royaltyFeeRecipient,
                    royaltyFeeAmount
                );
                finalSellerAmount -= royaltyFeeAmount;
            }
        }

        require(
            (finalSellerAmount * 10000) >= (minPercentageToAsk * amount),
            "Fees: Higher than expected"
        );

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(WETH).safeTransfer(to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer fees & funds
     * @param strategy Execution strategy
     * @param nftAddress Address of nftAddress
     * @param tokenId Token Id of NFT
     * @param currency Payment currency
     * @param to Address of reciever
     * @param amount Amount of NFT
     * @param minPercentageToAsk Protect seller
     */
    function _transferFeesAndFunds(
        address strategy,
        address nftAddress,
        uint256 tokenId,
        address currency,
        address from,
        address to,
        uint256 amount,
        uint256 minPercentageToAsk
    ) internal {
        uint256 finalSellerAmount = amount;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = (IStrategy(strategy).viewProtocolFee() *
                finalSellerAmount) / 10000;

            // Check if the protocol fee is different than 0 for this strategy
            if (
                (protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)
            ) {
                IERC20(currency).safeTransferFrom(
                    from,
                    protocolFeeRecipient,
                    protocolFeeAmount
                );
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Royalty fee
        {
            (
                address royaltyFeeRecipient,
                uint256 royaltyFeeAmount
            ) = _royaltyManager.calculateRoyaltyFeeAndGetRecipient(
                    nftAddress,
                    amount
                );

            // Check if there is a royalty fee and that it is different to 0
            if (
                (royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)
            ) {
                IERC20(currency).safeTransferFrom(
                    from,
                    royaltyFeeRecipient,
                    royaltyFeeAmount
                );
                finalSellerAmount -= royaltyFeeAmount;
            }
        }

        require(
            (finalSellerAmount * 10000) >= (minPercentageToAsk * amount),
            "Fees: Higher than expected"
        );

        // 3. Transfer final amount (post-fees) to seller
        {
            IERC20(currency).safeTransferFrom(from, to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer NFT
     * @param nftAddress Address of NFT
     * @param from Address of seller
     * @param to Address of buyer
     * @param amount Amount of NFT
     */
    function _transferNonFungibleToken(
        address nftAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint96 nftType = ICollectible(nftAddress).getType();
        if (nftType == uint96(721)) {
            ICollectible721(nftAddress).transferFrom(from, to, tokenId, "Ox");
        } else if (nftType == uint96(1155)) {
            ICollectible1155(nftAddress).transferFrom(
                from,
                to,
                tokenId,
                amount,
                "Ox"
            );
        } else {
            revert("Invalid NFT Type!");
        }
    }

    function _validateOrder(
        OrderTypes.MakerOrder calldata makerOrder,
        bytes32 orderHash
    ) internal view {
        require(
            !_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][
                makerOrder.nonce
            ] && makerOrder.nonce >= _userMinOrderNonce[makerOrder.signer],
            "TritonExchange: Matching order expired!"
        );

        require(
            makerOrder.signer != address(0),
            "TritonExchange: Invalid signer!"
        );

        require(makerOrder.price > 0, "TritonExchange: Amount cannot be 0!");

        // Verify the validity of the signature
        require(
            SignatureChecker.verify(
                orderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s,
                DOMAIN_SEPARATOR
            ),
            "Signature: Invalid"
        );
    }
}
