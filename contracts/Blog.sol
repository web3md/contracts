// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/Bytes32Pagination.sol";

contract Blog {
    using Bytes32Pagination for bytes32[];

    event Created(bytes32 hash);
    event Updated(bytes32 hash);
    event Liked(bytes32 hash, address liker);

    struct Revision {
        string title;
        string body;
        uint256 createdAt;
    }

    struct Post {
        bytes32 parentHash;
        address author;
        Revision[] revisions;
        address[] likes;
        uint256 updatedAt;
    }

    mapping(address => bytes32[]) internal _hashesOfAuthor;
    mapping(bytes32 => Post) public postOfHash;

    function numberOfHashesOfAuthor(address author) public view returns (uint256) {
        return _hashesOfAuthor[author].length;
    }

    function hashesOfAuthor(
        address author,
        uint256 page,
        uint256 limit
    ) public view returns (bytes32[] memory) {
        return _hashesOfAuthor[author].paginate(page, limit);
    }

    function create(
        string memory title,
        string memory body,
        bytes32 parentHash
    ) public {
        require(bytes(title).length > 0, "empty-title");
        require(bytes(body).length > 0, "empty-body");
        if (parentHash != bytes32(0)) {
            require(postOfHash[parentHash].author != address(0), "invalid-parent-hash");
        }

        bytes32 hash = _hash(msg.sender, title, body, parentHash);
        Post storage post = postOfHash[hash];
        require(post.author == address(0), "already-posted");
        post.author = msg.sender;
        post.updatedAt = block.timestamp;

        Revision storage revision = post.revisions.push();
        revision.title = title;
        revision.body = body;
        revision.createdAt = block.timestamp;

        emit Created(hash);
    }

    function _hash(
        address author,
        string memory title,
        string memory body,
        bytes32 parentHash
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(author, title, body, parentHash, block.number));
    }

    function update(
        bytes32 hash,
        string memory title,
        string memory body
    ) public {
        require(bytes(title).length > 0, "empty-title");
        require(bytes(body).length > 0, "empty-body");

        Post storage post = postOfHash[hash];
        require(post.author == msg.sender, "not-author");
        post.updatedAt = block.timestamp;

        Revision storage revision = post.revisions.push();
        revision.title = title;
        revision.body = body;
        revision.createdAt = block.timestamp;

        emit Updated(hash);
    }

    function like(bytes32 hash) public {
        Post storage post = postOfHash[hash];
        require(post.author != address(0), "wrong-hash");

        for (uint256 i = 0; i < post.likes.length; i++) {
            if (post.likes[i] == msg.sender) {
                revert("already-liked");
            }
        }
        post.likes.push(msg.sender);

        emit Liked(hash, msg.sender);
    }
}
