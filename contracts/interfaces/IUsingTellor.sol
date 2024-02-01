// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;



interface IUsingTellor {
    /**
 * @dev Retrieves the next value for the queryId after the specified timestamp
 * @param _queryId is the queryId to look up the value for
 * @param _timestamp after which to search for next value
 * @return _value the value retrieved
 * @return _timestampRetrieved the value's timestamp
 */
function getDataAfter(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bytes memory _value, uint256 _timestampRetrieved);

/**
  * @dev Retrieves the latest value for the queryId before the specified timestamp
  * @param _queryId is the queryId to look up the value for
  * @param _timestamp before which to search for latest value
  * @return _value the value retrieved
  * @return _timestampRetrieved the value's timestamp
  */
function getDataBefore(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bytes memory _value, uint256 _timestampRetrieved);

/**
 * @dev Retrieves next array index of data after the specified timestamp for the queryId
 * @param _queryId is the queryId to look up the index for
 * @param _timestamp is the timestamp after which to search for the next index
 * @return _found whether the index was found
 * @return _index the next index found after the specified timestamp
 */
function getIndexForDataAfter(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bool _found, uint256 _index);

/**
 * @dev Retrieves latest array index of data before the specified timestamp for the queryId
 * @param _queryId is the queryId to look up the index for
 * @param _timestamp is the timestamp before which to search for the latest index
 * @return _found whether the index was found
 * @return _index the latest index found before the specified timestamp
 */
function getIndexForDataBefore(bytes32 _queryId, uint256 _timestamp)
    public
    view
    returns (bool _found, uint256 _index);

/**
 * @dev Retrieves multiple uint256 values before the specified timestamp
 * @param _queryId the unique id of the data query
 * @param _timestamp the timestamp before which to search for values
 * @param _maxAge the maximum number of seconds before the _timestamp to search for values
 * @param _maxCount the maximum number of values to return
 * @return _values the values retrieved, ordered from oldest to newest
 * @return _timestamps the timestamps of the values retrieved
 */
function getMultipleValuesBefore(
  bytes32 _queryId,
  uint256 _timestamp,
  uint256 _maxAge,
  uint256 _maxCount
)
  public
  view
  returns (bytes[] memory _values, uint256[] memory _timestamps);

/**
 * @dev Counts the number of values that have been submitted for the queryId
 * @param _queryId the id to look up
 * @return uint256 count of the number of values received for the queryId
 */
function getNewValueCountbyQueryId(bytes32 _queryId)
  public
  view
  returns (uint256);

/**
 * @dev Returns the address of the reporter who submitted a value for a data ID at a specific time
 * @param _queryId is ID of the specific data feed
 * @param _timestamp is the timestamp to find a corresponding reporter for
 * @return address of the reporter who reported the value for the data ID at the given timestamp
 */
function getReporterByTimestamp(bytes32 _queryId, uint256 _timestamp)
  public
  view
  returns (address);

/**
 * @dev Gets the timestamp for the value based on their index
 * @param _queryId is the id to look up
 * @param _index is the value index to look up
 * @return uint256 timestamp
 */
function getTimestampbyQueryIdandIndex(bytes32 _queryId, uint256 _index)
  public
  view
  returns (uint256);

/**
 * @dev Determines whether a value with a given queryId and timestamp has been disputed
 * @param _queryId is the value id to look up
 * @param _timestamp is the timestamp of the value to look up
 * @return bool true if queryId/timestamp is under dispute
 */
function isInDispute(bytes32 _queryId, uint256 _timestamp)
  public
  view
  returns (bool);

/**
 * @dev Retrieve value from oracle based on queryId/timestamp
 * @param _queryId being requested
 * @param _timestamp to retrieve data/value from
 * @return bytes value for query/timestamp submitted
 */
function retrieveData(bytes32 _queryId, uint256 _timestamp)
  public
  view
  returns (bytes memory);
}