// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./IERC721Lite.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721Lite is IERC721Lite, ERC721("", "") {
    using Address for address;
    using Strings for uint256;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function balanceOf(address owner)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (uint256)
    {
        _nonZeroAddress(owner);
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (address)
    {
        address owner = _owners[tokenId];
        _nonZeroAddress(owner);
        // require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        _onlyExists(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721, IERC721)
    {
        address owner = ownerOf(tokenId);
        // require(to != owner, "ERC721: approval to current owner");
        _nonSelfApproving(to, owner);

        // require(
        //     _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
        //     "ERC721: approve caller is not owner nor approved for all"
        // );
        if (!_isApprovedOrOwner(_msgSender(), owner)) {
            revert ERC721__Unauthorized();
        }

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (address)
    {
        // require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        _onlyExists(tokenId);

        return _tokenApprovals[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        // if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
        //     revert ERC721__Unauthorized();
        // }
        _onlyOwnerOrApproved(_msgSender(), tokenId);

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) {
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        // if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
        //     revert ERC721__Unauthorized();
        // }
        _onlyOwnerOrApproved(_msgSender(), tokenId);
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual override {
        _transfer(from, to, tokenId);
        // require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        if (!__checkOnERC721Received(from, to, tokenId, _data)) {
            revert ERC721__ERC721ReceiverNotImplemented();
        }
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual override {
        _mint(to, tokenId);
        if (!__checkOnERC721Received(address(0), to, tokenId, _data)) {
            revert ERC721__ERC721ReceiverNotImplemented();
        }
    }

    // function _receiverMustImplement(address from, address to, uint256 tokenId, bytes memory _data) internal {
    //     if (!__checkOnERC721Received(from, to, tokenId, _data)) {
    //         revert ERC721__ERC721ReceiverNotImplemented();
    //     }
    // }

    function _mint(address to, uint256 tokenId) internal virtual override {
        // require(to != address(0), "ERC721: mint to the zero address");
        // require(!_exists(tokenId), "ERC721: token already minted");
        _nonZeroAddress(to);
        if (_exists(tokenId)) {
            revert ERC721__TokenExisted();
        }

        _beforeTokenTransfer(address(0), to, tokenId);

        ++_balances[to];
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // require(
        //     ERC721.ownerOf(tokenId) == from,
        //     "ERC721: transfer from incorrect owner"
        // );
        if (ownerOf(tokenId) != from) {
            revert ERC721__Unauthorized();
        }
        _nonZeroAddress(to);
        //require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        --_balances[from];
        ++_balances[to];
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual override {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual override {
        //require(owner != operator, "ERC721: approve to caller");
        _nonSelfApproving(owner, operator);
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function __checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // revert(
                    //     "ERC721: transfer to non ERC721Receiver implementer"
                    // );
                    revert ERC721__ERC721ReceiverNotImplemented();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _nonZeroAddress(address addr_) internal pure {
        if (addr_ == address(0)) {
            revert ERC721__NonZeroAddress();
        }
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _onlyOwnerOrApproved(address spender, uint256 tokenId)
        internal
        view
    {
        _onlyExists(tokenId);
        //address owner = ERC721.ownerOf(tokenId);
        bool isApprovedOrOwner = (_isApprovedOrOwner(
            spender,
            ownerOf(tokenId)
        ) || getApproved(tokenId) == spender);
        if (!isApprovedOrOwner) {
            revert ERC721__Unauthorized();
        }
    }

    // function _isApprovedOrOwner(address spender, uint256 tokenId)
    //     internal
    //     view
    //     virtual
    //     override
    //     returns (bool)
    // {
    //     //require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    //     _onlyExists(tokenId);
    //     address owner = ERC721.ownerOf(tokenId);
    //     return (_isApprovedOrOwner(spender, owner) ||
    //         getApproved(tokenId) == spender);
    // }

    function _isApprovedOrOwner(address spender_, address owner_)
        internal
        view
        returns (bool)
    {
        return spender_ == owner_ || isApprovedForAll(owner_, spender_);
    }

    function _nonSelfApproving(address from_, address to_) internal pure {
        if (from_ == to_) {
            revert ERC721__SelfApproving();
        }
    }

    function _onlyExists(uint256 tokenId_) internal view {
        if (!_exists(tokenId_)) {
            revert ERC721__TokenUnexisted();
        }
    }
}
