// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/Bytes32Pagination.sol";

contract Blog {
    using Bytes32Pagination for bytes32[];

    event Created(bytes32 hash, bytes32 parentHash);
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
        bytes32[] commentHashes;
        address[] likers;
        uint256 updatedAt;
    }

    mapping(address => bytes32[]) internal _hashesOfAuthor;
    mapping(bytes32 => Post) internal _postOfHash;

    function getPost(bytes32 hash)
        public
        view
        returns (
            address author,
            string memory title,
            string memory body,
            uint256 updatedAt
        )
    {
        Post storage post = _postOfHash[hash];
        if (post.author == address(0)) {
            return (address(0), "", "", 0);
        } else {
            Revision storage latest = post.revisions[post.revisions.length - 1];
            return (post.author, latest.title, latest.body, post.updatedAt);
        }
    }

    function numberOfRevisions(bytes32 hash) public view returns (uint256) {
        Post storage post = _postOfHash[hash];
        return post.revisions.length;
    }

    function revisionAt(bytes32 hash, uint256 index) public view returns (Revision memory) {
        Post storage post = _postOfHash[hash];
        return post.revisions[index];
    }

    function numberOfCommentHashes(bytes32 hash) public view returns (uint256) {
        Post storage post = _postOfHash[hash];
        return post.commentHashes.length;
    }

    function commentHashAt(bytes32 hash, uint256 index) public view returns (bytes32) {
        Post storage post = _postOfHash[hash];
        return post.commentHashes[index];
    }

    function numberOfLikers(bytes32 hash) public view returns (uint256) {
        Post storage post = _postOfHash[hash];
        return post.likers.length;
    }

    function likerAt(bytes32 hash, uint256 index) public view returns (address) {
        Post storage post = _postOfHash[hash];
        return post.likers[index];
    }

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

        bytes32 hash =
            keccak256(abi.encodePacked(msg.sender, title, body, parentHash, block.number));

        Post storage post = _postOfHash[hash];
        require(post.author == address(0), "already-posted");
        post.author = msg.sender;
        post.updatedAt = block.timestamp;

        Revision storage revision = post.revisions.push();
        revision.title = title;
        revision.body = body;
        revision.createdAt = block.timestamp;

        if (parentHash != bytes32(0)) {
            Post storage parentPost = _postOfHash[parentHash];
            require(parentPost.author != address(0), "invalid-parent-hash");
            parentPost.commentHashes.push(hash);
        }

        emit Created(hash, parentHash);
    }

    function update(
        bytes32 hash,
        string memory title,
        string memory body
    ) public {
        require(bytes(title).length > 0, "empty-title");
        require(bytes(body).length > 0, "empty-body");

        Post storage post = _postOfHash[hash];
        require(post.author == msg.sender, "not-author");
        post.updatedAt = block.timestamp;

        Revision storage revision = post.revisions.push();
        revision.title = title;
        revision.body = body;
        revision.createdAt = block.timestamp;

        emit Updated(hash);
    }

    function like(bytes32 hash) public {
        Post storage post = _postOfHash[hash];
        require(post.author != address(0), "wrong-hash");

        for (uint256 i = 0; i < post.likers.length; i++) {
            if (post.likers[i] == msg.sender) {
                revert("already-liked");
            }
        }
        post.likers.push(msg.sender);

        emit Liked(hash, msg.sender);
    }
}
