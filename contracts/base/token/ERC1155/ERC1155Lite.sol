// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./IERC1155Lite.sol";

abstract contract ERC1155Lite is ERC1155, IERC1155Lite {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory uri_) ERC1155(uri_) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155, IERC1155) {
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
        _onlyOwnerOrApproved(from);
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // function isApprovedForAll(address account, address operator) public view virtual override(IERC1155, ERC1155) returns (bool) {
    //     return _operatorApprovals[account][operator];
    // }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(ERC1155, IERC1155)
        returns (uint256)
    {
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
        //uint256 length = accounts.length;
        _lengthMustMatch(accounts.length, ids.length);

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i; i < accounts.length; ) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
            unchecked {
                ++i;
            }
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override(ERC1155, IERC1155)
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            type(IERC165).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        _nonZeroAddress(to);
        address operator = _msgSender();
        uint256[] memory ids = __asSingletonArray(id);
        uint256[] memory amounts = __asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
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
    ) internal virtual override {
        //uint256 length = ids.length;
        _lengthMustMatch(ids.length, amounts.length);
        _nonZeroAddress(to);

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i; i < ids.length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            _balanceMustSufficient(fromBalance, amount);
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
    ) internal virtual override {
        _nonZeroAddress(to);
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
    ) internal virtual override {
        _nonZeroAddress(to);
        //uint256 length = ids.length;
        _lengthMustMatch(ids.length, amounts.length);
        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i; i < ids.length; ) {
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
    ) internal virtual override {
        _nonZeroAddress(from);

        address operator = _msgSender();
        uint256[] memory ids = __asSingletonArray(id);
        uint256[] memory amounts = __asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        _balanceMustSufficient(fromBalance, amount);
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        // require(from != address(0), "ERC1155: burn from the zero address");
        // require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        _nonZeroAddress(from);
        _lengthMustMatch(ids.length, amounts.length);

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i; i < ids.length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            // require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balanceMustSufficient(fromBalance, amount);
            unchecked {
                _balances[id][from] = fromBalance - amount;
                ++i;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual override {
        if (owner == operator) {
            revert ERC1155__SelfApproving();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
        if (from_ != sender && !isApprovedForAll(from_, sender)) {
            revert ERC1155__Unauthorized();
        }
    }

    function _nonZeroAddress(address addr_) internal pure {
        if (addr_ == address(0)) {
            revert ERC1155__ZeroAddress();
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
                    revert ERC1155__TokenRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
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
                    revert ERC1155__TokenRejected();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155__ERC1155ReceiverNotImplemented();
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
