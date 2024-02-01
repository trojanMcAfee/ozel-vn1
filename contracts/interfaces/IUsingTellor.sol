// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;



interface IUsingTellor {
  function getDataBefore(bytes32 _queryId, uint256 _timestamp)
    external
    view
    returns (bool _ifRetrieve, bytes memory _value, uint256 _timestampRetrieved);
}