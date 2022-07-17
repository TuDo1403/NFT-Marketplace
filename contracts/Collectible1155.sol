// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
// import "./external/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
// import "./external/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
// import "./external/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./CollectibleBase.sol";
import "./ERC1155Permit.sol";

import "./interfaces/IGovernance.sol";
import "./interfaces/ICollectible1155.sol";

contract Collectible1155 is
    ERC1155Supply,
    ERC1155Permit,
    CollectibleBase,
    ERC1155Burnable,
    ERC1155URIStorage,
    ICollectible1155
{
    using Strings for uint256;
    using Address for address;
    using Counters for Counters.Counter;
    using TokenIdGenerator for uint256;
    using TokenIdGenerator for TokenIdGenerator.Token;

    uint256 public constant TYPE = 1155;

    string public name;
    string public symbol;

    string private _uri;

    mapping(address => Counters.Counter) public nonces;

    mapping(uint256 => uint256) private _totalSupply;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    

    modifier onlyUnexists(uint256 tokenId_) {
        __onlyUnexists(tokenId_);
        _;
    }

    constructor(
        address admin_,
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC1155Permit(name_, VERSION) CollectibleBase(admin_) {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32) {
            revert ERC1155__StringTooLong();
        }
        _setBaseURI(baseURI_);

        name = name_;
        symbol = symbol_;
        _grantRole(MINTER_ROLE, owner_);
        _grantRole(URI_SETTER_ROLE, owner_);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155, IERC1155) {
        // require(
        //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
        //     "ERC1155: caller is not owner nor approved"
        // );
        // address sender = _msgSender();
        // if (from != sender || !isApprovedForAll(from, sender)) {
        //     revert ERC1155__Unauthorized();
        // }
        _onlyOwnerOrApproved(from);
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155, IERC1155) {
        // require(
        //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
        //     "ERC1155: transfer caller is not owner nor approved"
        // );
        // address sender = _msgSender();
        // if (from != sender || !isApprovedForAll(from, sender)) {
        //     revert ERC1155__Unauthorized();
        // }
        _onlyOwnerOrApproved(from);
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setBaseURI(string calldata baseURI_)
        external
        override(CollectibleBase, ICollectible)
        onlyRole(URI_SETTER_ROLE)
        notFrozenBase
    {
        _setBaseURI(baseURI_);
        _freezeBase();
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        // require(
        //     account == _msgSender() || isApprovedForAll(account, _msgSender()),
        //     "ERC1155: caller is not owner nor approved"
        // );
        _onlyOwnerOrApproved(account);
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        // require(
        //     account == _msgSender() || isApprovedForAll(account, _msgSender()),
        //     "ERC1155: caller is not owner nor approved"
        // );
        _onlyOwnerOrApproved(account);
        _burnBatch(account, ids, values);
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(ERC1155, IERC1155)
        returns (uint256)
    {
        //require(account != address(0), "ERC1155: balance query for the zero address");
        // if (account == address(0)) {
        //     revert ERC1155__ZeroAddress();
        // }
        _nonZeroAddress(account);
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override(ERC1155, IERC1155)
        returns (uint256[] memory)
    {
        //require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        // if (accounts.length != ids.length) {
        //     revert ERC1155__LengthMismatch();
        // }
        uint256 length = accounts.length;
        _lengthMustMatch(length, ids.length);

        uint256[] memory batchBalances = new uint256[](length);

        for (uint256 i; i < length; ) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
            unchecked {
                ++i;
            }
        }

        return batchBalances;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155) {
        _nonZeroAddress(to);
        //require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = __asSingletonArray(id);
        uint256[] memory amounts = __asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        // require(
        //     fromBalance >= amount,
        //     "ERC1155: insufficient balance for transfer"
        // );
        // if (fromBalance < amount) {
        //     revert ERC1155__InsufficientBalance();
        // }
        _balanceMustSufficient(fromBalance, amount);
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        __doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        //require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        uint256 length = ids.length;
        _lengthMustMatch(length, amounts.length);
        _nonZeroAddress(to);
        //require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i; i < length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            _balanceMustSufficient(fromBalance, amount);
            //require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
                ++i;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        __doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155) {
        _nonZeroAddress(to);
        //require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = __asSingletonArray(id);
        uint256[] memory amounts = __asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        __doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        _nonZeroAddress(to);
        //require(to != address(0), "ERC1155: mint to the zero address");
        //require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        uint256 length = ids.length;
        _lengthMustMatch(length, amounts.length);
        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i; i < length; ) {
            _balances[ids[i]][to] += amounts[i];
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        __doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155) {
        _nonZeroAddress(from);
        //require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = __asSingletonArray(id);
        uint256[] memory amounts = __asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        _balanceMustSufficient(fromBalance, amount);
        //require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");

        _resetTokenRoyalty(id);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155) {
        _nonZeroAddress(from);
        //require(from != address(0), "ERC1155: burn from the zero address");
        //require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        uint256 length = ids.length;
        _lengthMustMatch(length, amounts.length);

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i; i < length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            //require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balanceMustSufficient(fromBalance, amount);
            unchecked {
                ++i;
                _balances[id][from] = fromBalance - amount;
            }
            _resetTokenRoyalty(id);
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual override(ERC1155) {
        //require(owner != operator, "ERC1155: setting approval status for self");
        if (owner == operator) {
            revert ERC1155__SelfApproving();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _freezeBase() internal override notFrozenBase {
        isFrozenBase = true;
        emit PermanentURI(0, uri(0));
    }

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        _setURI(tokenId_, tokenURI_);
        _freezeToken(tokenId_);
    }

    function mint(uint256 tokenId_, uint256 amount_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        address sender = _msgSender();
        __supplyCheck(tokenId_, amount_);
        _mint(sender, tokenId_, amount_, "");
    }

    function mint(address to_, ReceiptUtil.Item memory item_)
        external
        override
    {
        uint256 tokenId = item_.tokenId;
        __onlyUnexists(tokenId);
        if (_msgSender() != admin.marketplace()) {
            _checkRole(MINTER_ROLE);
        }
        _setTokenRoyalty(
            tokenId,
            tokenId.getTokenCreator(),
            uint96(tokenId.getCreatorFee())
        );
        _mint(to_, tokenId, item_.amount, "");

        string memory _tokenURI = item_.tokenURI;
        if (bytes(_tokenURI).length != 0) {
            _setURI(tokenId, _tokenURI);
        }
    }

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external override onlyRole(MINTER_ROLE) {
        address sender = _msgSender();
        for (uint256 i; i < amounts_.length; ) {
            uint256 tokenId = tokenIds_[i];
            _onlyCreatorAndNotFrozen(sender, tokenId);
            __supplyCheck(tokenId, amounts_[i]);
            unchecked {
                ++i;
            }
        }
        _mintBatch(sender, tokenIds_, amounts_, "");
    }

    function mintBatch(address to_, ReceiptUtil.Bulk memory bulk_)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        for (uint256 i; i < bulk_.tokenURIs.length; ) {
            uint256 tokenId = bulk_.tokenIds[i];
            __onlyUnexists(tokenId);
            _setTokenRoyalty(
                tokenId,
                tokenId.getTokenCreator(),
                uint96(tokenId.getCreatorFee())
            );
            string memory _tokenURI = bulk_.tokenURIs[i];
            if (bytes(_tokenURI).length != 0) {
                _setURI(tokenId, _tokenURI);
            }
            unchecked {
                ++i;
            }
        }
        _mintBatch(to_, bulk_.tokenIds, bulk_.amounts, "");
    }

    function tokenURI(uint256 tokenId_)
        external
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    bytes(uri(tokenId_)),
                    bytes(tokenId_.toString())
                )
            );
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.uri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, CollectibleBase, IERC165)
        returns (bool)
    {
        return
            type(ICollectible1155).interfaceId == interfaceId ||
            type(IERC165).interfaceId == interfaceId ||
            ERC1155.supportsInterface(interfaceId) ||
            CollectibleBase.supportsInterface(interfaceId);
    }

    function _useNonce(address owner_)
        internal
        override
        returns (uint256 nonce)
    {
        nonce = nonces[owner_].current();
        nonces[owner_].increment();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                // require(
                //     supply >= amount,
                //     "ERC1155: burn amount exceeds totalSupply"
                // );
                if (supply < amount) {
                    revert ERC1155__AllocationExceeds();
                }
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    function _freezeToken(uint256 tokenId_) internal override {
        super._freezeToken(tokenId_);
        emit PermanentURI(tokenId_, uri(tokenId_));
    }

    function _balanceMustSufficient(uint256 fromBalance_, uint256 amount_)
        internal
        pure
    {
        if (fromBalance_ < amount_) {
            revert ERC1155__InsufficientBalance();
        }
    }

    function _lengthMustMatch(uint256 a, uint256 b) internal pure {
        if (a != b) {
            revert ERC1155__LengthMismatch();
        }
    }

    function _onlyOwnerOrApproved(address from_) internal view {
        address sender = _msgSender();
        if (from_ != sender || !isApprovedForAll(from_, sender)) {
            revert ERC1155__Unauthorized();
        }
    }

    function _nonZeroAddress(address addr_) internal pure {
        if (addr_ == address(0)) {
            revert ERC1155__ZeroAddress();
        }
    }

    function __supplyCheck(uint256 tokenId_, uint256 amount_) private view {
        if (amount_ > 2**TokenIdGenerator.SUPPLY_BIT - 1) {
            revert ERC1155__AllocationExceeds();
        }
        uint256 maxSupply = tokenId_.getTokenMaxSupply();
        if (maxSupply != 0) {
            unchecked {
                if (amount_ + totalSupply(tokenId_) > maxSupply) {
                    revert ERC1155__AllocationExceeds();
                }
            }
        }
    }

    function __onlyUnexists(uint256 tokenId_) private view {
        if (exists(tokenId_)) {
            revert ERC1155__TokenExisted();
        }
    }

    function __doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    //revert("ERC1155: ERC1155Receiver rejected tokens");
                    revert ERC1155__TokenRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                //revert("ERC1155: transfer to non ERC1155Receiver implementer");
                revert ERC1155__ERC1155ReceiverNotImplemented();
            }
        }
    }

    function __doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    //revert("ERC1155: ERC1155Receiver rejected tokens");
                    revert ERC1155__TokenRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155__ERC1155ReceiverNotImplemented();
                //revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function __asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
