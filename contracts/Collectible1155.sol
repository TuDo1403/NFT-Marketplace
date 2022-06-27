// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

/// @custom:security-contact tudm@inspirelab.io
contract Collectible1155 is
    ERC1155,
    Pausable,
    AccessControl,
    Initializable,
    ERC1155Supply,
    ERC1155Burnable,
    ICollectible1155
{
    string private _name;
    string private _symbol;


    address public factory;

    uint96 public constant TYPE = 1155;
    bytes32 public constant VERSION = keccak256("Collectible1155v1");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    modifier onlyFactory() {
        require(factory == _msgSender(), "Collectible1155: Only Factory");
        _;
    }

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    receive() external payable {}

    fallback() external payable {}

    function initialize(
        address admin_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external override initializer {
        _setURI(uri_);
        
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);
        _grantRole(URI_SETTER_ROLE, admin_); 
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        _name = name_;
        _symbol = _symbol;
        factory = _msgSender();
    }

    function freezeUri() external {}

    function getVersion() external pure override returns (bytes32) {
        return VERSION;
    }

    function getType() external pure override returns (uint96) {
        return TYPE;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {}

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {}

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
