// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NftCollection {
    string public name;
    string public symbol;
    uint256 public maxSupply;
    uint256 public totalSupply;
    string public baseURI;
    address public owner;
    bool public mintingPaused;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => bool) private _tokenExists;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event MintingPaused(bool paused);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(_tokenExists[tokenId], "Token does not exist");
        _;
    }

    modifier notZeroAddress(address account) {
        require(account != address(0), "Zero address");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint256 _maxSupply, string memory _baseURI) {
        require(_maxSupply > 0, "Max supply must be > 0");
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
        baseURI = _baseURI;
        owner = msg.sender;
        totalSupply = 0;
        mintingPaused = false;
    }

    function balanceOf(address account) public view notZeroAddress(account) returns (uint256) {
        return _balances[account];
    }

    function ownerOf(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return _owners[tokenId];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory) public {
        transferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public notZeroAddress(to) tokenExists(tokenId) {
        address tokenOwner = _owners[tokenId];
        require(from == tokenOwner, "From not owner");
        
        bool isApproved = msg.sender == tokenOwner || msg.sender == _tokenApprovals[tokenId] || _operatorApprovals[tokenOwner][msg.sender];
        require(isApproved, "Not authorized");

        _tokenApprovals[tokenId] = address(0);
        emit Approval(tokenOwner, address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public tokenExists(tokenId) {
        address tokenOwner = _owners[tokenId];
        require(msg.sender == tokenOwner || _operatorApprovals[tokenOwner][msg.sender], "Not authorized");
        
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public notZeroAddress(operator) {
        require(operator != msg.sender, "Cannot self-approve");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address tokenOwner, address operator) public view returns (bool) {
        return _operatorApprovals[tokenOwner][operator];
    }

    function tokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, _uint2str(tokenId), ".json"));
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner notZeroAddress(to) {
        require(!mintingPaused, "Minting paused");
        require(!_tokenExists[tokenId], "Token exists");
        require(totalSupply < maxSupply, "Max supply reached");
        require(tokenId > 0, "Token ID > 0");

        _tokenExists[tokenId] = true;
        _owners[tokenId] = to;
        _balances[to]++;
        totalSupply++;

        emit Transfer(address(0), to, tokenId);
    }

    function batchMint(address to, uint256[] calldata tokenIds) public onlyOwner notZeroAddress(to) {
        require(!mintingPaused, "Minting paused");
        require(tokenIds.length > 0, "Must mint >= 1");
        require(totalSupply + tokenIds.length <= maxSupply, "Exceeds max");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(!_tokenExists[tokenId], "Token exists");
            require(tokenId > 0, "Token ID > 0");

            _tokenExists[tokenId] = true;
            _owners[tokenId] = to;
            emit Transfer(address(0), to, tokenId);
        }

        _balances[to] += tokenIds.length;
        totalSupply += tokenIds.length;
    }

    function burn(uint256 tokenId) public tokenExists(tokenId) {
        address tokenOwner = _owners[tokenId];
        require(msg.sender == tokenOwner || msg.sender == owner, "Cannot burn");

        _balances[tokenOwner]--;
        _tokenExists[tokenId] = false;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId];
        totalSupply--;

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    function setPausedState(bool paused) public onlyOwner {
        mintingPaused = paused;
        emit MintingPaused(paused);
    }

    function isMintingPaused() public view returns (bool) {
        return mintingPaused;
    }

    function transferOwnership(address newOwner) public onlyOwner notZeroAddress(newOwner) {
        owner = newOwner;
    }

    function getContractInfo() public view returns (string memory, string memory, uint256, uint256) {
        return (name, symbol, maxSupply, totalSupply);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _tokenExists[tokenId];
    }

    function _uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
}
